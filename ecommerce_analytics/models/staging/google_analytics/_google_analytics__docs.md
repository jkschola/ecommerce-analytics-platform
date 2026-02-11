{% docs engagement_level_logic %}
## Engagement Level Classification

Sessions are classified into 4 engagement levels based on depth and duration:

### Bounce
- **Definition:** 1 page view AND <30 seconds
- **Indicates:** User left immediately, no engagement
- **Typical %:** 40-60% of all sessions

### Low Engagement
- **Definition:** ≤3 page views AND <60 seconds
- **Indicates:** Brief visit, minimal exploration
- **Typical %:** 20-30% of sessions

### Medium Engagement
- **Definition:** ≤7 page views AND <5 minutes
- **Indicates:** Moderate exploration
- **Typical %:** 15-25% of sessions

### High Engagement
- **Definition:** >7 page views OR >5 minutes
- **Indicates:** Deep engagement, potential conversion
- **Typical %:** 5-15% of sessions

**Usage in downstream models:**
```sql
-- Calculate engagement rate by channel
select
    traffic_channel,
    count(*)                                            as total_sessions,
    sum(case when engagement_level = 'high_engagement' 
             then 1 else 0 end)                         as high_eng_sessions,
    round(avg(case when engagement_level = 'high_engagement' 
                   then 1.0 else 0 end) * 100, 2)       as high_eng_rate_pct
from {% raw %}{{ ref('stg_google_analytics__sessions') }}{% endraw %}
group by 1
order by high_eng_sessions desc
```
{% enddocs %}


{% docs traffic_channel_logic %}
## Traffic Channel Classification

Traffic sources are grouped into standardized channels for consistent reporting.

| traffic_source | traffic_channel |
|----------------|----------------|
| organic | organic_search |
| paid | paid_advertising |
| direct | direct_traffic |
| referral | referral_traffic |
| social | social_media |
| anything else | other |

**Note:** traffic_source is normalized to lowercase before classification,
so 'ORGANIC', 'Organic', and 'organic' all map to 'organic_search'.
{% enddocs %}