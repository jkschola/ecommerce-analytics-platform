-- models/intermediate/customer_behavior/int_customers__order_history.sql
-- Minimal version - aggregate orders per customer
-- No joins yet, no complex logic, just prove the aggregation works
-- Add Derived Date and Lifecycle Metrics
-- Add Customer Segmentation Logic

-- models/intermediate/customer_behavior/int_customers__order_history.sql

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

        count(*)                                        as total_orders,
        count(case when is_completed then 1 end)        as completed_orders,
        count(case when is_refunded then 1 end)         as refunded_orders,
        count(case when is_cancelled then 1 end)        as cancelled_orders,
        count(case when is_pending then 1 end)          as pending_orders,

        sum(revenue)                                    as total_revenue,
        sum(refund_amount)                              as total_refunds,
        sum(net_revenue_impact)                         as net_revenue,
        avg(case when is_completed
                 then revenue end)                      as avg_order_value,

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
        total_orders,
        completed_orders,
        refunded_orders,
        cancelled_orders,
        pending_orders,
        total_revenue,
        total_refunds,
        net_revenue,
        round(avg_order_value, 2)                       as avg_order_value,

        round(
            total_refunds / nullif(total_revenue, 0),
        4)                                              as refund_rate,

        first_order_date,
        last_order_date,

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

),

with_segments as (

    select
        customer_id,
        total_orders,
        completed_orders,
        refunded_orders,
        cancelled_orders,
        pending_orders,
        total_revenue,
        total_refunds,
        net_revenue,
        avg_order_value,
        refund_rate,
        first_order_date,
        last_order_date,
        days_between_first_and_last_order,
        days_since_last_order,
        days_as_customer,

        -- Is this a repeat buyer?
        (completed_orders > 1)                          as is_repeat_customer,

        -- Has customer bought in last 90 days? (active customer)
        -- is_active_customer: TRUE only if customer has completed orders AND ordered recently

        (last_order_date is not null
        and days_since_last_order <= 90)                as is_active_customer,

        -- Customer value segment (see docs: customer_segment_logic)
        case
            when completed_orders = 0               then 'no_purchases'
            when completed_orders = 1
                 and total_revenue < 100             then 'one_time_low'
            when completed_orders = 1
                 and total_revenue >= 100            then 'one_time_high'
            when completed_orders between 2 and 4
                 and total_revenue < 500             then 'occasional'
            when completed_orders between 2 and 4
                 and total_revenue >= 500            then 'occasional_high_value'
            when completed_orders >= 5
                 and total_revenue < 1000            then 'frequent'
            when completed_orders >= 5
                 and total_revenue >= 1000           then 'vip'
        end                                             as customer_segment,

        -- RFM: Recency tier (for marketing targeting)
        case
            when days_since_last_order is null      then 'never_purchased'
            when days_since_last_order <= 30        then 'active'
            when days_since_last_order <= 90        then 'warm'
            when days_since_last_order <= 180       then 'cooling'
            else                                         'churned'
        end                                             as recency_tier

    from with_lifecycle

),

final as (

    select
        -- Key
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
        avg_order_value,
        refund_rate,

        -- Date metrics
        first_order_date,
        last_order_date,
        days_between_first_and_last_order,
        days_since_last_order,
        days_as_customer,

        -- Segmentation
        is_repeat_customer,
        is_active_customer,
        customer_segment,
        recency_tier

    from with_segments

)

select * from final