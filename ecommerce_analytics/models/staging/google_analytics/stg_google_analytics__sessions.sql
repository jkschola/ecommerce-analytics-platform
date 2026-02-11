-- models/staging/google_analytics/stg_google_analytics__sessions.sql
-- Add derived time columns

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

        -- Session timing (raw)
        session_date,

        -- Session timing (derived)
        cast(session_date as date)                                  as session_date_day,
        date_trunc('week', cast(session_date as date))              as session_date_week,
        date_trunc('month', cast(session_date as date))             as session_date_month,

        -- Engagement metrics (raw)
        page_views,
        session_duration_seconds,

        -- Engagement metrics (derived)
        round(session_duration_seconds / 60.0, 2)                   as session_duration_minutes,

        round(
            case
                when page_views > 0
                    then session_duration_seconds / page_views
                else 0
            end,
        2)                                                          as avg_time_per_page_seconds,

        -- Attribution (renamed for clarity)
        source          as traffic_source,
        medium          as traffic_medium,
        campaign        as campaign_name,

        -- Metadata
        _loaded_at      as loaded_at_timestamp

    from source

)

select * from renamed