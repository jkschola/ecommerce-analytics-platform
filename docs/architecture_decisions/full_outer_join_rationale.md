# Architecture Decision: Event-Driven FULL OUTER JOIN vs. Cartesian Date Spine

**Date:** 2026-02-09  
**Status:** Implemented  
**Context:** Resolving a critical data loss bug (orphaned ad spend) in `int_marketing__channel_performance`.

## Problem Statement

An asymmetric `LEFT JOIN` (Sessions -> Ads) resulted in the silent loss of €8,706.44 of ad spend across 63 days. The logic assumed web sessions were the base grain, inherently dropping any day where Facebook Ads spent money but generated zero `paid_advertising` website sessions.

## Solutions Considered

### Option 1: Date Spine + CROSS JOIN ❌ 
*Rejected: Anti-pattern for intermediate transformations.*

**Approach:**
Generate a continuous date spine, `CROSS JOIN` it with a channel spine, and `LEFT JOIN` the session and ad metrics onto that dense grid.

**Pros:**
- Mathematically guarantees 100% data preservation.
- Forces explicit handling of `0` vs `NULL`.

**Cons (The Cartesian Explosion):**
- **Warehouse Compute Bloat:** Forces the generation of 4,380 rows (730 days × 6 channels). 
- **Fake Data Generation:** ~83% of the generated rows are empty. For example, it forces a row for "Christmas Day / Social Media" even if zero activity occurred.
- **Layer Violation:** Dense spine generation is a presentation-layer (BI) responsibility for line-chart continuity, not an intermediate transformation pattern.

### Option 2: FULL OUTER JOIN ✅ 
*Selected: Standard Data Engineering pattern for asymmetric event data.*

**Approach:**
Natively combine the two tables using `FULL OUTER JOIN` on Date and Channel, leveraging `COALESCE` to handle missing keys and metric defaults.



**Pros:**
- **Event-Driven:** Only creates rows for *actual, real-world events* (730 true data points).
- **Performant:** Scans 83% fewer rows; avoids Cartesian explosions.
- **Scalable:** Scales linearly with the business, not exponentially with time × dimensions.

**Cons:**
- Requires strict, defensive `COALESCE` handling to prevent `NULL` primary keys.

## Implementation Details

**Defensive COALESCE Strategy:**
- **Primary Keys:** `coalesce(s.activity_date, a.activity_date)` (Prevents `NULL` keys).
- **Absolute Volumes:** `coalesce(s.total_sessions, 0)` (Zero semantically represents "no sessions").
- **Rate Metrics:** `s.bounce_rate` (Intentionally left `NULL` on zero-session days to prevent `0/0` division errors).
- **Ad Metrics:** `a.total_spend` (Intentionally left `NULL` for non-paid organic channels).

**Data Contract Adjustments:**
- **Removed:** The `total_sessions > 0` constraint. 
- **Rationale:** Zero is now a mathematically valid state for days where ad spend occurred but upstream web tracking recorded zero traffic.

## Performance Impact

| Metric | Date Spine (Option 1) | FULL OUTER JOIN (Option 2) | Efficiency Gain |
|--------|-----------------------|----------------------------|-----------------|
| Row Generation | 4,380 rows | 730 rows | **83% Reduction** |
| Fake Data Created | ~3,650 empty rows | 0 empty rows | **100% Elimination** |
| Scaling Factor | Exponential ($Days \times Channels$) | Linear (Real Events) | **Infinite** |

## Key Takeaways

1. **Layer Discipline:** Date spines belong in the BI/Reporting layer, not the data warehouse transformation layer.
2. **Semantic Integrity:** A `0` (an event happened resulting in zero) is vastly different from a `NULL` (no event happened). The `FULL OUTER JOIN` respects this reality.
3. **Observability ROI:** Our `assert_ad_spend_matches_staging` singular test caught this €8.7k anomaly before it hit production dashboards, proving the value of strict financial data contracts.