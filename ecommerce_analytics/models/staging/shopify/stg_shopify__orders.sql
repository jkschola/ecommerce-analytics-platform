-- models/staging/shopify/stg_shopify__orders.sql

{{
    config(
        materialized='view',
        tags=['daily']
    )
}}

with source as (

    select * from {{ source('shopify', 'orders') }}

),

renamed as (

    select
        -- Primary key
        order_id,

        -- Foreign keys
        customer_id,

        -- Order attributes
        order_date,
        status as order_status,
        total_amount as order_total,

        -- Derived boolean flags
        case
            when status = 'completed' then true
            else false
        end as is_completed,

        case
            when status = 'cancelled' then true
            else false
        end as is_cancelled,

        case
            when status = 'refunded' then true
            else false
        end as is_refunded,

        case
            when status = 'pending' then true
            else false
        end as is_pending,

        -- Revenue calculations (only count completed orders)
        case
            when status = 'completed' then total_amount
            else 0
        end as order_revenue,

        -- Refund amount (absolute value for refunded orders)
        case
            when status = 'refunded' then abs(total_amount)
            else 0
        end as refund_amount,

        -- Order value categories
        case
            when abs(total_amount) < 50 then 'small'
            when abs(total_amount) < 150 then 'medium'
            when abs(total_amount) < 300 then 'large'
            else 'very_large'
        end as order_size_category,

        -- Metadata timestamps
        created_at as order_created_at,
        updated_at as order_updated_at,
        _loaded_at as loaded_at_timestamp

    from source

)

select * from renamed