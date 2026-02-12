{% docs ctr_definition %}
## Click-Through Rate (CTR)

**Formula:** `clicks / impressions`

**Range:** 0.0 to 1.0 (presented as percentage in dashboards: multiply by 100)

**NULL handling:** Returns NULL when impressions = 0 (no delivery day).
Use `COALESCE(click_through_rate, 0)` for aggregations.

**Industry benchmarks:**
- Display ads: 0.1% - 0.3% is typical
- Search ads: 2% - 5% is typical
- High performance in this model: >= 4%

**Downstream usage:**
```sql
select
    ad_id,
    avg(coalesce(click_through_rate, 0))    as avg_ctr,
    sum(clicks)                             as total_clicks,
    sum(impressions)                        as total_impressions,
    sum(clicks) / nullif(sum(impressions), 0) as blended_ctr
from {% raw %}{{ ref('stg_facebook_ads__ad_performance') }}{% endraw %}
group by 1
```
{% enddocs %}


{% docs cpc_definition %}
## Cost Per Click (CPC)

**Formula:** `spend / clicks`

**Unit:** EUR

**NULL handling:** Returns NULL when clicks = 0.

**Lower is better.** High CPC may indicate low ad relevance or
high competition for the target audience.

**Downstream usage:** Always use blended CPC (sum_spend / sum_clicks)
when aggregating across days, not avg(cost_per_click).
{% enddocs %}


{% docs cpm_definition %}
## Cost Per Mille (CPM)

**Formula:** `(spend / impressions) * 1000`

**Unit:** EUR per 1,000 impressions

**NULL handling:** Returns NULL when impressions = 0.

**Industry standard** for comparing reach efficiency across
campaigns regardless of click performance. Use for brand
awareness campaign analysis.
{% enddocs %}


{% docs cpa_definition %}
## Cost Per Acquisition (CPA)

**Formula:** `spend / conversions`

**Unit:** EUR per conversion

**NULL handling:** Returns NULL when conversions = 0.

**Lower is better.** The primary efficiency metric for
performance marketing campaigns.

**Important:** Conversion attribution window may cause
CPA to appear artificially low on recent dates (conversions
still being attributed). Use with caution for data < 7 days old.
{% enddocs %}


{% docs cvr_definition %}
## Conversion Rate (CVR)

**Formula:** `conversions / clicks`

**Range:** 0.0 to 1.0 (presented as percentage: multiply by 100)

**NULL handling:** Returns NULL when clicks = 0.

**Industry benchmarks:**
- E-commerce: 1% - 4% is typical
- High intent (retargeting): up to 10%

**Downstream usage:** Always use blended CVR (sum_conversions /
sum_clicks) when aggregating, not avg(conversion_rate).
{% enddocs %}


{% docs performance_tier_thresholds %}
## Performance Tier Classification

Ad days are classified based on Click-Through Rate (CTR):

| Tier | CTR Threshold | Description |
|------|--------------|-------------|
| no_delivery | 0 impressions | Ad had no delivery that day |
| underperforming | CTR < 1% | Below minimum viable performance |
| low_performance | 1% <= CTR < 2% | Acceptable but improvable |
| medium_performance | 2% <= CTR < 4% | Good performance |
| high_performance | CTR >= 4% | Excellent engagement |

**Note:** Thresholds are configurable via dbt variables.
Current thresholds are calibrated for e-commerce display ads.

**Downstream usage:**
```sql
select
    performance_tier,
    count(distinct ad_id)           as unique_ads,
    sum(spend)                      as total_spend,
    sum(conversions)                as total_conversions,
    avg(coalesce(cost_per_acquisition, 0)) as avg_cpa
from {% raw %}{{ ref('stg_facebook_ads__ad_performance') }}{% endraw %}
group by 1
order by total_spend desc
```
{% enddocs %}