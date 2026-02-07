-- ============================================
-- SNOWFLAKE ENVIRONMENT SETUP
-- Project: E-Commerce Analytics Platform
-- Purpose: Create databases, schemas, roles, and warehouses
-- Author: jkschola
-- Date: 2025-02-07
-- ============================================

-- Use ACCOUNTADMIN for setup
USE ROLE ACCOUNTADMIN;

-- ============================================
-- 1. CREATE ROLE FOR ANALYTICS ENGINEERING
-- ============================================

CREATE ROLE IF NOT EXISTS ANALYTICS_ENGINEER
    COMMENT = 'Role for analytics engineering workflows';

-- Grant to your user (REPLACE WITH YOUR USERNAME)
GRANT ROLE ANALYTICS_ENGINEER TO USER <YOUR_SNOWFLAKE_USERNAME>;

-- ============================================
-- 2. CREATE COMPUTE WAREHOUSE
-- ============================================

CREATE WAREHOUSE IF NOT EXISTS ANALYTICS_WH
    WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60                    -- Suspend after 1 min of inactivity
    AUTO_RESUME = TRUE                   -- Resume automatically when needed
    INITIALLY_SUSPENDED = TRUE           -- Don't start running immediately
    COMMENT = 'Warehouse for dbt transformations and analytics';

-- Grant usage to analytics role
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE ANALYTICS_ENGINEER;
GRANT OPERATE ON WAREHOUSE ANALYTICS_WH TO ROLE ANALYTICS_ENGINEER;

-- ============================================
-- 3. CREATE RAW DATA DATABASE
-- ============================================

CREATE DATABASE IF NOT EXISTS ECOMMERCE_RAW
    COMMENT = 'Raw data ingested from source systems (Shopify, GA, Facebook Ads)';

GRANT USAGE ON DATABASE ECOMMERCE_RAW TO ROLE ANALYTICS_ENGINEER;
GRANT CREATE SCHEMA ON DATABASE ECOMMERCE_RAW TO ROLE ANALYTICS_ENGINEER;

-- Create schemas for each source system
USE DATABASE ECOMMERCE_RAW;

CREATE SCHEMA IF NOT EXISTS SHOPIFY
    COMMENT = 'Raw Shopify e-commerce platform data';

CREATE SCHEMA IF NOT EXISTS GOOGLE_ANALYTICS
    COMMENT = 'Raw Google Analytics web events data';

CREATE SCHEMA IF NOT EXISTS FACEBOOK_ADS
    COMMENT = 'Raw Facebook Ads campaign performance data';

-- Grant permissions on raw schemas
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA SHOPIFY TO ROLE ANALYTICS_ENGINEER;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA GOOGLE_ANALYTICS TO ROLE ANALYTICS_ENGINEER;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA FACEBOOK_ADS TO ROLE ANALYTICS_ENGINEER;

-- Grant SELECT on future tables (for when data is loaded)
GRANT SELECT ON FUTURE TABLES IN SCHEMA SHOPIFY TO ROLE ANALYTICS_ENGINEER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA GOOGLE_ANALYTICS TO ROLE ANALYTICS_ENGINEER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA FACEBOOK_ADS TO ROLE ANALYTICS_ENGINEER;

-- ============================================
-- 4. CREATE ANALYTICS DATABASE (for dbt)
-- ============================================

CREATE DATABASE IF NOT EXISTS ECOMMERCE_ANALYTICS
    COMMENT = 'Transformed analytics-ready data (dbt staging, intermediate, marts)';

GRANT USAGE ON DATABASE ECOMMERCE_ANALYTICS TO ROLE ANALYTICS_ENGINEER;
GRANT CREATE SCHEMA ON DATABASE ECOMMERCE_ANALYTICS TO ROLE ANALYTICS_ENGINEER;

-- Create development and production schemas
USE DATABASE ECOMMERCE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DBT_DEV
    COMMENT = 'Development environment for dbt models (your personal workspace)';

CREATE SCHEMA IF NOT EXISTS DBT_PROD
    COMMENT = 'Production environment for dbt models (deployed code)';

-- Grant full permissions on analytics schemas
GRANT ALL ON SCHEMA DBT_DEV TO ROLE ANALYTICS_ENGINEER;
GRANT ALL ON SCHEMA DBT_PROD TO ROLE ANALYTICS_ENGINEER;

-- Grant on future objects
GRANT SELECT ON FUTURE TABLES IN SCHEMA DBT_DEV TO ROLE ANALYTICS_ENGINEER;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA DBT_DEV TO ROLE ANALYTICS_ENGINEER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DBT_PROD TO ROLE ANALYTICS_ENGINEER;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA DBT_PROD TO ROLE ANALYTICS_ENGINEER;

-- ============================================
-- 5. VERIFICATION & SUMMARY
-- ============================================

-- Switch to the analytics role to verify setup
USE ROLE ANALYTICS_ENGINEER;
USE WAREHOUSE ANALYTICS_WH;
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA DBT_DEV;

-- Display current session context
SELECT 
    CURRENT_ROLE() AS current_role,
    CURRENT_WAREHOUSE() AS current_warehouse,
    CURRENT_DATABASE() AS current_database,
    CURRENT_SCHEMA() AS current_schema;

-- Show all databases accessible to this role
SHOW DATABASES;

-- Show all schemas in raw database
SHOW SCHEMAS IN DATABASE ECOMMERCE_RAW;

-- Show all schemas in analytics database
SHOW SCHEMAS IN DATABASE ECOMMERCE_ANALYTICS;

SELECT '✅ Snowflake environment setup complete!' AS status;

-- ============================================
-- CLEANUP COMMANDS (if you need to reset)
-- ============================================

-- CAUTION: Uncomment only if you want to completely reset

-- USE ROLE ACCOUNTADMIN;
-- DROP DATABASE IF EXISTS ECOMMERCE_RAW CASCADE;
-- DROP DATABASE IF EXISTS ECOMMERCE_ANALYTICS CASCADE;
-- DROP WAREHOUSE IF EXISTS ANALYTICS_WH;
-- DROP ROLE IF EXISTS ANALYTICS_ENGINEER;