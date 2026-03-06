-- tests/assert_ad_spend_matches_staging.sql
--
-- PURPOSE: Validates that the LEFT JOIN from sessions to ads did not orphan any advertising spend.
--
-- SCENARIO: If Google Analytics tracking fails for a day but Facebook Ads is still running and spending money, 
-- this test will FAIL, alerting us to the missing spend.
--
-- BUSINESS IMPACT: Without this test, we could silently lose thousands of dollars of ad spend from our reporting, 
-- leading to incorrect ROAS calculations and bad business decisions.

-- TOLERANCE: {{ var('spend_variance_tolerance') }} (configurable)
-- To change: dbt test --vars '{spend_variance_tolerance: 0.10}'

with staging_spend as (
    select sum(spend) as total_staging_spend
    from {{ ref('stg_facebook_ads__ad_performance') }}
),

intermediate_spend as (
    select sum(total_spend) as total_intermediate_spend
    from {{ ref('int_marketing__channel_performance') }}
),

variance_check as (
    select
        staging_spend.total_staging_spend,
        intermediate_spend.total_intermediate_spend,
        abs(staging_spend.total_staging_spend 
            - intermediate_spend.total_intermediate_spend) as spend_variance,
        {{ var('spend_variance_tolerance') }} as tolerance
    from staging_spend
    cross join intermediate_spend
)

select
    total_staging_spend,
    total_intermediate_spend,
    spend_variance,
    tolerance,
    'CRITICAL: Ad spend variance exceeds tolerance' as error_message
from variance_check
where spend_variance > tolerance