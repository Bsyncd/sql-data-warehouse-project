/*
==========================================================================
Quality Checks
==========================================================================
Script Purpose:
  These perform various quality checks for data consistency, accuracy,
  and standardization across the 'silver' layer schemas.  They include
  checks for:
    - Null or duplicate primary keys
    - Unwanted spaces in string fields
    - Data standardization and consistency
    - Invalid date ranges and orders
    - Data consistency between related fields

Usage Notes:
  - Run these checks after loading the data into the Silver layer.
  - Investigate and resolve any discrepancies found during the checks.
===========================================================================
*/


/* CHECKING CRM TABLES */

-- ========================================================================
-- Checking 'silver.crm_cust_info'
-- ========================================================================
-- Done after cleaning the data for the silver layer, re checking for 
-- data quality

-- MAIN QUERY OF ALL DATA
SELECT * FROM silver.crm_cust_info;

	-- 1A: DATA EXPLORATION
SELECT 
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

		-- 2A:  Check for unwanted spaces in cells with string values
		-- Expectation: No Result
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname); 

-- lastname
SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname); 

-- marital status, none found
SELECT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status); 

-- gender, none found
SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr); 


		-- 2B:  Check for data standardization and consistency with marital status and gender columns
		-- Expectation: No Result

-- marital status
SELECT DISTINCT cst_marital_status -- only 3 possible values
FROM silver.crm_cust_info;

-- gender
SELECT DISTINCT cst_gndr -- only 3 possible values
FROM silver.crm_cust_info;


-- ========================================================================
-- Checking 'silver.crm_prd_info'
-- ========================================================================
-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces in product name column
-- Expectation: No Result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm); -- none found

-- Check for NULLs or negative numbers in product cost column
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;
	-- no negatives but we have nulls, so we can replace with '0' if business allows
	-- use ISNULL function to replace NULLs with '0'



-- Data Standardization and Consistency in prd_line column
SELECT DISTINCT prd_line
FROM silver.crm_prd_info; -- returns NULL, M, R, S, T / these need to be replaced with a value
-- Ask staff for proper names

-- ==============Check for Invalid Start and End order dates for the last two columns=================
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;
-- the end date should NOT be earlier than the start but this is found here so we need to fix these columns
-- go get some exapmles, take it to Excel, anf figure out how to fix it
-- there shouldn't be any overlapping of years either
-- some records don't have a start which is bad because all orders need a start date
-- however, it's okay for records not to have end dates because this means it's the current data

/*MAIN SOLUTION: (discuss with business experts)
	- use only the start dates, remove the end dates
	- rebuild the end dates, derive the end dates from the start dates
		-- the rule is that the end date equals the start date of the NEXT record
		-- this means take the start date of the next record and make it the end date of the current record
		then subtract 1 (day) so that it is smaller than 
		-- for the last record, it can stay NULL

	For the prd_end_dt < prd_start_dt issue, 
		focus on the columns that we need then use one or two scenarios
		to build the logic.  Once this is ready, we'll go and integrate it
		into the query*/
-- Here's the test scenario to work with
/*SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS prd_end_dt_test
	-- LEAD() - access values from the next row within a window / take this line to the main query
FROM silver.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')*/

-- FINAL CHECK OF ENTIRE SILVER TABLE
SELECT * FROM silver.crm_prd_info;


-- ========================================================================
-- Checking 'silver.crm_sales_details'
-- ========================================================================
-- ========================== COLUMN CHECKS ============================ --
-- WHEN DOING THE FINAL CHECK AFTER INSERTING THE TABLE, THE TABLE CHANGES FROM BRONZE TO SILVER

-- WHERE sls_ord_num != TRIM(sls_ord_num) -- checking for extra spaces, none found

-- WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
-- WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)
/*2 queries above checking integrity of the data in these columns in both tables, to make sure
they can be linked properly, no issues found */

/* -- If the date comes in as an integer and we need to change it to a date
SELECT
    NULLIF(sls_order_dt,0) sls_order_dt -- replace 0's with NULLs
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 
    OR LEN(sls_order_dt) != 8 
    OR sls_order_dt > 20500101
    OR sls_order_dt < 19000101
-- if the number doesnt equal or less than 0
-- if the date doesn't equal 8 numbers (YYYY-MM-DD), incase there are weird numbers
-- none found
If issues were found, then the following would be in the query to change integers to dates:
    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt
*/

-- Order date must always be earlier than the shipping date or due date
-- Checking for invalid date orders
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt -- order date should be smaller/earlier than ship date
    OR sls_order_dt > sls_due_dt -- order date should be earlier than due date
    -- OR sls_ship_dt > sls_due_dt -- if shipped on time, ship date should be earlier than due date, won't work if it was due earlier but shipped late
-- none found

