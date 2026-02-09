-- models/staging/google_analytics/stg_google_analytics__sessions.sql

{{
    config(
        materialized='view',
        tags=['daily', 'web_analytics']
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

        -- Temporal fields
        session_date,
        date(session_date) as session_date_day,
        date_trunc('week', session_date) as session_date_week,
        date_trunc('month', session_date) as session_date_month,

        -- Engagement metrics
        page_views,
        session_duration_seconds,
        
        -- Derived engagement metrics
        round(session_duration_seconds / 60.0, 2) as session_duration_minutes,
        case
            when page_views >= 1 and session_duration_seconds >= 10 then
                round(session_duration_seconds::decimal / page_views, 1)
            else 0
        end as avg_time_per_page_seconds,

        -- Engagement categorization
        case
            when page_views = 1 and session_duration_seconds < 30 then 'bounce'
            when page_views <= 3 and session_duration_seconds < 60 then 'low_engagement'
            when page_views <= 7 and session_duration_seconds < 300 then 'medium_engagement'
            else 'high_engagement'
        end as engagement_level,

        -- Boolean engagement flags
        case
            when page_views = 1 and session_duration_seconds < 30 then true
            else false
        end as is_bounce,

        case
            when page_views >= 5 or session_duration_seconds >= 180 then true
            else false
        end as is_engaged_session,

        -- Traffic source fields
        lower(source) as traffic_source,
        lower(medium) as traffic_medium,
        campaign as campaign_name,

        -- Traffic categorization
        case
            when lower(source) = 'organic' then 'organic_search'
            when lower(source) = 'paid' then 'paid_advertising'
            when lower(source) = 'direct' then 'direct_traffic'
            when lower(source) = 'referral' then 'referral_traffic'
            when lower(source) = 'social' then 'social_media'
            else 'other'
        end as traffic_channel,

        -- Boolean channel flags
        lower(source) = 'paid' as is_paid_traffic,
        lower(source) = 'organic' as is_organic_traffic,

        -- Metadata
        _loaded_at as loaded_at_timestamp

    from source

)

select * from renamed