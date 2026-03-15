-- models/marts/core/dim_customers.sql
-- Customer dimension table with pre-aggregated lifetime metrics.
--
-- Design: Type 1 SCD (current state snapshot)
-- Grain: One row per customer_id
-- 
-- Sources:
--   - stg_shopify__customers: Base customer attributes (name, email, country)
--   - int_customers__order_history: Pre-aggregated lifetime metrics and segments
-- 
-- Architecture:
--   This dimension leverages the customer-grain intermediate layer (int_customers__order_history) instead of re-aggregating from facts.
--   The intermediate layer handles all aggregation logic; this dimension adds presentation formatting and additional derived flags.

{{
    config(
        materialized='table',
        tags=['daily', 'core', 'dimension']
    )
}}

with customers as (

    select * from {{ ref('stg_shopify__customers') }}

),

customer_metrics as (

    -- Pre-aggregated metrics from intermediate layer
    select * from {{ ref('int_customers__order_history') }}

),

final as (

    select
        -- Primary key
        c.customer_id,

        -- Customer attributes (from staging)
        c.full_name                                     as customer_full_name,
        c.customer_email,
        c.customer_country,
        c.customer_created_at,

        -- Account age (derived from staging)
        -- LEAD AE FIX: Cast timestamp to date for safe diffing
        datediff(
            'day',
            cast(c.customer_created_at as date),
            '{{ var("recency_reference_date") }}'
        )                                               as account_age_days,

        -- Lifetime order counts (from intermediate)
        coalesce(m.total_orders, 0)                     as lifetime_orders,
        coalesce(m.completed_orders, 0)                 as completed_orders,
        coalesce(m.refunded_orders, 0)                  as refunded_orders,
        coalesce(m.cancelled_orders, 0)                 as cancelled_orders,
        coalesce(m.pending_orders, 0)                   as pending_orders,

        -- Revenue metrics (from intermediate)
        coalesce(m.total_revenue, 0)                    as lifetime_revenue,
        coalesce(m.total_refunds, 0)                    as total_refunds,
        coalesce(m.net_revenue, 0)                      as net_revenue,
        coalesce(m.avg_order_value, 0)                  as avg_order_value,
        coalesce(m.refund_rate, 0)                      as refund_rate, -- LEAD AE FIX

        -- Temporal metrics (from intermediate)
        m.first_order_date,
        m.last_order_date,
        m.days_between_first_and_last_order,
        m.days_since_last_order,
        m.days_as_customer,

        -- Customer behavior flags (from intermediate)
        coalesce(m.is_repeat_customer, false)           as is_repeat_customer,
        coalesce(m.is_active_customer, false)           as is_active_customer,

        -- Customer segments (from intermediate)
        coalesce(m.customer_segment, 'no_purchases')    as customer_segment,
        coalesce(m.recency_tier, 'never_purchased')     as recency_tier

    from customers c
    
    left join customer_metrics m
        on c.customer_id = m.customer_id

)

select * from final