-- BUSINESS RULES for sales, quantity, and price columns:
    -- Total Sales = Quantity * Price
    -- Negatives, Zeros, and NULLs are Not Allowed
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;
/* issues exist, so next we talk to an expert and discuss with them, they may fix it in the source system
OR they'll fix it in the data warehouse, they must make the decision not you

- In this case, if Sales is negative, zero, or null, derive it using Quantity and Price
- If Price is zero or null calculate the Price using Sales and Quantity
- If Price is negative, convert it to a positive value 

Now we'll rewrite the check query with the transformations*/

SELECT DISTINCT
    sls_sales AS old_sls_sales, -- org sales column with issues
    sls_quantity, -- fine, leave as is
    sls_price AS old_sls_price, -- org price column with issues
    
    CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price) -- converts negative prices to positive
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales, -- new recalculated sls_sales column

    CASE WHEN sls_price IS NULL OR sls_price <=0 -- if the price is NULL or 0
            THEN sls_sales / NULLIF(sls_quantity, 0) -- make NULL if quantity comes in as 0, so we don't divide by 0
        ELSE sls_price
    END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

/*FINAL FINAL CHECK OF THE WHOLE TABLE*/

SELECT
*
FROM silver.crm_sales_details;


/* CHECKING ERP TABLES */

-- ========================================================================
-- Checking 'silver.erp_cust_az12'
-- ========================================================================
-- =============== FIRST FIELD CHECK, 'CID' COLUMN  ====================

-- this shows that our transformation is working and the data in both tables in this field match
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)

--WHERE cid LIKE '%AW00011000%'

SELECT * FROM
silver.crm_cust_info;

-- we can connect these two with the cst_key field in both tables
-- not all of the cids have NAS, so we need to remove them


-- ===================== SECOND FIELD CHECK, 'BDATE' COLUMN  ==========================
-- Check for OUT OF RANGE dates
-- checking for a bdate that may be too old or in the future (person not born)
-- out of range dates were found so we need to fix it,  any dates in the future become NULLs

SELECT DISTINCT
	bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE() 
-- we didn't change the old dates, just the ones in the future so this is fine

-- ===================== THIRD FIELD CHECK, 'GEN' COLUMN  ==========================
-- DATA STANDARDIZATION & CONSISTENCY CHECK
-- shows if any gender data is other than Male or Female
-- other data is returned, we need to fix

SELECT DISTINCT 
	gen
FROM silver.erp_cust_az12; 
-- now only Male, Female, and N/A are returned

-- FINAL CHECK OF WHOLE TABLE
SELECT * FROM silver.erp_cust_az12;



-- ========================================================================
-- Checking 'silver.erp_loc_a101'
-- ========================================================================
-- =============== FIRST: CHECK AND FIX CID COLUMN ===============
-- erp's 'cid' column connects to crm's cst_key column, so we need to get the data to match
SELECT cst_key FROM silver.crm_cust_info; -- you'll see there was a dash in the bronze table, so we need to remove it

-- Double check here, if NO matching data is returned (table is blank) then the transformation works
SELECT
	REPLACE(cid, '-', '') cid,
	cntry
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN
	(SELECT cst_key FROM silver.crm_cust_info);


-- =============== SECOND: CHECK, FIX CNTRY COLUMN ===================
-- Check for country name standardization and consistency
-- Initial check
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101 -- quality is bad, several different names for a country

-- create the transformation then check, compare the new with old 'cntry'
SELECT DISTINCT cntry AS old_cntry,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
		ELSE TRIM(cntry)
	END cntry
FROM bronze.erp_loc_a101;


----============= AFTER DATA FIXED and LOADED: FINAL COLUMN CHECKS ===============
-- cid column
SELECT cid FROM silver.erp_loc_a101
WHERE cid NOT IN
	(SELECT cst_key FROM silver.crm_cust_info);
-- table returned empty, means data in this column match in both tables

-- cntry column
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;
-- should see all updates, data is now corrected

----============= FINAL TABLE CHECK ====================
SELECT * FROM silver.erp_loc_a101;



-- ========================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ========================================================================
-- LINKS WITH crm_prd_info table by prd_key

--======================== FIRST CHECK ID COLUMN ==========================
-- trim for extra spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE id != TRIM(id)
-- nothing else needed, column returns clean/empty
-- cat_id column in crm_prd_info table links to id column here

--======================= SECOND CHECK CAT COLUMN =========================
-- trim for extra spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
-- column returns clean/empty

-- Data Standardization check
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2
-- nothing strange, all returned with unique standarized names

--======================== THIRD CHECK SUBCAT COLUMN
-- trim for extra spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat)
-- column returns clean/empty

-- Data Standardization check
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2
-- nothing strange, all returned with unique standarized names

--======================== FOURTH CHECK MAINTENANCE COLUMN
-- trim for extra spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance)
-- column returns clean/empty

-- Data Standardization check
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2
-- nothing strange, all returned with unique standarized names

-- ============= AFTER DATA LOAD, FINAL CHECKS
--- DATA IS CLEAN!

-- ============= FINAL TABLE CHECK
SELECT * FROM silver.erp_px_cat_g1v2;
