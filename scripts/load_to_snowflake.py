# scripts/load_to_snowflake.py
"""
Load generated CSV data to Snowflake raw tables.

This script:
1. Creates raw tables in appropriate schemas
2. Loads CSV data using Snowflake's write_pandas
3. Validates record counts
4. Adds _loaded_at timestamps

Author: jkschola
Date: 2026-02-07
"""

import os
import pandas as pd
import numpy as np
from datetime import datetime
from dotenv import load_dotenv
from snowflake.connector import connect
from snowflake.connector.pandas_tools import write_pandas


# 1. Load the .env file
load_dotenv()

# 2. Use os.getenv to fetch variables safely
SNOWFLAKE_CONFIG = {
    'account': os.getenv('DBT_SNOWFLAKE_ACCOUNT'),
    'user': os.getenv('DBT_SNOWFLAKE_USER'),
    'password': os.getenv('DBT_SNOWFLAKE_PASSWORD'),
    'warehouse': os.getenv('DBT_SNOWFLAKE_WAREHOUSE', 'ANALYTICS_WH'),
    'role': os.getenv('DBT_SNOWFLAKE_ROLE', 'ANALYTICS_ENGINEER')
}

# 3. Simple validation to ensure secrets loaded
missing_keys = [k for k, v in SNOWFLAKE_CONFIG.items() if v is None]
if missing_keys:
    raise ValueError(f"Missing environment variables for: {', '.join(missing_keys)}")

print(f"✅ Connection parameters loaded for account: {SNOWFLAKE_CONFIG['account']}")

print("=" * 60)
print("LOADING DATA TO SNOWFLAKE")
print("=" * 60)

# Connect to Snowflake
print("\n🔌 Connecting to Snowflake...")
try:
    conn = connect(**SNOWFLAKE_CONFIG)
    cursor = conn.cursor()
    print("✅ Connected successfully")
except Exception as e:
    print(f"❌ Connection failed: {e}")
    exit(1)

# ============================================
# 1. LOAD SHOPIFY DATA
# ============================================
print("\n📦 Loading Shopify data...")

cursor.execute("USE DATABASE ECOMMERCE_RAW")
cursor.execute("USE SCHEMA SHOPIFY")
cursor.execute("USE WAREHOUSE ANALYTICS_WH")

# Create customers table
print("  → Creating customers table...")
cursor.execute("""
CREATE OR REPLACE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    country VARCHAR(100),
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Customer master data from Shopify'
""")

# Load customers data
df_customers = pd.read_csv('../data/raw/shopify_customers.csv')
df_customers.columns = [x.upper() for x in df_customers.columns]

# THE FIX: Convert to datetime64[ns] and remove timezone
for col in ['CREATED_AT', 'UPDATED_AT', '_LOADED_AT']:
    df_customers[col] = pd.to_datetime(df_customers[col]).dt.tz_localize(None).astype('datetime64[ns]')

success, nchunks, nrows, _ = write_pandas(
    conn, 
    df_customers, 
    'CUSTOMERS',
    database='ECOMMERCE_RAW',
    schema='SHOPIFY',
    auto_create_table=False,
    overwrite=True,
    use_logical_type=True  # CRITICAL: Forces Parquet to use Timestamp logic
)
print(f"  ✅ Loaded {nrows:,} customers")

# Create orders table
print("  → Creating orders table...")
cursor.execute("""
CREATE OR REPLACE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date TIMESTAMP_NTZ,
    total_amount DECIMAL(10,2),
    status VARCHAR(50),
    created_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
)
COMMENT = 'Order transactions from Shopify'
""")

# Load orders data
df_orders = pd.read_csv('../data/raw/shopify_orders.csv')
df_orders.columns = [x.upper() for x in df_orders.columns]
for col in ['ORDER_DATE', 'CREATED_AT', 'UPDATED_AT', '_LOADED_AT']:
    df_orders[col] = pd.to_datetime(df_orders[col]).dt.tz_localize(None).astype('datetime64[ns]')

success, nchunks, nrows, _ = write_pandas(
    conn,
    df_orders,
    'ORDERS',
    database='ECOMMERCE_RAW',
    schema='SHOPIFY',
    auto_create_table=False,
    overwrite=True,
    use_logical_type=True
)
print(f"  ✅ Loaded {nrows:,} orders")

