{% docs customer_segment_logic %}
## Customer Segment Classification

Customers are segmented based on **completed order count** and **total revenue**:

| Segment | Completed Orders | Total Revenue | Description |
|---------|-----------------|---------------|-------------|
| no_purchases | 0 | any | Registered but never bought |
| one_time_low | 1 | < €100 | Single low-value purchase |
| one_time_high | 1 | >= €100 | Single high-value purchase |
| occasional | 2-4 | < €500 | Returning, lower spend |
| occasional_high_value | 2-4 | >= €500 | Returning, higher spend |
| frequent | 5+ | < €1,000 | Loyal, moderate spend |
| vip | 5+ | >= €1,000 | Loyal, high spend |

**Downstream usage:**
```sql
select
    customer_segment,
    count(*)                        as customers,
    round(avg(total_revenue), 2)    as avg_revenue,
    round(avg(avg_order_value), 2)  as avg_aov
from {% raw %}{{ ref('int_customers__order_history') }}{% endraw %}
group by 1
order by avg_revenue desc
```
{% enddocs %}


{% docs recency_tier_logic %}
## Recency Tier Classification

Customers are classified by days since their most recent completed order:

| Tier | Days Since Last Order | Marketing Action |
|------|-----------------------|-----------------|
| never_purchased | NULL (no orders) | Activation campaign |
| active | <= 30 days | Upsell / cross-sell |
| warm | 31-90 days | Re-engagement email |
| cooling | 91-180 days | Win-back campaign |
| churned | 180+ days | Reactivation or suppress |

**Note:** This metric uses current_timestamp() so values shift daily.
For stable segmentation, use a snapshot or add a calculation date column.

**Combined with customer_segment for RFM targeting:**
```sql
select
    recency_tier,
    customer_segment,
    count(*)                        as customers
from {% raw %}{{ ref('int_customers__order_history') }}{% endraw %}
where customer_segment in ('frequent', 'vip')
group by 1, 2
order by customers desc
```
{% enddocs %}