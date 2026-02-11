-- models/staging/facebook_ads/stg_facebook_ads__ad_performance.sql
-- Minimal version - source connection and column renames only
-- Derived metrics added incrementally in subsequent commits

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
        date                    as performance_date,

        -- Raw performance metrics
        impressions,
        clicks,
        spend,
        conversions,

        -- Metadata
        _loaded_at              as loaded_at_timestamp

    from source

)

select * from renamed