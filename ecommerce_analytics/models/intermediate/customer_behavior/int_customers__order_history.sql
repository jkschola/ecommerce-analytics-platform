-- models/intermediate/customer_behavior/int_customers__order_history.sql
-- Minimal version - aggregate orders per customer
-- No joins yet, no complex logic, just prove the aggregation works
-- Add Derived Date and Lifecycle Metrics

{{
    config(
        materialized='view',
        tags=['intermediate', 'daily']
    )
}}

with orders as (

    select * from {{ ref('stg_shopify__orders') }}

),

customer_orders as (

    select
        customer_id,

        -- Order counts
        count(*)                                        as total_orders,
        count(case when is_completed then 1 end)        as completed_orders,
        count(case when is_refunded then 1 end)         as refunded_orders,
        count(case when is_cancelled then 1 end)        as cancelled_orders,
        count(case when is_pending then 1 end)          as pending_orders,

        -- Revenue metrics
        sum(revenue)                                    as total_revenue,
        sum(refund_amount)                              as total_refunds,
        sum(net_revenue_impact)                         as net_revenue,
        avg(case when is_completed
                 then revenue end)                      as avg_order_value,

        -- Date metrics (raw)
        min(case when is_completed
                 then order_date end)                   as first_order_date,
        max(case when is_completed
                 then order_date end)                   as last_order_date

    from orders
    group by customer_id

),

with_lifecycle as (

    select
        customer_id,

        -- Order counts
        total_orders,
        completed_orders,
        refunded_orders,
        cancelled_orders,
        pending_orders,

        -- Revenue metrics
        total_revenue,
        total_refunds,
        net_revenue,
        round(avg_order_value, 2)                       as avg_order_value,

        -- Refund rate (handle division by zero)
        round(
            total_refunds / nullif(total_revenue, 0),
        4)                                              as refund_rate,

        -- Date metrics (raw)
        first_order_date,
        last_order_date,

        -- Date metrics (derived)
        datediff(
            'day',
            first_order_date,
            last_order_date
        )                                               as days_between_first_and_last_order,

        datediff(
            'day',
            last_order_date,
            current_timestamp()
        )                                               as days_since_last_order,

        datediff(
            'day',
            first_order_date,
            current_timestamp()
        )                                               as days_as_customer

    from customer_orders

)

select * from with_lifecycle