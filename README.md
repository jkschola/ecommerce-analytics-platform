# E-Commerce Analytics Platform

[![dbt](https://img.shields.io/badge/dbt-1.7.4-orange.svg)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-ready-blue.svg)](https://www.snowflake.com/)

**A production-grade analytics engineering project demonstrating modern data stack best practices**

## 🎯 Project Goals

Build a multi-source e-commerce analytics platform covering the complete Analytics Engineering workflow:
- ✅ Medallion architecture (staging → intermediate → marts)
- ✅ Comprehensive data quality framework
- ✅ CI/CD automation
- ✅ Production-ready documentation

## 📊 Architecture
```
Sources (Shopify, GA, Facebook Ads)
    ↓
Staging Layer (standardization) ← 📍 Day 1 Complete
    ↓
Intermediate Layer (business logic)
    ↓
Marts Layer (analytics-ready)
```

## 🏗️ Current Status

**Day 1 Complete:** Foundation & Infrastructure ✅

### Data Pipeline
| Layer | Models | Tests | Status |
|-------|--------|-------|--------|
| Sources | 4 tables | 20+ | ✅ Configured |
| Staging | 1/8 models | 10 | ✅ In Progress |
| Intermediate | 0 models | 0 | 📅 Day 3-4 |
| Marts | 0 models | 0 | 📅 Day 4-5 |

### Infrastructure
- ✅ Snowflake environment (2 databases, 5 schemas)
- ✅ dbt project (dev/prod targets)
- ✅ 116,500 synthetic records loaded
- ✅ Git workflow with protected main branch
- ✅ PR template and documentation

## 📈 Data Sources

| Source | Table | Records | Grain |
|--------|-------|---------|-------|
| Shopify | customers | 5,000 | One per customer |
| Shopify | orders | 25,000 | One per order |
| Google Analytics | sessions | 50,000 | One per session |
| Facebook Ads | ad_performance | 36,500 | One per ad per day |

## 🚀 Quick Start
```bash
# Clone repository
git clone https://github.com/jkschola/ecommerce-analytics-platform.git
cd ecommerce-analytics-platform

# Set up Python environment
python3 -m venv venv        # On Windows: python -m venv venv
source venv/bin/activate    # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt

# Configure dbt (update ~/.dbt/profiles.yml with your Snowflake credentials)

# Install dbt packages
cd ecommerce_analytics
dbt deps

# Run models
dbt run --select staging

# Run tests
dbt test

# View documentation
dbt docs generate && dbt docs serve
```

## 📚 Tech Stack

| Component | Technology |
|-----------|-----------|
| Data Warehouse | Snowflake |
| Transformation | dbt Core 1.7.4 |
| Orchestration | GitHub Actions (coming) |
| Languages | SQL, Python |
| Version Control | Git/GitHub |
| Packages | dbt-utils, codegen |

## 📅 Development Roadmap

### ✅ Week 1: Foundation (Day 1-5)
- [x] **Day 1:** Environment setup, source configuration, first staging model
- [ ] **Day 2:** Complete staging layer (7 more models)
- [ ] **Day 3:** Intermediate models + macros
- [ ] **Day 4:** Marts layer (facts and dimensions)
- [ ] **Day 5:** Incremental models + snapshots

### 📅 Week 2: Quality & Governance (Day 6-10)
- [ ] **Day 6:** Advanced testing (custom tests, dbt-expectations)
- [ ] **Day 7:** Model contracts and versioning
- [ ] **Day 8:** CI/CD with GitHub Actions
- [ ] **Day 9:** Exposures and deployment workflow
- [ ] **Day 10:** Performance optimization + final polish

## 🎓 dbt Analytics Engineering Certification Coverage

This project covers all 8 certification topics:

- ✅ **Topic 1:** Developing dbt models
- 📅 **Topic 2:** Understanding dbt models governance
- 📅 **Topic 3:** Debugging data modeling errors
- 📅 **Topic 4:** Managing data pipelines
- ✅ **Topic 5:** Implementing dbt tests
- ✅ **Topic 6:** Creating and maintaining dbt documentation
- 📅 **Topic 7:** Implementing external dependencies
- 📅 **Topic 8:** Leveraging the dbt state

## 📊 Quality Metrics (Day 1)

| Metric | Value |
|--------|-------|
| Total tests | 30+ |
| Passing tests | 30 (100%) |
| Models with docs | 1/1 (100%) |
| Source freshness | Configured |

## 📝 Documentation

- [Snowflake Setup Guide](docs/snowflake_setup.md)
- [Day 1 Test Results](docs/stg_shopify__customers_test_results.md)
- [dbt Docs](http://localhost:8080) (run `dbt docs serve`)

## 🤝 Contributing

This is a portfolio project, but feedback is welcome! Please open an issue or PR.

## 📫 Contact

**Janvier S** - *Analytics Engineer*

LinkedIn: [https://www.linkedin.com/in/jkschola/]

Project Link: [https://github.com/jkschola/ecommerce-analytics-platform](https://github.com/jkschola/ecommerce-analytics-platform)

---

*Last updated: Day 1 Complete - February 8, 2026*