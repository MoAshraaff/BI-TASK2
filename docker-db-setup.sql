-- One-time setup: creates a SQL Server login scoped to MO_ASHRAF only, for
-- the Docker api container to use (it can't do Windows Integrated auth from
-- inside a Linux container). Run this once against your local SQL Server
-- instance, passing the same password you put in .env's DB_PASSWORD, e.g.:
--
--   sqlcmd -S localhost -E -v DbPassword="<value of DB_PASSWORD in .env>" -i docker-db-setup.sql

USE master;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'bi_task2_docker')
BEGIN
    DECLARE @sql nvarchar(max) = N'CREATE LOGIN bi_task2_docker WITH PASSWORD = ''' + REPLACE('$(DbPassword)', '''', '''''') + N''', CHECK_POLICY = ON;';
    EXEC (@sql);
END
GO

USE MO_ASHRAF;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'bi_task2_docker')
BEGIN
    CREATE USER bi_task2_docker FOR LOGIN bi_task2_docker;
    ALTER ROLE db_owner ADD MEMBER bi_task2_docker;
END
GO
