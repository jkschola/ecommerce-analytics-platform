
# Day 1 Test Results

## stg_shopify__customers

**Run timestamp:** 2026-02-08 09:50:00  
**Environment:** DBT_DEV

### Model Build
```
1 of 1 START sql view model DBT_DEV_staging.stg_shopify__customers ............. [RUN]
1 of 1 OK created sql view model DBT_DEV_staging.stg_shopify__customers ........ [SUCCESS 1 in 1.49s]
```

### Tests Executed

| Test | Status | Runtime |
|------|--------|---------|
| unique_stg_shopify__customers_customer_id | ✅ PASS
| not_null_stg_shopify__customers_customer_id | ✅ PASS 
| not_null_stg_shopify__customers_customer_email | ✅ PASS 
| not_null_stg_shopify__customers_first_name | ✅ PASS 
| not_null_stg_shopify__customers_last_name | ✅ PASS 
| not_null_stg_shopify__customers_full_name | ✅ PASS 
| unique_stg_shopify__customers_customer_unique_key | ✅ PASS 
| not_null_stg_shopify__customers_customer_unique_key | ✅ PASS 
| accepted_values_stg_shopify__customers_customer_country | ✅ PASS 
| not_null_stg_shopify__customers_customer_country | ✅ PASS 

**Total:** 10 data tests, 10 passed, 0 failures

### Data Validation
```sql
SELECT 
    COUNT(*) as total_customers,
    COUNT(DISTINCT customer_id) as unique_ids,
    COUNT(DISTINCT customer_unique_key) as unique_keys,
    COUNT(DISTINCT customer_country) as unique_countries
FROM STG_SHOPIFY__CUSTOMERS;
```

**Results:**
- Total customers: 5,000
- Unique customer_ids: 5,000
- Unique surrogate keys: 5,000
- Unique countries: 8

✅ All validations passed