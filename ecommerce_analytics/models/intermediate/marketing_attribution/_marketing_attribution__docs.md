{% docs marketing_traffic_channels %}
## Traffic Channel Taxonomy

Standardized channel groupings from Google Analytics sessions:

| Channel | Source Values | Typical Volume | Business Purpose |
|---------|--------------|----------------|------------------|
| organic_search | 'organic' | 40-50% | SEO performance |
| {% raw %}{{ var('paid_channel_name') }}{% endraw %} | 'paid' | 15-25% | Paid media ROI |
| direct_traffic | 'direct' | 15-20% | Brand strength |
| referral_traffic | 'referral' | 5-10% | Partnership value |
| social_media | 'social' | 5-10% | Community engagement |
| other | all others | <5% | Catch-all |

**Data Source:** stg_google_analytics__sessions.traffic_channel

**Validation:** Accepted values tested in staging layer.

**Usage in this model:** Pass-through dimension for slicing aggregated metrics.
{% enddocs %}


{% docs ga_total_sessions %}
## Total Sessions (Google Analytics)

Count of website sessions aggregated to daily channel level.

**Grain:** One session = one continuous period of user activity ending after 30 minutes of inactivity or at midnight (UTC).

**Source calculation:**
```sql
count(*) as total_sessions
from {% raw %}{{ ref('stg_google_analytics__sessions') }}{% endraw %}
group by cast(session_date as date), traffic_channel
```

**Business meaning:** Volume metric for top-of-funnel analysis.

**Typical ranges:**
- Organic search: 500-2,000 sessions/day
- Paid advertising: 200-800 sessions/day
- Direct: 300-600 sessions/day
{% enddocs %}


{% docs ga_bounce_rate %}
## Bounce Rate

Percentage of single-page sessions (visitor left without viewing a second page).

**Formula:** `bounced_sessions / NULLIF(total_sessions, 0)`
*(Note: Safe division is implemented at the database level to prevent pipeline crashes on zero-traffic days).*

**Range:** 0.0 to 1.0 (multiply by 100 for percentage display)

**Typical benchmarks:**
- E-commerce: 20-45%
- Blog: 65-90%
- Landing page: 70-90%

**High bounce rate signals:**
- Poor page relevance or slow load times
- Mismatched ad copy
  *(Note: A high bounce rate coupled with a high conversion rate often indicates a highly effective, single-action landing page).*

{% enddocs %}


{% docs fb_total_spend %}
## Total Ad Spend (Facebook Ads)

Sum of daily advertising spend in EUR, aggregated across all ads.

**Grain:** All ads rolled up to daily level, then LEFT JOINED to session data by date + channel.

**Source calculation:**
```sql
sum(spend) as total_spend
from {% raw %}{{ ref('stg_facebook_ads__ad_performance') }}{% endraw %}
group by performance_date
```

**NULL handling:** NULL for all non-paid channels (organic, direct, etc.).
This is intentional - only the `{% raw %}{{ var('paid_channel_name') }}{% endraw %}` channel receives blended spend.

**Data quality monitoring:** See singular test `assert_ad_spend_matches_staging.sql`, 
which actively validates that no ad spend is dropped in the event of upstream Google Analytics tracking outages.

{% enddocs %}