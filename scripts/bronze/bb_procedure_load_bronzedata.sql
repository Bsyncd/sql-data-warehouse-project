/*
===========================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===========================================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    -  Truncates the bronze tables before loading data.
    -  Uses the 'Bulk Insert' command to load data from csv Files to the bronze tables.

Parameters:
    None.
    This stored procedudre does not accept any parameters nor return any values.

Usage Example
    EXEC bronze.load_bronze;
===========================================================================================
*/

EXEC bronze.load_bronze;

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; -- Declare variables to store the start and end time of the procedure execution
	BEGIN TRY
		SET @batch_start_time = GETDATE(); 
		PRINT '============================================================';
		PRINT 'Loading the Bronze Layer';
		PRINT '============================================================';

		PRINT '----------------------------';
		PRINT 'Loading the CRM Tables';
		PRINT '----------------------------';

		SET @start_time = GETDATE(); -- Get the current date and time when starting the loading process
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info; -- Clear the table before loading new data
		PRINT '>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\color\Desktop\SQL W_BARAA\WAREHOUSE_PROJECT\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, -- Skip the header row, we already have the information,
			FIELDTERMINATOR = ',', -- The fields are separated by commas
			TABLOCK -- This option allows the bulk insert operation to acquire a bulk update lock on the table, which can improve performance when inserting large amounts of data. It also allows the operation to bypass certain logging and locking mechanisms, which can further enhance performance. However, it should be used with caution, as it can lead to blocking and other issues if not used properly.
		);
		SET @end_time = GETDATE(); -- Get the date and time after the loading process is complete
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; -- Calculate and print the duration of the loading process in seconds 
		PRINT '>> ----------------------------------------------------';

		/*SELECT * FROM bronze.crm_cust_info;-- Testing the quality of the loaded table
		 /*Make sure you have data and that it is the correct data in the column*/
		SELECT COUNT(*) FROM bronze.crm_cust_info; -- There will always be one less row because of the column headers
-----------------------------------------------------------------------------------------------	*/	

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info; 

		PRINT '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\color\Desktop\SQL W_BARAA\WAREHOUSE_PROJECT\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';
		
		/*SELECT * FROM bronze.crm_prd_info;
		SELECT COUNT(*) FROM bronze.crm_prd_info;*/
-----------------------------------------------------------------------------------------------
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
	
		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\color\Desktop\SQL W_BARAA\WAREHOUSE_PROJECT\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK
			--MAXERRORS = 1000,  -- Allow more errors to see pattern
			--ERRORFILE = 'C:\Users\color\Desktop\sales_errors2.txt'
		  -- Log bad rows here
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		/*SELECT * FROM bronze.crm_sales_details;
		SELECT COUNT(*) FROM bronze.crm_sales_details;*/
------------------------------------------------------------------------------------------------

		SET @start_time = GETDATE();
		PRINT'----------------------------';
		PRINT 'Loading the ERP Tables';
		PRINT'----------------------------';

		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
	
		PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\color\Desktop\SQL W_BARAA\WAREHOUSE_PROJECT\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		/*SELECT * FROM bronze.erp_cust_az12;
		SELECT COUNT(*) FROM bronze.erp_cust_az12;
---------------------------------------------------------------------------------*/

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101; 

		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\color\Desktop\SQL W_BARAA\WAREHOUSE_PROJECT\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';
		
		/*SELECT * FROM bronze.erp_loc_a101;
		SELECT COUNT(*) FROM bronze.erp_loc_a101;
---------------------------------------------------------------------------------*/

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2; 

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\color\Desktop\SQL W_BARAA\WAREHOUSE_PROJECT\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'; 
		PRINT '>> ----------------------------------------------------';

		SELECT * FROM bronze.erp_px_cat_g1v2;
		SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;
	
	SET @batch_end_time = GETDATE();
		PRINT '============================================================';
		PRINT 'Bronze Layer loading is Complete';
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
