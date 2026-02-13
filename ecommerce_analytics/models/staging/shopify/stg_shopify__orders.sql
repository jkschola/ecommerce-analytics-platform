-- models/staging/shopify/stg_shopify__orders.sql
-- Minimal version - source connection and column renames only
-- Add Date Dimension Columns 

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

        -- Order timing (derived)
        cast(order_date as date)                            as order_date_day,
        date_trunc('week', cast(order_date as date))        as order_date_week,
        date_trunc('month', cast(order_date as date))       as order_date_month,
        extract(year from order_date)                       as order_year,
        extract(quarter from order_date)                    as order_quarter,
        extract(month from order_date)                      as order_month,
        extract(dayofweek from order_date)                  as order_day_of_week,

        -- Order financials (raw)
        total_amount,

        -- Order status
        status              as order_status,

        -- Metadata
        created_at          as order_created_at,
        updated_at          as order_updated_at,
        _loaded_at          as loaded_at_timestamp

    from source

)

select * from renamed