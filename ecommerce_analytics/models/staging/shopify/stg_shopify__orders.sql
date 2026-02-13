-- models/staging/shopify/stg_shopify__orders.sql
-- Minimal version - source connection and column renames only
-- Business logic and derived columns added incrementally

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

        -- Order timing (raw)
        order_date,

        -- Order financials (raw)
        total_amount,

        -- Order status (renamed for clarity)
        status              as order_status,

        -- Metadata
        created_at          as order_created_at,
        updated_at          as order_updated_at,
        _loaded_at          as loaded_at_timestamp

    from source

)

select * from renamed