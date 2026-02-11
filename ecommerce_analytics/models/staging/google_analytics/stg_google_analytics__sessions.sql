-- models/staging/google_analytics/stg_google_analytics__sessions.sql
-- Add derived time columns
-- Add business logic columns (engagement, traffic classification)

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

        -- Engagement classification (see docs: engagement_level_logic)
        case
            when page_views = 1
                and session_duration_seconds < 30                   then 'bounce'
            when page_views <= 3
                and session_duration_seconds < 60                   then 'low_engagement'
            when page_views <= 7
                and session_duration_seconds < 300                  then 'medium_engagement'
            else                                                         'high_engagement'
        end                                                         as engagement_level,

        -- Engagement flags
        (
            page_views = 1
            and session_duration_seconds < 30
        )                                                           as is_bounce,

        (
            page_views >= 5
            or session_duration_seconds >= 180
        )                                                           as is_engaged_session,

        -- Attribution (renamed for clarity)
        lower(source)   as traffic_source,
        lower(medium)   as traffic_medium,
        campaign        as campaign_name,

        -- Traffic classification
        case
            when lower(source) = 'organic'                          then 'organic_search'
            when lower(source) = 'paid'                             then 'paid_advertising'
            when lower(source) = 'direct'                           then 'direct_traffic'
            when lower(source) = 'referral'                         then 'referral_traffic'
            when lower(source) = 'social'                           then 'social_media'
            else                                                         'other'
        end                                                         as traffic_channel,

        -- Traffic flags
        (lower(source) = 'paid')                                    as is_paid_traffic,
        (lower(source) = 'organic')                                 as is_organic_traffic,

        -- Metadata
        _loaded_at      as loaded_at_timestamp

    from source

),

-- Final select with explicit column ordering
final as (

    select
        -- Keys
        session_id,
        user_id,

        -- Time dimensions
        session_date,
        session_date_day,
        session_date_week,
        session_date_month,

        -- Engagement metrics
        page_views,
        session_duration_seconds,
        session_duration_minutes,
        avg_time_per_page_seconds,
        engagement_level,

        -- Engagement flags
        is_bounce,
        is_engaged_session,

        -- Attribution
        traffic_source,
        traffic_medium,
        campaign_name,
        traffic_channel,

        -- Traffic flags
        is_paid_traffic,
        is_organic_traffic,

        -- Metadata
        loaded_at_timestamp

    from renamed

)

select * from final