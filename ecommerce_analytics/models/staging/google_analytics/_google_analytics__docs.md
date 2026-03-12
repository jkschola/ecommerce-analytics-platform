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

**🚨 Configuration-Driven Logic:**
This taxonomy is dynamically driven by global variables. Do not rely on hardcoded SQL. 

Please refer to the `vars` section in `dbt_project.yml` for the exact, up-to-date mappings.
* **Output Channels:** Defined by `channel_*` variables (e.g., `channel_organic`).
* **Input UTM Mappings:** Defined by `source_mapping_*` lists (e.g., `source_mapping_organic`).

**Note:** `traffic_source` is normalized to lowercase before classification, so 'ORGANIC', 'Organic', and 'organic' all successfully map to the organic channel bucket.
{% enddocs %}