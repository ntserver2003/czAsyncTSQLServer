CREATE OR ALTER PROC async.sp_CreateWorker @worker NVARCHAR(255), @maxReaders INT, @debug INT
AS
BEGIN
  DECLARE @__Line INT = -1, @__ErrMsg nvarchar(4000), @__ErrPrefix NVARCHAR(128);
  SELECT @__Line = -1, @__ErrPrefix = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + N'.' + OBJECT_NAME(@@PROCID), N'<Dynamic code>') + N': ';
  
  BEGIN TRY
    -- new object names
    declare @newExecActivatedName NVARCHAR(128), @newExecQueueName NVARCHAR(128), @newServiceName NVARCHAR(128), @newExecInvoke NVARCHAR(128)
           ,@newDocflowApplyMethodAsync NVARCHAR(128), @newDocflowApplyMethodByGuidAsync NVARCHAR(128)
  
    SELECT @newExecActivatedName = sp_ExecActivated
          ,@newExecQueueName = ExecQueue
          ,@newServiceName = AsyncExecService
          ,@newExecInvoke = ExecInvoke
          ,@newDocflowApplyMethodAsync = sp_DocflowApplyMethodAsync
          ,@newDocflowApplyMethodByGuidAsync = sp_DocflowApplyMethodByGuidAsync FROM (VALUES (
      --
      'sp_ExecActivated_' + @worker
      , 'ExecQueue_' + @worker
      , 'AsyncExecService_' + @worker
      , 'ExecInvoke_' + @worker
      , 'sp_DocflowApplyMethodAsync_' + @worker
      , 'sp_DocflowApplyMethodByGuidAsync_' + @worker
      --
      )) foo (sp_ExecActivated, ExecQueue, AsyncExecService, ExecInvoke, sp_DocflowApplyMethodAsync, sp_DocflowApplyMethodByGuidAsync)
    
    if exists (select 1 from sys.service_queues where  schema_id = SCHEMA_ID('async') and name = @newExecQueueName)
    begin
      SET @__ErrMsg = @__ErrPrefix + FORMATMESSAGE(N'Worker %s already exists', @worker);
      THROW 51000, @__ErrMsg, 1;
    end 
  
    declare @sql NVARCHAR(MAX)
    -- Worker sp_ExecActivated procedure
    SET @sql = OBJECT_DEFINITION(OBJECT_ID('async.sp_ExecActivated'))
    SET @sql = '/* Auto generated. Don''t change */' + CHAR(13) + REPLACE(@sql, 'sp_ExecActivated', @newExecActivatedName)
    SET @sql = REPLACE(@sql, '[ExecQueue]', '['+@newExecQueueName+']')
    IF @debug > 0
     SELECT @sql sp_ExecActivated
    ELSE
    BEGIN
     EXEC (@sql)
     SET @sql = FORMATMESSAGE('GRANT EXECUTE, REFERENCES ON async.%s TO [MACROBANK WORKGROUP]', @newExecActivatedName)
     EXEC (@sql)
    END
    
    -- Worker sp_ExecInvoke procedure
    SET @sql = OBJECT_DEFINITION(OBJECT_ID('async.sp_ExecInvoke'))
    SET @sql = '/* Auto generated. Don''t change */' + CHAR(13) + REPLACE(@sql, 'sp_ExecInvoke', @newExecInvoke)
    SET @sql = REPLACE(@sql, 'AsyncExecService', @newServiceName)
    SET @sql = REPLACE(@sql, '''default''', ''''+@worker+'''')
    IF @debug > 0
     SELECT @sql sp_ExecInvoke
    ELSE
      BEGIN
       EXEC (@sql)
       SET @sql = FORMATMESSAGE('GRANT EXECUTE, REFERENCES ON async.%s TO [MACROBANK WORKGROUP]', @newExecInvoke)
       EXEC (@sql)
      END

    -- Worker sp_DocflowApplyMethodAsync procedure
    SET @sql = OBJECT_DEFINITION(OBJECT_ID('async.sp_DocflowApplyMethodAsync'))
    SET @sql = '/* Auto generated. Don''t change */' + CHAR(13) + REPLACE(@sql, 'sp_DocflowApplyMethodAsync', @newDocflowApplyMethodAsync)
    SET @sql = REPLACE(@sql, 'sp_ExecInvoke', @newExecInvoke)
    IF @debug > 0
     SELECT @sql sp_DocflowApplyMethodAsync
    ELSE
      BEGIN
       EXEC (@sql)
       SET @sql = FORMATMESSAGE('GRANT EXECUTE, REFERENCES ON async.%s TO [MACROBANK WORKGROUP]', @newDocflowApplyMethodAsync)
       EXEC (@sql)
      END
  
    
    -- Worker sp_DocflowApplyMethodByGuidAsync procedure
    SET @sql = OBJECT_DEFINITION(OBJECT_ID('async.sp_DocflowApplyMethodByGuidAsync'))
    SET @sql = '/* Auto generated. Don''t change */' + CHAR(13) + REPLACE(@sql, 'sp_DocflowApplyMethodByGuidAsync', @newDocflowApplyMethodByGuidAsync)
    SET @sql = REPLACE(@sql, 'sp_DocflowApplyMethodAsync', @newDocflowApplyMethodAsync)
    IF @debug > 0
     SELECT @sql sp_DocflowApplyMethodByGuidAsync
    ELSE
      BEGIN
       EXEC (@sql)
       SET @sql = FORMATMESSAGE('GRANT EXECUTE, REFERENCES ON async.%s TO [MACROBANK WORKGROUP]', @newDocflowApplyMethodByGuidAsync)
       EXEC (@sql)
      END

    SELECT @sql = 'CREATE QUEUE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(@newExecQueueName) +
           CASE
               WHEN activation_procedure IS NOT NULL
                   THEN CHAR(13) + 'WITH STATUS = ' + CASE is_activation_enabled
                                                          WHEN 1 THEN 'ON,'
                                                          ELSE 'OFF,'
                   END + CHAR(13) +
                        'RETENTION = ' + CASE is_retention_enabled
                                             WHEN 1 THEN 'ON,'
                                             ELSE 'OFF,'
                            END + CHAR(13) +
                        'ACTIVATION (' + CHAR(13) +
                        '    STATUS = ON,' + CHAR(13) +
                        '    PROCEDURE_NAME = [async].[' + @newExecActivatedName + '],' + CHAR(13) +
                        '    MAX_QUEUE_READERS = ' + CAST(@maxReaders AS VARCHAR(3)) + ',' + CHAR(13) +
                        '    EXECUTE AS ' + CASE execute_as_principal_id
                                                WHEN NULL THEN 'SELF'
                                                WHEN -2 THEN 'OWNER'
                                                ELSE QUOTENAME(USER_NAME(execute_as_principal_id))
                            END + '),' + CHAR(13) +
                        'POISON_MESSAGE_HANDLING (STATUS = ON)'
               ELSE ''
               END + ';'
    -- select *
    FROM sys.service_queues
    WHERE is_ms_shipped = 0 and schema_id = SCHEMA_ID('async') and name = 'ExecQueue'; -- Exclude system queues
    IF @debug > 0
     SELECT @sql ExecQueue
    ELSE
     EXEC (@sql)
    
    set @sql = FORMATMESSAGE('CREATE SERVICE [%s]  ON QUEUE [async].[%s] ([DEFAULT])', @newServiceName, @newExecQueueName)
    IF @debug > 0
     SELECT @sql Service
    ELSE
     EXEC (@sql)
    
  END TRY
  BEGIN CATCH
    THROW
  END CATCH
END
GO

/* Test
DECLARE @worker NVARCHAR(255), @maxReaders INT, @debug INT
SELECT @worker = 't1', @maxReaders = 8, @debug = 0

EXEC async.sp_CreateWorker @worker = @worker
                          ,@maxReaders = @maxReaders
                          ,@debug = @debug
--*/