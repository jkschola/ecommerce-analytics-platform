# 🎓 Certification & Interview Prep Guide

This document maps the engineering decisions made in the E-Commerce Analytics Platform directly to the **dbt Analytics Engineering Certification** topics and common **Senior Data Engineering interview questions**.

---

## Part 1: dbt Certification Topic Mapping

### ✅ Topic 1: Developing dbt Models
* **DRY Principles:** Reused `dbt_project.yml` variables (e.g., `{{ var('recent_order_days') }}`) across multiple models to ensure logic only exists in one place.
* **Macros:** Leveraged `dbt_utils.generate_surrogate_key` to create single-column primary keys for fact tables without natural keys (`fct_marketing_performance`).
* **Jinja Compilation:** Used Jinja `join()` filters to dynamically compile YAML lists of paid marketing channels into valid SQL `IN (...)` clauses in the staging layer.

### ✅ Topic 2: Fact & Dimension Design
* **Type 1 SCD (Current State):** Built `dim_customers` to house static profile data alongside constantly updating lifetime aggregates (LTV, total orders).
* **Dimensional Denormalization:** Purposefully denormalized customer segments and recency tiers directly into `fct_orders` to optimize downstream BI querying and eliminate complex joins in Tableau/Looker.
* **Defensive Math:** Utilized `NULLIF(denominator, 0)` on financial ratios (ROAS, CPA) to prevent division-by-zero fatal execution errors.

### ✅ Topic 3: Debugging Data Errors
* **The "Orphaned Spend" Bug:** Discovered that an asymmetric `LEFT JOIN` was dropping Facebook Ad spend on days with zero Google Analytics sessions. **Fix:** Implemented an event-driven `FULL OUTER JOIN` to rescue €8.7k of orphaned spend.
* **The "100% Refund" Anomaly:** The bounds test (`refund_rate between 0 and 1`) failed because synthetic data generated refunds larger than original orders. **Fix:** Wrapped the division logic in a SQL `least(..., 1.0)` function to gracefully cap rates at 100% without dropping raw data.
* **Three-Valued Logic Traps:** Discovered that boolean flags evaluate to `NULL` if underlying ratios are `NULL`. **Fix:** Applied strict `IS NOT NULL` guardrails before boolean evaluations (`blended_cpc is not null and blended_cpc <= 2.00`) to keep dashboard filters clean.

### ✅ Topic 5: Implementing Tests
* **Comprehensive Coverage:** Scaled to 226 tests across 10 models with a 100% pass rate.
* **Advanced Generic Tests:** Relied heavily on `dbt_utils.expression_is_true` for logical bounds checking (e.g., ensuring `account_age_days >= 0`).
* **Custom Singular Tests:** Wrote `assert_ad_spend_matches_staging.sql` to mathematically prove that the `FULL OUTER JOIN` logic didn't accidentally duplicate or drop financial data.

### ✅ Topic 6: Documentation
* **Parameterized Descriptions:** Injected `dbt_project.yml` variables directly into YAML descriptions (e.g., `True if sessions >= {{ var('marketing_high_traffic_sessions') }}`) so data dictionaries auto-update if business logic changes.
* **BI-Safe Sorting:** Prefixed qualitative tiers with integers (e.g., `'1. Low'`, `'2. Medium'`) to force native alphabetical sorting in BI tools, documenting the logic clearly in the YAML.

---

## Part 2: Behavioral Interview "STAR" Stories

*(Situation, Task, Action, Result)*

### 🎤 Q: "Tell me about a time you handled messy or misaligned data."
**The Story:** Unifying Marketing Data (`int_marketing__channel_performance`)
* **Situation:** Facebook Ads lived at the "Ad-Day" grain, while Google Analytics lived at the "Session" grain.
* **Action:** I pre-aggregated both datasets to a common `date + channel` grain in CTEs, then used a `FULL OUTER JOIN` using a combined surrogate key.
* **Result:** Successfully built a unified marketing funnel fact table, actively preventing the loss of orphaned ad spend on low-traffic days.

### 🎤 Q: "How do you handle changing business logic in your pipelines?"
**The Story:** Configuration-as-Code for Marketing Thresholds
* **Situation:** The VP of Marketing constantly tweaks the definition of a "High Value Customer" or "Efficient CPC". Hardcoding these in SQL causes brittle pipelines and stale documentation.
* **Action:** I extracted all business thresholds into `dbt_project.yml` variables. I referenced these variables in the SQL `CASE` statements and dynamically injected them into the `.yml` data dictionary descriptions.
* **Result:** A single PR to `dbt_project.yml` now safely updates the transformation logic and the documentation simultaneously, eliminating maintenance debt.

### 🎤 Q: "How do you design models specifically for BI tool performance?"
**The Story:** The Presentation Layer Refinements
* **Action 1:** I pre-computed all `DATE_TRUNC` logic (week, month, quarter) in the fact tables so the BI warehouse doesn't waste compute doing it on the fly.
* **Action 2:** I generated single-column hashed Surrogate Keys for all fact tables to prevent BI developers from having to write slow, error-prone composite joins (`ON a.date = b.date AND a.channel = b.channel`).
* **Action 3:** I mapped complex CASE statements to clean boolean flags (`is_high_value_order`, `is_efficient_spend`) allowing dashboard users to filter millions of rows with a single click.