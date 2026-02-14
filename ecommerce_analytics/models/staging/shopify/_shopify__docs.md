{% docs customer_id %}
Unique identifier for each customer in the Shopify platform.

This is the primary key for the customers table and is used as a foreign key in the orders table.

**Type:** Integer  
**Source:** Shopify internal ID
{% enddocs %}


{% docs revenue_recognition_logic %}
## Revenue Recognition Logic

Revenue is recognized **only for completed orders**.

| order_status | total_amount | revenue | refund_amount | net_revenue_impact |
|-------------|-------------|---------|--------------|-------------------|
| completed | €120.00 | €120.00 | €0.00 | +€120.00 |
| pending | €85.00 | €0.00 | €0.00 | €0.00 |
| cancelled | €45.00 | €0.00 | €0.00 | €0.00 |
| refunded | -€90.00 | €0.00 | €90.00 | -€90.00 |

### Why This Approach?

- **Pending** excluded: order may not complete
- **Cancelled** excluded: no revenue was ever realized
- **Refunded** shows negative net impact: revenue was realized then returned

### Downstream Usage
```sql
-- Monthly net revenue
select
    order_date_month,
    sum(net_revenue_impact)                     as net_revenue,
    sum(revenue)                                as gross_revenue,
    sum(refund_amount)                          as total_refunds,
    round(
        sum(refund_amount) 
        / nullif(sum(revenue), 0) * 100,
    2)                                          as refund_rate_pct
from {% raw %}{{ ref('stg_shopify__orders') }}{% endraw %}
group by 1
order by 1
```
{% enddocs %}


{% docs order_status_definitions %}
## Order Status Definitions

| Status | Description | is_active_order | is_financially_closed |
|--------|-------------|-----------------|----------------------|
| pending | Placed, not yet fulfilled | ✅ Yes | ❌ No |
| completed | Fulfilled and delivered | ✅ Yes | ✅ Yes |
| cancelled | Cancelled before fulfillment | ❌ No | ❌ No |
| refunded | Completed then returned | ❌ No | ✅ Yes |

### Flag Reference

- **is_active_order**: `pending` + `completed`
- **is_financially_closed**: `completed` + `refunded`
- Each order maps to exactly **one** TRUE status flag
{% enddocs %}