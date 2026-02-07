# scripts/generate_sample_data.py
"""
Generate realistic synthetic e-commerce data for analytics platform.

This script creates:
- 5,000 customers across 8 European countries
- 25,000 orders with realistic distributions
- 50,000 Google Analytics sessions
- 36,500 Facebook Ads performance records (50 ads x 730 days)

Data covers 2023-01-01 to 2024-12-31 (2 years).

Author: [Your Name]
Date: 2025-02-07
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
import sys

# Configuration
SEED = 42
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2024, 12, 31)
NUM_CUSTOMERS = 5000
NUM_ORDERS = 25000
NUM_SESSIONS = 50000
NUM_ADS = 50

# Set seeds for reproducibility
random.seed(SEED)
np.random.seed(SEED)
fake = Faker()
Faker.seed(SEED)

print("=" * 60)
print("E-COMMERCE DATA GENERATION")
print("=" * 60)
print(f"Date range: {START_DATE.date()} to {END_DATE.date()}")
print(f"Random seed: {SEED}")
print("=" * 60)

# ============================================
# 1. GENERATE CUSTOMERS
# ============================================
print("\n📊 Generating customers...")

customers = []
countries = ['France', 'Germany', 'Spain', 'Italy', 'Belgium', 
             'Netherlands', 'UK', 'Switzerland']
country_weights = [0.30, 0.20, 0.15, 0.12, 0.08, 0.07, 0.05, 0.03]

for i in range(1, NUM_CUSTOMERS + 1):
    created_at = fake.date_time_between(
        start_date=START_DATE, 
        end_date=END_DATE - timedelta(days=30)  # Ensure customers exist before most orders
    )
    
    customers.append({
        'customer_id': i,
        'email': fake.email(),
        'first_name': fake.first_name(),
        'last_name': fake.last_name(),
        'country': random.choices(countries, weights=country_weights)[0],
        'created_at': created_at,
        'updated_at': created_at + timedelta(days=random.randint(0, 10)),
        '_loaded_at': datetime.now()
    })

df_customers = pd.DataFrame(customers)
print(f"✅ Generated {len(df_customers):,} customers")
print(f"   Countries: {df_customers['country'].value_counts().to_dict()}")

# ============================================
# 2. GENERATE ORDERS
# ============================================
print("\n📦 Generating orders...")

orders = []
order_statuses = ['completed', 'completed', 'completed', 'completed',  # 57% completed
                  'pending', 'pending',  # 29% pending
                  'cancelled',  # 14% cancelled
                  'refunded']  # Small % refunded

for i in range(1, NUM_ORDERS + 1):
    # Select random customer
    customer = df_customers.sample(1).iloc[0]
    
    # Order date must be after customer creation
    order_date = fake.date_time_between(
        start_date=max(customer['created_at'], START_DATE),
        end_date=END_DATE
    )
    
    # Determine status
    status = random.choice(order_statuses)
    
    # Generate realistic order amounts using log-normal distribution
    # Mean ~€75, most orders €20-200, some up to €500
    base_amount = np.random.lognormal(mean=4.3, sigma=0.7)
    total_amount = round(max(10.0, min(base_amount, 500.0)), 2)
    
    # Refunded orders have negative amounts
    if status == 'refunded':
        total_amount = -total_amount
    
    orders.append({
        'order_id': i,
        'customer_id': customer['customer_id'],
        'order_date': order_date,
        'total_amount': total_amount,
        'status': status,
        'created_at': order_date,
        'updated_at': order_date + timedelta(hours=random.randint(0, 72)),
        '_loaded_at': datetime.now()
    })

df_orders = pd.DataFrame(orders)

print(f"✅ Generated {len(df_orders):,} orders")
print(f"   Status distribution:")
for status in df_orders['status'].unique():
    count = len(df_orders[df_orders['status'] == status])
    pct = count / len(df_orders) * 100
    print(f"     - {status}: {count:,} ({pct:.1f}%)")

completed_revenue = df_orders[df_orders['status'] == 'completed']['total_amount'].sum()
print(f"   Total completed revenue: €{completed_revenue:,.2f}")

# ============================================
# 3. GENERATE GOOGLE ANALYTICS SESSIONS
# ============================================
print("\n🌐 Generating Google Analytics sessions...")

sessions = []
traffic_sources = ['organic', 'organic', 'organic',  # 50% organic
                   'paid', 'paid',  # 33% paid
                   'direct',  # 11% direct
                   'referral',  # 5.5% referral
                   'social']  # 0.5% social

mediums = ['google', 'facebook', 'instagram', 'email', 'direct', 'referral', 'linkedin']
campaigns = [f'campaign_{i:02d}' for i in range(1, 21)]

for i in range(1, NUM_SESSIONS + 1):
    session_date = fake.date_time_between(start_date=START_DATE, end_date=END_DATE)
    source = random.choice(traffic_sources)
    
    # Page views follows power law (most sessions 1-3 pages, some up to 20)
    page_views = min(int(np.random.pareto(a=2.0) + 1), 20)
    
    # Session duration correlates with page views
    avg_time_per_page = random.randint(30, 120)
    session_duration = page_views * avg_time_per_page + random.randint(-20, 60)
    session_duration = max(10, session_duration)
    
    sessions.append({
        'session_id': f'session_{i}',
        'user_id': f'user_{random.randint(1, NUM_CUSTOMERS * 2)}',  # Some non-customers
        'session_date': session_date,
        'page_views': page_views,
        'session_duration_seconds': session_duration,
        'source': source,
        'medium': random.choice(mediums),
        'campaign': random.choice(campaigns) if source == 'paid' else None,
        '_loaded_at': datetime.now()
    })

df_sessions = pd.DataFrame(sessions)
print(f"✅ Generated {len(df_sessions):,} sessions")
print(f"   Source distribution:")
for source in df_sessions['source'].value_counts().head().items():
    print(f"     - {source[0]}: {source[1]:,}")

# ============================================
# 4. GENERATE FACEBOOK ADS PERFORMANCE
# ============================================
print("\n📱 Generating Facebook Ads performance data...")

ads_performance = []

# Generate daily performance for each ad
for ad_id in range(1, NUM_ADS + 1):
    current_date = START_DATE
    
    while current_date <= END_DATE:
        # Realistic ad metrics with some randomness
        impressions = random.randint(500, 15000)
        
        # CTR between 1-5%
        ctr = random.uniform(0.01, 0.05)
        clicks = int(impressions * ctr)
        
        # Conversion rate between 2-10%
        conversion_rate = random.uniform(0.02, 0.10)
        conversions = int(clicks * conversion_rate)
        
        # Spend varies by day and ad
        spend = round(random.uniform(20, 300), 2)
        
        ads_performance.append({
            'ad_id': f'ad_{ad_id:03d}',
            'date': current_date.date(),
            'impressions': impressions,
            'clicks': clicks,
            'spend': spend,
            'conversions': conversions,
            '_loaded_at': datetime.now()
        })
        
        current_date += timedelta(days=1)

df_ads = pd.DataFrame(ads_performance)
print(f"✅ Generated {len(df_ads):,} ad performance records")
print(f"   Total spend: €{df_ads['spend'].sum():,.2f}")
print(f"   Total conversions: {df_ads['conversions'].sum():,}")

# ============================================
# 5. SAVE TO CSV
# ============================================
print("\n💾 Saving data to CSV files...")

output_dir = '../data/raw'

df_customers.to_csv(f'{output_dir}/shopify_customers.csv', index=False)
print(f"   ✅ {output_dir}/shopify_customers.csv")

df_orders.to_csv(f'{output_dir}/shopify_orders.csv', index=False)
print(f"   ✅ {output_dir}/shopify_orders.csv")

df_sessions.to_csv(f'{output_dir}/google_analytics_sessions.csv', index=False)
print(f"   ✅ {output_dir}/google_analytics_sessions.csv")

df_ads.to_csv(f'{output_dir}/facebook_ads_performance.csv', index=False)
print(f"   ✅ {output_dir}/facebook_ads_performance.csv")

# ============================================
# 6. GENERATE SUMMARY STATISTICS
# ============================================
print("\n" + "=" * 60)
print("📈 DATA GENERATION SUMMARY")
print("=" * 60)
print(f"Customers:        {len(df_customers):>10,}")
print(f"Orders:           {len(df_orders):>10,}")
print(f"GA Sessions:      {len(df_sessions):>10,}")
print(f"Ad Records:       {len(df_ads):>10,}")
print("-" * 60)
print(f"Total Records:    {len(df_customers) + len(df_orders) + len(df_sessions) + len(df_ads):>10,}")
print("=" * 60)
print("✅ Data generation complete!")
print("=" * 60)