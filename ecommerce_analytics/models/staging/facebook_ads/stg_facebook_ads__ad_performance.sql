-- models/staging/facebook_ads/stg_facebook_ads__ad_performance.sql
-- Minimal version - source connection and column renames only
-- Derived metrics added incrementally in subsequent commits
-- Add Date Dimension Columns

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

        -- Metadata
        _loaded_at                                          as loaded_at_timestamp

    from source

)

select * from renamed