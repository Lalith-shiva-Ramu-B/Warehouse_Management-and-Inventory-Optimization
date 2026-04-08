# Warehouse & Logistics Inventory Analysis (SQL)

## Project Overview
This project focuses on optimizing warehouse operations for a logistics provider. I developed a suite of SQL views to monitor inventory health, identify stockout risks, and calculate operational costs.

## Business Problems Addressed
* **Stockout Risk:** Identifying items where lead time exceeds stock availability.
* **Cost Optimization:** Calculating holding and handling costs to identify "money-traps."
* **Demand Forecasting:** Analyzing the gap between current stock levels and 7-day forecasted demand.

## Key Features
- **Buffer Risk Analysis:** Calculated "Buffer Days" to predict exactly which items will run out before the next restock arrives.
- **Operational Costing:** Integrated daily holding costs with monthly order volumes to find total operational overhead per item.
- **Zonal Distribution:** Aggregated stock levels by warehouse zones to identify regional supply-demand gaps.

## Tools Used
- **Database:** MySQL
- **Concepts:** CTEs, Window Functions, Date Manipulation, View Creation, Aggregations.
