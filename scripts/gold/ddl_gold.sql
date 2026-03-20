/*
=================================================================================================
DDL script: Create Gold Views
=================================================================================================
Script Purpose:
    This script creates views for the Gold Layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
  - These views can be queried directly for analytics and reporting.
=================================================================================================
*/

-- ==============================================================================================
-- Create Dimension: gold.dim_customers
-- ==============================================================================================
IF OBJECT_ID('gold.dim_customers', 'v') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS
Select
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
		la.cntry as country,
	ci.cst_martial_status as martial_status,
	CASE WHEN ci.cst_gndr != 'n/a' then ci.cst_gndr
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date
From silver.crm_cust_info ci
Left Join silver.erp_cust_az12 ca
on ci.cst_key = ca.cid
Left Join silver.erp_loc_a101 la
on ci.cst_key = la.cid;

-- ==============================================================================================
-- Create Dimensions: gold.dim_products
-- ==============================================================================================
IF OBJECT_ID('gold.dim_products', 'v') IS NOT NULL
	DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
select 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null;-- filter out only a current data

-- ==============================================================================================
-- Create Dimensions:  gold.fact_sales
-- ==============================================================================================
IF OBJECT_ID('gold.fact_sales', 'v') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO
CREATE VIEW gold.fact_sales AS
SELECT 
sd.sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price price
from silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prod_key = pr.product_number
left join gold.dim_customers cu
on sd.sls_cust_id = cu.customer_id;
