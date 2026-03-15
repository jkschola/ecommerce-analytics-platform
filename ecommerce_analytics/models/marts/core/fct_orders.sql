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
        is_new_customer_order

    from orders

)

select * from final