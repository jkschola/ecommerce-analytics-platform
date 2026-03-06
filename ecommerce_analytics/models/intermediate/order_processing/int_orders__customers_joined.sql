-- models/intermediate/order_processing/int_orders__customers_joined.sql
-- Purpose: Enrich orders with customer attributes for downstream marts
-- Demonstrates: joining two staging models into reusable intermediate

{{
    config(
        materialized='view',
        tags=['intermediate', 'daily']
    )
}}

with orders as (

    select * from {{ ref('stg_shopify__orders') }}

),

customers as (

    select * from {{ ref('stg_shopify__customers') }}

),

joined as (

    select
        -- Order keys
        orders.order_id,
        orders.customer_id,

        -- Customer attributes (for slicing revenue by customer dims)
        customers.customer_email,
        customers.full_name                         as customer_full_name,
        customers.customer_country,
        customers.customer_created_at,

        -- Order timing
        orders.order_date,
        orders.order_date_day,
        orders.order_date_week,
        orders.order_date_month,
        orders.order_year,
        orders.order_quarter,
        orders.order_month,
        orders.order_day_of_week,

        -- Order financials
        orders.total_amount,
        orders.gross_amount,
        orders.revenue,
        orders.refund_amount,
        orders.net_revenue_impact,

        -- Order status
        orders.order_status,
        orders.is_completed,
        orders.is_refunded,
        orders.is_cancelled,
        orders.is_pending,
        orders.is_financially_closed,
        orders.is_active_order,

        -- Metadata
        orders.order_created_at,
        orders.order_updated_at,
        orders.loaded_at_timestamp

    from orders
    inner join customers
        on orders.customer_id = customers.customer_id

)

select * from joined