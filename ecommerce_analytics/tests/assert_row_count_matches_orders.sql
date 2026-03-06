-- tests/assert_row_count_matches_orders.sql
-- Validates INNER JOIN didn't lose or duplicate rows

with orders_count as (
    select count(*) as cnt
    from {{ ref('stg_shopify__orders') }}
),

joined_count as (
    select count(*) as cnt
    from {{ ref('int_orders__customers_joined') }}
)

select
    orders_count.cnt as orders_count,
    joined_count.cnt as joined_count,
    abs(orders_count.cnt - joined_count.cnt) as row_diff
from orders_count
cross join joined_count
where orders_count.cnt != joined_count.cnt