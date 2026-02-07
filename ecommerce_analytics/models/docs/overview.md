{% docs __overview__ %}

# E-Commerce Analytics Platform

## Project Purpose

This dbt project transforms raw e-commerce data from multiple sources into analytics-ready datasets for business intelligence and decision-making.

## Data Sources

- **Shopify**: E-commerce transactions and customer data
- **Google Analytics**: Website traffic and user behavior
- **Facebook Ads**: Marketing campaign performance

## Architecture Layers

### 1. Staging Layer (`staging/`)
**Purpose:** Standardize and clean source data

- Light transformations only (renaming, type casting)
- One staging model per source table
- Materialized as views (no storage cost)
- **Naming convention:** `stg_<source>__<entity>`

### 2. Intermediate Layer (`intermediate/`)
**Purpose:** Reusable business logic components

- Complex calculations and joins
- Shared across multiple marts
- Materialized as views (composability)
- **Naming convention:** `int_<entity>__<description>`

### 3. Marts Layer (`marts/`)
**Purpose:** Business-facing analytics tables

- Organized by business domain (core, marketing, finance)
- Optimized for query performance
- Materialized as tables
- **Naming convention:** `fct_<process>` or `dim_<entity>`

## Best Practices Implemented

1. ✅ Separation of concerns (staging vs intermediate vs marts)
2. ✅ DRY principles (reusable intermediate models)
3. ✅ Comprehensive testing (generic + custom tests)
4. ✅ Full documentation and lineage
5. ✅ Environment separation (dev vs prod)

## How to Navigate This Project

- **Sources:** Defined in `models/staging/_sources.yml`
- **Staging models:** `models/staging/<source>/`
- **Intermediate models:** `models/intermediate/<domain>/`
- **Marts models:** `models/marts/<domain>/`
- **Tests:** Schema tests in `.yml` files, singular tests in `tests/`
- **Macros:** Reusable code in `macros/`

{% enddocs %}
