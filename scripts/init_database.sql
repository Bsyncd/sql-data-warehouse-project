/*
================================
Create Database and Schemas
================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists.
    IF the database exists, it is dropped and recreated.  The script sets up 3 schemas within the
    database:  'bronze', 'silver', 'gold'.

**WARNING:
    Running this script will drop the entire 'DataWarehouse' databasae if it exists.
    All data in the database will be permanently deleted.  Proceed with caution and
    make sure you have proper backups before running this script
*/

USE master; 
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO
  
-- Create Database for 'DataWarehouse'
-- switch to the master database, start creating databases here
CREATE DATABASE DataWarehouse;

-- switch to new database
USE DataWarehouse;

-- create schemas
CREATE SCHEMA bronze;
GO						-- GO is a separator to separate batches when working with multiple SQL statements
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
