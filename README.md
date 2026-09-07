# Olist E-commerce Business Analytics

An end-to-end data analytics project examining sales, delivery performance, customer activity, seller concentration, product categories, and customer satisfaction in the Brazilian Olist marketplace.

The project combines **Python**, **MySQL**, and **Power BI** to transform raw marketplace data into validated analytical datasets, reproducible analysis, and an interactive five-page dashboard.

## Project Objectives

This project explores the following questions:

* How much order and payment activity was recorded?
* How effectively were orders completed and delivered?
* How did sales and delivery performance change over time?
* Where were customers and sellers geographically concentrated?
* How common were repeat purchases?
* Which product categories and sellers generated the highest observed value?
* How were delivery performance and customer review scores associated?
* How frequently did delivered orders receive low review scores?

## Dataset

The project uses the public **Brazilian E-commerce Public Dataset by Olist**, covering marketplace activity from 2016 to 2018.

The original data contains approximately:

* 99,441 orders
* 96,096 unique customers
* 112,650 order-item records
* 32,951 products with orders
* 3,095 sellers
* Payment, review, product, customer, seller, and geolocation data

Currency values are expressed in Brazilian reais (**R$**).

## Tools and Technologies

* **Python:** pandas, NumPy, Matplotlib and Jupyter Notebook
* **MySQL:** relational tables, typed views, joins, CTEs and window functions
* **Power BI:** data modeling, DAX measures, slicers and interactive reporting
* **Git and Git LFS:** version control and large-file management

## Analytical Workflow

1. Audited raw CSV files, schemas, missing values and duplicates.
2. Validated primary keys and relationships between datasets.
3. Converted timestamps and numeric fields to appropriate data types.
4. Created data-quality flags for delivery, payment and review analysis.
5. Removed exact geolocation duplicates.
6. Built cleaned and integrated analytical datasets.
7. Performed exploratory and business-focused analysis in Python.
8. Created MySQL tables, analytical views and reusable SQL queries.
9. Built a relational Power BI model with a dedicated date table.
10. Developed a five-page interactive dashboard.

## Data-Quality Decisions

Important data-quality rules include:

* Removed **261,831 exact duplicate geolocation records**.
* Retained orders with incomplete lifecycle information for status analysis.
* Excluded invalid or unavailable timestamps from delivery-duration metrics.
* Replaced four non-positive product weights with missing values.
* Retained rating-only reviews instead of treating missing comments as missing reviews.
* Defined a low review as a latest valid review score of **1 or 2**.
* Calculated the late-delivery rate only from delivered orders with valid delivery metrics.
* Treated observed customer value as historical recorded value, not predicted customer lifetime value.

## Key Metrics

| Metric                  |   Result |
| ----------------------- | -------: |
| Total Orders            |   99,441 |
| Delivered Orders        |   96,478 |
| Order Completion Rate   |   97.02% |
| Delivered Payment Value | R$15.42M |
| Unique Customers        |   96,096 |
| Total Sellers           |    3,095 |
| Average Order Value     | R$159.85 |
| Late Delivery Rate      |    6.78% |
| Average Review Score    |     4.16 |
| Low Review Rate         |   12.81% |

## Key Findings

### Sales and Delivery

* Delivered orders represented **97.02%** of recorded orders.
* Delivered payment value totaled approximately **R$15.42 million**.
* Average delivered-order value was approximately **R$159.85**.
* Among delivered orders with valid delivery information, **6.78%** were late.
* Monthly trends are presented through August 2018 to avoid interpreting incomplete later periods as normal monthly performance.

### Customers

* The dataset contains **96,096 unique customers**.
* **2,997 customers**, or **3.12%**, placed more than one order.
* São Paulo had the largest customer concentration, with **40,296 customers**.
* Customer recency groups use October 18, 2018 as the historical reference date.

### Sellers and Products

* The marketplace contained **3,095 sellers** and **32,951 products with orders**.
* São Paulo accounted for **1,849 sellers**, indicating substantial geographic concentration.
* Health and beauty produced the highest observed product value, followed closely by watches and gifts.
* Seller rankings are based on recorded order-item value and do not represent profitability.

### Reviews and Satisfaction

* Delivered orders with valid reviews had an average score of **4.16 out of 5**.
* **12,273 reviewed delivered orders** received a latest score of 1 or 2.
* The resulting low-review rate was **12.81%**.
* **56,749 orders** received a score of 5, representing approximately **59.2%** of reviewed delivered orders.
* On-time deliveries averaged **4.29**, compared with **2.27** for late deliveries.

The review comparison describes a historical association and does not establish that delivery timing alone caused the difference in review scores.

## Power BI Dashboard

The Power BI report contains five interactive analytical pages. It uses a relational data model, a dedicated date table, reusable DAX measures, page navigation, date filtering and customer-state filtering.

### 1. Executive Overview

Summarizes order volume, delivered payment value, customers, completion rate, review performance, monthly payment trends and the leading customer states.

![Executive Overview](images/executive-overview.png)

### 2. Sales & Delivery

Examines delivered payment value, order volume, average order value, late-delivery incidence and on-time delivery performance.

![Sales and Delivery](images/sales-delivery.png)

### 3. Customer Analysis

Explores geographic distribution, repeat purchasing, customer mix, average customer activity and historical recency groups.

![Customer Analysis](images/customer-analysis.png)

### 4. Seller & Product Performance

Compares seller concentration, product-category value, seller locations, order-item activity, freight value and leading sellers.

![Seller and Product Performance](images/seller-product-performance.png)

### 5. Reviews & Satisfaction

Analyzes review-score distribution, low-review incidence, monthly low-review trends and delivery-related review patterns.

![Reviews and Satisfaction](images/reviews-satisfaction.png)

The Power BI report is available here:

[Open the Power BI report](power-bi/Olist_Ecommerce_Analytics_Dashboard.pbix)

## Repository Structure

```text
olist-ecommerce-business-analytics/
├── data/
│   ├── raw/
│   └── processed/
├── notebooks/
├── sql/
├── power-bi/
│   └── Olist_Ecommerce_Analytics_Dashboard.pbix
├── images/
├── README.md
└── .gitattributes
```

* `data/raw/` contains the original Olist CSV files.
* `data/processed/` contains cleaned or integrated analytical outputs.
* `notebooks/` contains the numbered Python analysis notebooks.
* `sql/` contains database setup, analytical views, validation and business queries.
* `power-bi/` contains the interactive Power BI report.
* `images/` contains dashboard screenshots used in this README.

## Reproducing the Project

1. Clone the repository:

```bash
git clone https://github.com/ImmoBre/olist-ecommerce-business-analytics.git
```

2. Enter the project directory:

```bash
cd olist-ecommerce-business-analytics
```

3. Download files managed through Git LFS:

```bash
git lfs install
git lfs pull
```

4. Run the Python notebooks in numerical order.

5. Execute the MySQL scripts in their documented order.

6. Open the `.pbix` file in Power BI Desktop to explore the interactive report.

## Limitations

* The dataset represents historical marketplace activity and does not describe current Olist performance.
* Customer value measures represent observed historical transactions, not predicted lifetime value.
* Repeat-purchase and recency measures should not be interpreted as confirmed customer churn.
* Review and delivery comparisons are descriptive and do not establish causality.
* Forecasting and predictive-model notebooks are analytical exercises rather than production forecasts or deployed decision systems.
* Missing lifecycle timestamps, review text and product attributes limit some analyses.

## Author

**Saad Maher**
Data Analyst Portfolio Project

[GitHub Profile](https://github.com/ImmoBre)
