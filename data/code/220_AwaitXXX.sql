--region update description

CREATE OR ALTER PROCEDURE #sp_updateFuncDesc @object_name NVARCHAR(256), @description NVARCHAR(4000)
, @jsonParameters NVARCHAR(MAX) = NULL
AS
BEGIN
  DECLARE @type VARCHAR(128) = 'FUNCTION'
  DECLARE @schema SYSNAME
         ,@object SYSNAME;
  SET @schema = PARSENAME(@object_name, 2)
  SET @object = PARSENAME(@object_name, 1)

  BEGIN TRY
    EXEC sys.sp_dropextendedproperty @level0name = @schema
                                    ,@level1name = @object
                                    ,@level0type = N'SCHEMA'
                                    ,@level1type = @type
                                    ,@name = N'MS_Description'
  END TRY BEGIN CATCH
  END CATCH

  EXEC sys.sp_addextendedproperty @level0name = @schema
                                 ,@level1name = @object
                                 ,@value = @description
                                 ,@level0type = N'SCHEMA'
                                 ,@level1type = @type
                                 ,@name = N'MS_Description'

  DECLARE @sql NVARCHAR(MAX);
  SELECT @sql = STRING_AGG(
    FORMATMESSAGE('exec #sp_updateFuncParamDesc @object_name = ''%s'', @parameter=''%s'', @description=''%s''', @object_name, p.param
    , REPLACE(p.Description, '''', '''''')), CHAR(13) + CHAR(10)) FROM OPENJSON(@jsonParameters) l
    OUTER APPLY (SELECT [key] param
                       ,value description FROM OPENJSON(l.value)) p
  IF @sql IS NOT NULL
    EXEC (@sql)
END
  GO

CREATE OR ALTER PROCEDURE #sp_updateFuncParamDesc @object_name NVARCHAR(256), @parameter NVARCHAR(128), @description NVARCHAR(4000)
AS
BEGIN
  DECLARE @type VARCHAR(128) = 'FUNCTION'

  DECLARE @schema SYSNAME
         ,@object SYSNAME;
  SET @schema = PARSENAME(@object_name, 2)
  SET @object = PARSENAME(@object_name, 1)
  BEGIN TRY
    EXEC sys.sp_dropextendedproperty @level0name = @schema
                                    ,@level1name = @object
                                    ,@level2name = @parameter
                                    ,@level0type = N'SCHEMA'
                                    ,@level1type = @type
                                    ,@level2type = N'PARAMETER'
                                    ,@name = N'MS_Description'
  END TRY BEGIN CATCH
  END CATCH

  EXEC sys.sp_addextendedproperty @level0name = @schema
                                 ,@level1name = @object
                                 ,@level2name = @parameter
                                 ,@value = @description
                                 ,@level0type = N'SCHEMA'
                                 ,@level1type = @type
                                 ,@level2type = N'PARAMETER'
                                 ,@name = N'MS_Description'

END
  GO

CREATE OR ALTER PROCEDURE #sp_updateProcDesc @object_name NVARCHAR(256), @description NVARCHAR(4000)
, @jsonParameters NVARCHAR(MAX) = NULL
AS
BEGIN
  DECLARE @type VARCHAR(128) = 'PROCEDURE'
  DECLARE @schema SYSNAME
         ,@object SYSNAME;
  SET @schema = PARSENAME(@object_name, 2)
  SET @object = PARSENAME(@object_name, 1)

  BEGIN TRY
    EXEC sys.sp_dropextendedproperty @level0name = @schema
                                    ,@level1name = @object
                                    ,@level0type = N'SCHEMA'
                                    ,@level1type = @type
                                    ,@name = N'MS_Description'
  END TRY BEGIN CATCH
  END CATCH

  EXEC sys.sp_addextendedproperty @level0name = @schema
                                 ,@level1name = @object
                                 ,@value = @description
                                 ,@level0type = N'SCHEMA'
                                 ,@level1type = @type
                                 ,@name = N'MS_Description'

  DECLARE @sql NVARCHAR(MAX);
  SELECT @sql = STRING_AGG(
    FORMATMESSAGE('exec #sp_updateProcParamDesc @object_name = ''%s'', @parameter=''%s'', @description=''%s''', @object_name, p.param
    , REPLACE(p.Description, '''', '''''')), CHAR(13) + CHAR(10)) FROM OPENJSON(@jsonParameters) l
    OUTER APPLY (SELECT [key] param
                       ,value description FROM OPENJSON(l.value)) p
  IF @sql IS NOT NULL
    EXEC (@sql)
END
  GO

CREATE OR ALTER PROCEDURE #sp_updateProcParamDesc @object_name NVARCHAR(256), @parameter NVARCHAR(128), @description NVARCHAR(4000)
AS
BEGIN
  DECLARE @type VARCHAR(128) = 'PROCEDURE'

  DECLARE @schema SYSNAME
         ,@object SYSNAME;
  SET @schema = PARSENAME(@object_name, 2)
  SET @object = PARSENAME(@object_name, 1)
  BEGIN TRY
    EXEC sys.sp_dropextendedproperty @level0name = @schema
                                    ,@level1name = @object
                                    ,@level2name = @parameter
                                    ,@level0type = N'SCHEMA'
                                    ,@level1type = @type
                                    ,@level2type = N'PARAMETER'
                                    ,@name = N'MS_Description'
  END TRY BEGIN CATCH
  END CATCH

  EXEC sys.sp_addextendedproperty @level0name = @schema
                                 ,@level1name = @object
                                 ,@level2name = @parameter
                                 ,@value = @description
                                 ,@level0type = N'SCHEMA'
                                 ,@level1type = @type
                                 ,@level2type = N'PARAMETER'
                                 ,@name = N'MS_Description'

END
  GO
--endregion update description

CREATE OR ALTER PROCEDURE async.sp_Await (@groupId UNIQUEIDENTIFIER, @maxWaitMs INT = 5000)
AS
BEGIN
  DECLARE @__ErrMsg NVARCHAR(4000)
         ,@__ErrPrefix NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@procid) + N'.' + OBJECT_NAME(@@procid), N'<Dynamic code>') + N': ';
  DECLARE @delayMs INT = 30
         ,@__waitDelay DATETIME;


  -- Если задания нет вообще - падаем с ошибкой
  IF NOT EXISTS (SELECT 1 FROM async.ExecResults er WHERE er.group_id = @groupId)
    BEGIN
      SET @__ErrMsg = @__ErrPrefix + FORMATMESSAGE(N'Task id "%s" not found', CAST(@groupId as NVARCHAR(64)));
      THROW 51000, @__ErrMsg, 1;
    END;

  IF @maxWaitMs < 0
    SET @maxWaitMs = 100;
  DECLARE @endTime DATETIME;

  -- Ждем вечно
  IF @maxWaitMs = 0
    SET @endTime = DATEADD(YEAR, 100, GETDATE())
  -- Ждем указанное время
  ELSE SET @endTime = DATEADD(MILLISECOND, @maxWaitMs, GETDATE())

  WHILE 1 = 1
  BEGIN
    -- все выполнено
    IF NOT EXISTS (SELECT 1 FROM async.ExecResults er
          WHERE er.group_id = @groupId
                AND er.finish_time IS NULL)
      RETURN 1

    -- Проверим время
    IF GETDATE() > @endTime
      RETURN 0 -- не дождались

    -- ждем
    SET @__waitDelay = DATEADD(MILLISECOND, @delayMs, '19010101 00:00:00.000')
    WAITFOR DELAY @__waitDelay
  END
END;
GO
EXEC #sp_updateProcDesc @object_name = '[Async].[sp_Await]'
                       ,@description = N'Wait for Async SQL.

Returns: 1 - complete, 0 - incomplete

Exception: Group Id not found
-----------------------------------
'
,@jsonParameters = '[
{"@groupId":"Group id of tasks"},
{"@maxWaitMs":"Wait for tasks complete in ms. 0 - infinit, default: 5000ms"}
]'

GO
GRANT EXECUTE, REFERENCES ON async.sp_Await TO [MACROBANK WORKGROUP]
GO
