-- models/staging/shopify/stg_shopify__customers.sql

{{
    config(
        materialized='view',
        tags=['daily', 'pii']
    )
}}

with source as (

    select * from {{ source('shopify', 'customers') }}

),

renamed as (

    select
        -- Primary key
        customer_id,

        -- Customer attributes
        email as customer_email,
        first_name,
        last_name,
        initcap(first_name || ' ' || last_name) as full_name,
        {{ dbt_utils.generate_surrogate_key(['first_name', 'last_name', 'email']) }} as customer_unique_key,
        country as customer_country,

        -- Metadata timestamps
        created_at as customer_created_at,
        updated_at as customer_updated_at,
        _loaded_at as loaded_at_timestamp

    from source

)

select * from renamed