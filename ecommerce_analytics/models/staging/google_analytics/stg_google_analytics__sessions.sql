-- models/staging/google_analytics/stg_google_analytics__sessions.sql
-- Step 1: Minimal version - source connection and column renames only
-- Derived columns and business logic added in subsequent commits

{{
    config(
        materialized='view',
        tags=['daily']
    )
}}

with source as (

    select * from {{ source('google_analytics', 'sessions') }}

),

renamed as (

    select
        -- Primary key
        session_id,

        -- User identification
        user_id,

        -- Session timing
        session_date,

        -- Engagement metrics (raw)
        page_views,
        session_duration_seconds,

        -- Attribution (renamed for clarity)
        source          as traffic_source,
        medium          as traffic_medium,
        campaign        as campaign_name,

        -- Metadata
        _loaded_at      as loaded_at_timestamp

    from source

)

select * from renamed