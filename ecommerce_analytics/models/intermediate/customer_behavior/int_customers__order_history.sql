-- models/intermediate/customer_behavior/int_customers__order_history.sql
-- Minimal version - aggregate orders per customer
-- No joins yet, no complex logic, just prove the aggregation works

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

        -- Date metrics
        min(case when is_completed
                 then order_date end)                   as first_order_date,
        max(case when is_completed
                 then order_date end)                   as last_order_date

    from orders
    group by customer_id

)

select * from customer_orders