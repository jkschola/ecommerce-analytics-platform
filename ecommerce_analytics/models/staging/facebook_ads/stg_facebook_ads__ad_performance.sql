-- models/staging/facebook_ads/stg_facebook_ads__ad_performance.sql
-- Minimal version - source connection and column renames only
-- Derived metrics added incrementally in subsequent commits
-- Add Date Dimension Columns
-- Add Computed Ad Metrics (CTR, CPC, CPM, CPA, CVR)
-- Add Performance Tier Classification (based on CTR and CVR thresholds)

{{
    config(
        materialized='view',
        tags=['daily']
    )
}}

-- models/staging/facebook_ads/stg_facebook_ads__ad_performance.sql

{{
    config(
        materialized='view',
        tags=['daily']
    )
}}

with source as (

    select * from {{ source('facebook_ads', 'ad_performance') }}

),

renamed as (

    select
        -- Composite primary key
        ad_id,
        date                                                as performance_date,

        -- Date dimensions
        date_trunc('week', date)                            as performance_week,
        date_trunc('month', date)                           as performance_month,
        extract(year from date)                             as performance_year,
        extract(quarter from date)                          as performance_quarter,
        extract(month from date)                            as performance_month_num,
        extract(dayofweek from date)                        as performance_day_of_week,

        -- Raw performance metrics
        impressions,
        clicks,
        spend,
        conversions,

        -- Click-through rate (CTR): clicks / impressions
        -- Null when no impressions to avoid division by zero
        round(
            clicks / nullif(impressions, 0),
        4)                                                  as click_through_rate,

        -- Cost per click (CPC): spend / clicks
        -- Null when no clicks (common for display ads)
        round(
            spend / nullif(clicks, 0),
        2)                                                  as cost_per_click,

        -- Cost per mille (CPM): spend per 1000 impressions
        -- Standard media buying metric
        round(
            (spend / nullif(impressions, 0)) * 1000,
        2)                                                  as cost_per_mille,

        -- Cost per acquisition (CPA): spend / conversions
        -- Null when no conversions
        round(
            spend / nullif(conversions, 0),
        2)                                                  as cost_per_acquisition,

        -- Conversion rate (CVR): conversions / clicks
        -- Null when no clicks
        round(
            conversions / nullif(clicks, 0),
        4)                                                  as conversion_rate,

        -- Metadata
        _loaded_at                                          as loaded_at_timestamp,

        -- Performance tier based on CTR
        -- Classifies each ad-day into a performance bucket
        case
            when impressions = 0
                then 'no_delivery'
            when round(clicks / nullif(impressions, 0), 4) >= 0.04
                then 'high_performance'
            when round(clicks / nullif(impressions, 0), 4) >= 0.02
                then 'medium_performance'
            when round(clicks / nullif(impressions, 0), 4) >= 0.01
                then 'low_performance'
            else
                'underperforming'
        end                                                 as performance_tier,

        -- Is this a delivery day? (had at least 1 impression)
        (impressions > 0)                                   as is_delivery_day,

        -- Did this ad generate any clicks?
        (clicks > 0)                                        as has_clicks,

        -- Did this ad generate any conversions?
        (conversions > 0)                                   as has_conversions,

    from source

),

final as (

    select
        -- Keys
        ad_id,
        performance_date,

        -- Time dimensions
        performance_week,
        performance_month,
        performance_year,
        performance_quarter,
        performance_month_num,
        performance_day_of_week,

        -- Raw metrics
        impressions,
        clicks,
        spend,
        conversions,

        -- Computed metrics
        click_through_rate,
        cost_per_click,
        cost_per_mille,
        cost_per_acquisition,
        conversion_rate,

        -- Metadata
        loaded_at_timestamp,

        -- Classification
        performance_tier,

        -- Flags
        is_delivery_day,
        has_clicks,
        has_conversions,        

    from renamed

)

select * from final