# Snowflake Environment Setup

## Architecture Overview
```
ECOMMERCE_RAW (Database)
├── SHOPIFY (Schema)
├── GOOGLE_ANALYTICS (Schema)
└── FACEBOOK_ADS (Schema)

ECOMMERCE_ANALYTICS (Database)
├── DBT_DEV (Schema) - Development workspace
└── DBT_PROD (Schema) - Production deployment target
```

## Resources Created

| Resource Type | Name | Purpose |
|--------------|------|---------|
| Role | ANALYTICS_ENGINEER | Permissions for dbt development |
| Warehouse | ANALYTICS_WH | Compute for transformations |
| Database | ECOMMERCE_RAW | Raw source data storage |
| Database | ECOMMERCE_ANALYTICS | Transformed dbt models |
| Schema | ECOMMERCE_RAW.SHOPIFY | Shopify raw tables |
| Schema | ECOMMERCE_RAW.GOOGLE_ANALYTICS | GA raw tables |
| Schema | ECOMMERCE_RAW.FACEBOOK_ADS | Facebook Ads raw tables |
| Schema | ECOMMERCE_ANALYTICS.DBT_DEV | dbt dev models |
| Schema | ECOMMERCE_ANALYTICS.DBT_PROD | dbt prod models |

## Cost Optimization

- **Auto-suspend:** Warehouse suspends after 60 seconds of inactivity
- **Auto-resume:** Warehouse resumes automatically when queries run
- **Size:** XSMALL (cheapest option, suitable for this project)
- **Estimated cost:** ~$2-5 for entire project (within free trial credits)

## Setup Instructions

1. Log into Snowflake web UI
2. Open a new Worksheet
3. Run `scripts/snowflake_setup.sql`
4. Verify all objects created successfully

## Verification Queries
```sql
-- Check your current context
SELECT 
    CURRENT_ROLE(),
    CURRENT_WAREHOUSE(),
    CURRENT_DATABASE(),
    CURRENT_SCHEMA();

-- Should return:
-- ANALYTICS_ENGINEER | ANALYTICS_WH | ECOMMERCE_ANALYTICS | DBT_DEV

-- List all schemas in raw database
SHOW SCHEMAS IN DATABASE ECOMMERCE_RAW;

-- Verify permissions
SHOW GRANTS TO ROLE ANALYTICS_ENGINEER;
```

## Troubleshooting

**Issue:** "Insufficient privileges to operate on database"
**Solution:** Make sure you're using ACCOUNTADMIN role when running setup script

**Issue:** "Warehouse not found"
**Solution:** Check warehouse name is spelled correctly: ANALYTICS_WH

**Issue:** "Cannot create schema - database does not exist"
**Solution:** Ensure databases are created before schemas
