-- models/marts/core/fct_orders.sql
-- Fact table for order-level analysis with embedded customer dimensions.
-- 
-- Design: Denormalized star schema fact table optimized for BI tools.
-- Grain: One row per order_id
-- Updates: Daily (full refresh from intermediate layer)

{{
    config(
        materialized='table',
        tags=['daily', 'core', 'fact_table']
    )
}}

with orders as (

    select * from {{ ref('int_orders__customers_joined') }}

),

-- FIX: Calculate base metrics once to keep the final CTE DRY
metrics_staging as (

    select 
        *,
        datediff(
            'day',
            cast(order_date as date),
            '{{ var("recency_reference_date") }}'
        ) as days_since_order
    from orders

),

final as (

    select
        -- Primary key
        order_id,

        -- Foreign keys
        customer_id,

        -- Order attributes
        order_status,
        revenue,

        -- Customer attributes (denormalized for BI performance)
        customer_full_name,
        customer_country,

        -- Time dimensions (raw)
        order_date,

        -- Derived time dimensions
        cast(order_date as date)                        as order_date_day,
        date_trunc('week', cast(order_date as date))    as order_date_week,
        date_trunc('month', cast(order_date as date))   as order_date_month,
        date_trunc('quarter', cast(order_date as date)) as order_date_quarter,
        date_trunc('year', cast(order_date as date))    as order_date_year,

        -- Customer tenure metrics
        days_from_signup_to_order,
        is_new_customer_order,

        -- Business Logic Flags (Configuration-Driven)
        (revenue >= {{ var('high_value_threshold') }})          as is_high_value_order,
        (order_status = 'completed')                            as is_completed_order,
        (days_since_order <= {{ var('recent_order_days') }})    as is_recent_order,

        -- Recency Metrics
        days_since_order,

        -- Order age category (for cohort analysis : Hardcoded to guarantee mathematical match with string labels)
        case
            when days_since_order <= 30    then '1. 0-30 days'
            when days_since_order <= 90    then '2. 31-90 days'
            when days_since_order <= 180   then '3. 91-180 days'
            when days_since_order <= 365   then '4. 181-365 days'
            else                                '5. 365+ days'
        end                                             as order_age_category

    from metrics_staging

)

select * from final