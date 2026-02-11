-- models/staging/google_analytics/stg_google_analytics__sessions.sql

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
        
        -- Engagement metrics
        page_views,
        session_duration_seconds,

        -- Attribution
        source as traffic_source,
        medium as traffic_medium,
        campaign as campaign_name,

        -- Metadata
        _loaded_at as loaded_at_timestamp

    from source

)

select * from renamed