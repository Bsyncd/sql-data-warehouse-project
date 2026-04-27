/*
================================================================================
Stored Proceudre: Load Silver Layer (Bronze -> Silver)
================================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' layer tables from the 'bronze' layer.

Actions:
    - Truncate the Silver layer tables.
    - Insert transformed and cleansed data from the Bronze layer tables to the
      Silver layer tables

Parameters:
    None.
    This stored procedure does not accept any parameterss or return any values.

Usage Example
    EXEC Silver.load_silver;
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '============================================================';
		PRINT 'Loading the Silver Layer';
		PRINT '============================================================';

		PRINT '----------------------------';
		PRINT 'Loading the CRM Tables';
		PRINT '----------------------------';
		
		-- CRM: Customer Info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info'; 	
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info'; 
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)
		SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname, -- trims spaces for names
		TRIM(cst_lastname) AS cst_lastname, -- trims spaces for names
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' -- M becomes Married, catches lowercase, trims spaces
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' -- S becomes Single, catches lowercase, trims spaces
			ELSE 'Unknown'
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' -- F becomes Female, catches lowercase, trims spaces
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' -- M becomes Male, catches lowercase, trims spaces
			ELSE 'Unknown'
		END cst_gndr,
		cst_create_date
		FROM (
			SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
			FROM bronze.crm_cust_info
			-- WHERE cst_id = 29466 -- select duplicate id
		)t WHERE flag_last = 1 -- now we see the latest record (to check 'AND cst_id = 29466')
		SET @end_time = GETDATE(); 
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		-- CRM: Product Info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info'; 
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1,5), '-', '_') AS cat_id, -- Extract category ID
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extract Product ID
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost, -- Handles missing product costs by replacing NULLs with 0
			CASE UPPER(TRIM(prd_line)) 
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'Unknown'
			END AS prd_line, -- Map product line codes to descriptive values
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS prd_end_dt	-- Calculate the end date as one day before the next start date
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE(); 
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		-- CRM: Sales Details
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details'; 
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,	
			CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales, -- new recalculated sls_sales column
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <=0 -- if the price is NULL or 0
				THEN sls_sales / NULLIF(sls_quantity, 0) -- make NULL if quantity comes in as 0, so we don't divide by 0
				ELSE sls_price
			END AS sls_price
		 FROM [bronze].[crm_sales_details];
		SET @end_time = GETDATE(); 
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';


		SET @start_time = GETDATE();
		PRINT'----------------------------';
		PRINT 'Loading the ERP Tables';
		PRINT'----------------------------';
		-- ERM: Cust Az12
		PRINT '>> Truncating Table: silver.erp_cust_az12'; 
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
		SELECT
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- removes NAS, no matter the length of string (LEN)
				ELSE cid
			END cid,  -- handles invalid values

			CASE WHEN bdate > GETDATE() THEN NULL -- any future dates become NULLs
				ELSE bdate
			END bdate, -- handles invalid values

			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'	
				ELSE 'N/A'
			END gen
		FROM bronze.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		-- ERM: Loc A101
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101'; 
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
		SELECT
			REPLACE(cid, '-', '') cid,
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
				ELSE TRIM(cntry)
			END cntry
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		-- ERM: Px Cat G1V2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'; 
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2
		(id, cat, subcat, maintenance)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

	SET @batch_end_time = GETDATE();
		PRINT '============================================================';
		PRINT 'Silver Layer loading is Complete';
		PRINT '>> Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '============================================================';
	END TRY

	BEGIN CATCH
		PRINT '============================================================';
		PRINT 'Error Occurred While Loading the Bronze Layer';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_SEVERITY() AS NVARCHAR);
		PRINT '============================================================';
	END CATCH

END
