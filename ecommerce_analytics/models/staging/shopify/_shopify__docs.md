{% docs customer_id %}
Unique identifier for each customer in the Shopify platform.

This is the primary key for the customers table and is used as a foreign key in the orders table.

**Type:** Integer  
**Source:** Shopify internal ID
{% enddocs %}

{% docs order_revenue_logic %}
## Revenue Recognition Logic

Revenue is only recognized for **completed** orders:
```sql
case
    when status = 'completed' then total_amount
    else 0
end as order_revenue
```

**Excluded from revenue:**
- Pending orders (not yet fulfilled)
- Cancelled orders (never completed)
- Refunded orders (reversed transactions)

**Refunds** are tracked separately in the `refund_amount` field.
{% enddocs %}