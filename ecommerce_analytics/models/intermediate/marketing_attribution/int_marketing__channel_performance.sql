-- models/intermediate/marketing_attribution/int_marketing__channel_performance.sql
-- Sessions aggregated by day + channel only

{{
    config(
        materialized='view',
        tags=['intermediate', 'daily']
    )
}}

with sessions as (

    select * from {{ ref('stg_google_analytics__sessions') }}

),

sessions_by_channel as (

    select
        cast(session_date as date)          as activity_date,
        traffic_channel,

        -- Session volume
        count(*)                            as total_sessions,
        count(distinct user_id)             as unique_users,

        -- Engagement metrics
        sum(page_views)                     as total_page_views,
        sum(session_duration_seconds)       as total_session_duration_seconds,
        sum(case when is_bounce
                 then 1 else 0 end)         as bounced_sessions,
        sum(case when is_engaged_session
                 then 1 else 0 end)         as engaged_sessions,

        -- Computed rates
        round(
            sum(case when is_bounce then 1 else 0 end)
            / nullif(count(*), 0),
        4)                                  as bounce_rate,

        round(
            avg(session_duration_seconds),
        2)                                  as avg_session_duration_seconds

    from sessions
    group by
        cast(session_date as date),
        traffic_channel

)

select * from sessions_by_channel