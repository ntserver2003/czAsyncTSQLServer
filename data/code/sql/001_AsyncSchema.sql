IF SCHEMA_ID('async') IS NULL
  EXEC sp_executesql N'CREATE SCHEMA async'
GO
