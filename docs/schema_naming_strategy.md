# dbt Schema Naming Strategy

## How dbt Names Schemas

dbt uses the pattern: `<target_schema>_<custom_schema>`

### Development Environment
- **Target schema:** `DBT_DEV` (from profiles.yml)
- **Models:**
  - Staging models → `DBT_DEV_STAGING`
  - Intermediate models → `DBT_DEV_INTERMEDIATE`
  - Core marts → `DBT_DEV_MARTS_CORE`
  - Marketing marts → `DBT_DEV_MARTS_MARKETING`
  - Finance marts → `DBT_DEV_MARTS_FINANCE`

### Production Environment
- **Target schema:** `DBT_PROD` (from profiles.yml)
- **Models:**
  - Staging models → `DBT_PROD_STAGING`
  - Intermediate models → `DBT_PROD_INTERMEDIATE`
  - Core marts → `DBT_PROD_MARTS_CORE`
  - Marketing marts → `DBT_PROD_MARTS_MARKETING`
  - Finance marts → `DBT_PROD_MARTS_FINANCE`

## Why This Approach?

### 1. **Layer Isolation**
Each layer (staging, intermediate, marts) has its own schema, making it easy to:
- Grant permissions by layer
- Apply different retention policies
- Monitor costs by layer

### 2. **Environment Separation**
Dev and prod models live in separate schemas:
```sql
-- Development
SELECT * FROM DBT_DEV_STAGING.STG_SHOPIFY__CUSTOMERS;

-- Production
SELECT * FROM DBT_PROD_STAGING.STG_SHOPIFY__CUSTOMERS;
```

### 3. **Clear Organization**
In Snowflake, you can immediately see which layer a schema belongs to:
```
ECOMMERCE_ANALYTICS
├── DBT_DEV_STAGING          ← Staging layer (dev)
├── DBT_DEV_MARTS_CORE       ← Core marts (dev)
├── DBT_PROD_STAGING         ← Staging layer (prod)
└── DBT_PROD_MARTS_CORE      ← Core marts (prod)
```

## How to Reference Models

### In dbt (use ref() - schemas handled automatically):
```sql
-- This works in both dev and prod
select * from {{ ref('stg_shopify__customers') }}

-- dbt resolves to correct schema based on target
-- Dev: DBT_DEV_STAGING.STG_SHOPIFY__CUSTOMERS
-- Prod: DBT_PROD_STAGING.STG_SHOPIFY__CUSTOMERS
```

### In External Tools (BI, Python):
Use environment variables:
```python
# Python
schema = "DBT_PROD_STAGING" if env == "prod" else "DBT_DEV_STAGING"
query = f"SELECT * FROM {schema}.STG_SHOPIFY__CUSTOMERS"
```

## Verification
```sql
-- Show all schemas in dev
SHOW SCHEMAS IN DATABASE ECOMMERCE_ANALYTICS LIKE 'DBT_DEV%';

-- Show all objects in staging schema
SHOW VIEWS IN SCHEMA DBT_DEV_STAGING;
```