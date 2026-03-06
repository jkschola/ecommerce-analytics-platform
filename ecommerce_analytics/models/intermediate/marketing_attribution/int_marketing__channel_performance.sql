-- models/intermediate/marketing_attribution/int_marketing__channel_performance.sql
-- Sessions Aggregated by Day and Channel
-- Add Facebook Ads and Join Both Sources 


{{
    config(
        materialized='view',
        tags=['intermediate', 'daily']
    )
}}

with sessions as (

    select * from {{ ref('stg_google_analytics__sessions') }}

),

ads as (

    select * from {{ ref('stg_facebook_ads__ad_performance') }}

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

),

ads_by_day as (

    select
        performance_date                    as activity_date,

        -- Aggregate all ads into one paid_advertising row per day
        sum(impressions)                    as total_impressions,
        sum(clicks)                         as total_ad_clicks,
        sum(spend)                          as total_spend,
        sum(conversions)                    as total_conversions,

        -- Blended metrics (sum/sum, not avg of rates)
        round(
            sum(clicks) / nullif(sum(impressions), 0),
        4)                                  as blended_ctr,
        round(
            sum(spend) / nullif(sum(clicks), 0),
        2)                                  as blended_cpc,
        round(
            sum(spend) / nullif(sum(conversions), 0),
        2)                                  as blended_cpa

    from ads
    group by performance_date

),

-- Left join: keep all session channels, enrich paid with ad metrics
joined as (

    select
        s.activity_date,
        s.traffic_channel,

        -- Session metrics (all channels)
        s.total_sessions,
        s.unique_users,
        s.total_page_views,
        s.total_session_duration_seconds,
        s.bounced_sessions,
        s.engaged_sessions,
        s.bounce_rate,
        s.avg_session_duration_seconds,

        -- Ad metrics (paid_advertising channel only, null for others)
        a.total_impressions,
        a.total_ad_clicks,
        a.total_spend,
        a.total_conversions,
        a.blended_ctr,
        a.blended_cpc,
        a.blended_cpa,

        -- Is this a paid channel? (uses variable)
        (s.traffic_channel = '{{ var("paid_channel_name") }}')   as is_paid_channel

    from sessions_by_channel s
    left join ads_by_day a
        on  s.activity_date  = a.activity_date
        and s.traffic_channel = '{{ var("paid_channel_name") }}'

),

final as (

    select
        -- Keys / dimensions
        activity_date,
        traffic_channel,
        is_paid_channel,

        -- Session metrics
        total_sessions,
        unique_users,
        total_page_views,
        total_session_duration_seconds,
        bounced_sessions,
        engaged_sessions,
        bounce_rate,
        avg_session_duration_seconds,

        -- Paid metrics (null for non-paid channels)
        total_impressions,
        total_ad_clicks,
        total_spend,
        total_conversions,
        blended_ctr,
        blended_cpc,
        blended_cpa

    from joined

)

select * from final