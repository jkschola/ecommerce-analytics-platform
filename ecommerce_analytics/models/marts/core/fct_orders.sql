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
        is_new_customer_order,

        -- Business Logic Flags
        -- High-value order: Revenue in top 20% (configurable threshold)
        (revenue >= 150)                                as is_high_value_order,

        -- Completed order: Status indicates successful transaction
        (order_status = 'completed')                    as is_completed_order,

        -- Recent order: Within last 90 days from reference date
        (
            datediff(
                'day',
                cast(order_date as date),
                '{{ var("recency_reference_date") }}'
            ) <= 90
        )                                               as is_recent_order

        -- Recency Metrics
        -- Days since order (from reference date)
        datediff(
            'day',
            cast(order_date as date),
            '{{ var("recency_reference_date") }}'
        )                                               as days_since_order,

        -- Order age category (for cohort analysis)
        case
            when datediff(
                'day',
                cast(order_date as date),
                '{{ var("recency_reference_date") }}'
            ) <= 30                                     then '0-30 days'
            when datediff(
                'day',
                cast(order_date as date),
                '{{ var("recency_reference_date") }}'
            ) <= 90                                     then '31-90 days'
            when datediff(
                'day',
                cast(order_date as date),
                '{{ var("recency_reference_date") }}'
            ) <= 180                                    then '91-180 days'
            when datediff(
                'day',
                cast(order_date as date),
                '{{ var("recency_reference_date") }}'
            ) <= 365                                    then '181-365 days'
            else                                             '365+ days'
        end                                             as order_age_category

    from orders

)

select * from final