# ============================================
# 2. LOAD GOOGLE ANALYTICS DATA
# ============================================
print("\n🌐 Loading Google Analytics data...")

cursor.execute("USE SCHEMA GOOGLE_ANALYTICS")

print("  → Creating sessions table...")
cursor.execute("""
CREATE OR REPLACE TABLE sessions (
    session_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    session_date TIMESTAMP_NTZ,
    page_views INTEGER,
    session_duration_seconds INTEGER,
    source VARCHAR(100),
    medium VARCHAR(100),
    campaign VARCHAR(200),
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Website session data from Google Analytics'
""")

df_sessions = pd.read_csv('../data/raw/google_analytics_sessions.csv')
df_sessions.columns = [x.upper() for x in df_sessions.columns]
df_sessions['SESSION_DATE'] = pd.to_datetime(df_sessions['SESSION_DATE']).dt.tz_localize(None).astype('datetime64[ns]')
df_sessions['_LOADED_AT'] = pd.to_datetime(df_sessions['_LOADED_AT']).dt.tz_localize(None).astype('datetime64[ns]')

success, nchunks, nrows, _ = write_pandas(
    conn,
    df_sessions,
    'SESSIONS',
    database='ECOMMERCE_RAW',
    schema='GOOGLE_ANALYTICS',
    auto_create_table=False,
    overwrite=True,
    use_logical_type=True
)
print(f"  ✅ Loaded {nrows:,} sessions")

# ============================================
# 3. LOAD FACEBOOK ADS DATA
# ============================================
print("\n📱 Loading Facebook Ads data...")

cursor.execute("USE SCHEMA FACEBOOK_ADS")

print("  → Creating ad_performance table...")
cursor.execute("""
CREATE OR REPLACE TABLE ad_performance (
    ad_id VARCHAR(50),
    date DATE,
    impressions INTEGER,
    clicks INTEGER,
    spend DECIMAL(10,2),
    conversions INTEGER,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ad_id, date)
)
COMMENT = 'Daily ad performance metrics from Facebook Ads'
""")

df_ads = pd.read_csv('../data/raw/facebook_ads_performance.csv')
df_ads.columns = [x.upper() for x in df_ads.columns]
df_ads['DATE'] = pd.to_datetime(df_ads['DATE']).dt.date
df_ads['_LOADED_AT'] = pd.to_datetime(df_ads['_LOADED_AT']).dt.tz_localize(None).astype('datetime64[ns]')

success, nchunks, nrows, _ = write_pandas(
    conn,
    df_ads,
    'AD_PERFORMANCE',
    database='ECOMMERCE_RAW',
    schema='FACEBOOK_ADS',
    auto_create_table=False,
    overwrite=True,
    use_logical_type=True
)
print(f"  ✅ Loaded {nrows:,} ad performance records")

# ============================================
# 4. VERIFICATION
# ============================================
print("\n🔍 Verifying data load...")

cursor.execute("SELECT COUNT(*) FROM ECOMMERCE_RAW.SHOPIFY.CUSTOMERS")
customers_count = cursor.fetchone()[0]
print(f"  Customers: {customers_count:,}")

cursor.execute("SELECT COUNT(*) FROM ECOMMERCE_RAW.SHOPIFY.ORDERS")
orders_count = cursor.fetchone()[0]
print(f"  Orders: {orders_count:,}")

cursor.execute("SELECT COUNT(*) FROM ECOMMERCE_RAW.GOOGLE_ANALYTICS.SESSIONS")
sessions_count = cursor.fetchone()[0]
print(f"  Sessions: {sessions_count:,}")

cursor.execute("SELECT COUNT(*) FROM ECOMMERCE_RAW.FACEBOOK_ADS.AD_PERFORMANCE")
ads_count = cursor.fetchone()[0]
print(f"  Ad Records: {ads_count:,}")

# Close connection
cursor.close()
conn.close()

print("\n" + "=" * 60)
print("✅ ALL DATA LOADED SUCCESSFULLY TO SNOWFLAKE")
print("=" * 60)