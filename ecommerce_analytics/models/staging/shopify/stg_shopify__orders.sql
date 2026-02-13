-- models/staging/shopify/stg_shopify__orders.sql
-- Minimal version - source connection and column renames only
-- Add Date Dimension Columns 
-- Add Financial Derived Columns

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

        -- Order financials (derived)
        -- Gross amount: always positive regardless of status
        abs(total_amount)                                   as gross_amount,

        -- Revenue: only completed orders contribute revenue
        case
            when status = 'completed'
                then total_amount
            else 0
        end                                                 as revenue,

        -- Refund amount: positive value for refunded orders only
        case
            when status = 'refunded'
                then abs(total_amount)
            else 0
        end                                                 as refund_amount,

        -- Net revenue impact: completed positive, refunded negative, others 0
        case
            when status = 'completed' then total_amount
            when status = 'refunded'  then total_amount
            else 0
        end                                                 as net_revenue_impact,

        -- Order status
        status              as order_status,

        -- Metadata
        created_at          as order_created_at,
        updated_at          as order_updated_at,
        _loaded_at          as loaded_at_timestamp

    from source

),

final as (

    select
        -- Keys
        order_id,
        customer_id,

        -- Time dimensions
        order_date,
        order_date_day,
        order_date_week,
        order_date_month,
        order_year,
        order_quarter,
        order_month,
        order_day_of_week,

        -- Financials
        total_amount,
        gross_amount,
        revenue,
        refund_amount,
        net_revenue_impact,

        -- Status
        order_status,

        -- Metadata
        order_created_at,
        order_updated_at,
        loaded_at_timestamp

    from renamed

)

select * from final