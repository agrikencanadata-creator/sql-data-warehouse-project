/*
===================================================
Create Database and Schemas
===================================================
Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it already exists.
  If the database exists, it is  dropped and recreated.
  Additionally, the script sets up 3 schemas within the database: 'bronze', 'silver', and 'gold'.

Warning:
Running this script will drop the entire 'DataWarehouse' database if it already exists.
All data in the database will be permanently deleted. 
Process with caution and ensure you have proper backups before running this script.
*/
