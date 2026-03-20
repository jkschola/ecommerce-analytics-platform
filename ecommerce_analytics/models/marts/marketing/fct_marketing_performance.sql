-- models/marts/marketing/fct_marketing_performance.sql
-- Marketing performance fact table at daily channel grain.
--
-- Design: Denormalized fact table for marketing ROI analysis
-- Grain: One row per (activity_date, traffic_channel)
-- 
-- Source: int_marketing__channel_performance (pre-aggregated metrics)

{{
    config(
        materialized='table',
        tags=['daily', 'marketing', 'fact_table']
    )
}}

with marketing_performance as (

    select * from {{ ref('int_marketing__channel_performance') }}

),

final as (

    select
        -- Primary Key (Single surrogate key for BI joins)
        {{ dbt_utils.generate_surrogate_key(['activity_date', 'traffic_channel']) }} as marketing_id,

        -- Composite business keys
        activity_date,
        traffic_channel,

        -- Derived time dimensions for BI
        date_trunc('week', cast(activity_date as date))    as activity_date_week,
        date_trunc('month', cast(activity_date as date))   as activity_date_month,
        date_trunc('quarter', cast(activity_date as date)) as activity_date_quarter,
        date_trunc('year', cast(activity_date as date))    as activity_date_year,

        -- Channel classification
        is_paid_channel,

        -- Session metrics (Google Analytics)
        total_sessions,
        unique_users,
        total_page_views,
        total_session_duration_seconds,
        bounced_sessions,
        engaged_sessions,
        bounce_rate,
        avg_session_duration_seconds,

        -- Ad metrics (Facebook Ads - paid channel only)
        total_impressions,
        total_ad_clicks,
        total_spend,
        total_conversions,
        blended_ctr,
        blended_cpc,
        blended_cpa,

        -- ============================================
        -- Presentation-Layer Performance Flags
        -- ============================================
        
        -- High traffic day: Sessions met the high-volume threshold
        (coalesce(total_sessions, 0) >= {{ var('marketing_high_traffic_sessions') }}) as is_high_traffic_day,
        
        -- High spend day: Paid channel spend met the threshold
        (
            is_paid_channel 
            and coalesce(total_spend, 0) >= {{ var('marketing_high_spend_threshold') }}
        )                                                                             as is_high_spend_day,

        -- Engaged audience: Bounce rate is below the acceptable threshold (quality traffic)
        (
            bounce_rate is not null 
            and bounce_rate <= {{ var('marketing_engaged_bounce_rate_threshold') }}
        )                                                                             as is_engaged_audience,
        
        -- Efficient ad spend: Paid channel CPC is below the strict efficiency threshold
        (
            is_paid_channel 
            and blended_cpc is not null 
            and blended_cpc <= {{ var('marketing_efficient_cpc_threshold') }}
        )                                                                             as is_efficient_spend,
        
        -- Converting day: Campaign successfully drove at least 1 conversion
        (coalesce(total_conversions, 0) > 0)                                          as is_converting_day,

        -- ============================================
        -- Presentation-Layer Performance Tiers
        -- ============================================

        -- Traffic tier (for volume-based cohort analysis)
        case
            when coalesce(total_sessions, 0) = 0 then '1. No Traffic'
            when total_sessions < 100            then '2. Low'
            when total_sessions < 500            then '3. Medium'
            when total_sessions < 1000           then '4. High'
            else                                      '5. Very High'
        end                                             as traffic_tier,

        -- Spend tier (for budget efficiency analysis)
        case
            when not is_paid_channel             then '0. Non-Paid'
            when coalesce(total_spend, 0) = 0    then '1. No Spend'
            when total_spend < 50                then '2. Low'
            when total_spend < 100               then '3. Medium'
            when total_spend < 200               then '4. High'
            else                                      '5. Very High'
        end                                             as spend_tier,

        -- Engagement quality tier (based on bounce rate)
        case
            when bounce_rate is null             then '0. No Data'
            when bounce_rate <= 0.30             then '1. Excellent'
            when bounce_rate <= 0.40             then '2. Good'
            when bounce_rate <= 0.60             then '3. Average'
            when bounce_rate <= 0.80             then '4. Poor'
            else                                      '5. Very Poor'
        end                                             as engagement_tier

    from marketing_performance

)

select * from final