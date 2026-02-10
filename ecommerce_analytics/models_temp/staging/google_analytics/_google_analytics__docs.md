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
    count(*) as total_sessions,
    sum(case when engagement_level = 'high_engagement' then 1 else 0 end) as high_engagement_sessions,
    avg(case when engagement_level = 'high_engagement' then 1 else 0 end) as engagement_rate
from {{ ref('stg_google_analytics__sessions') }}
group by 1
```
{% enddocs %}