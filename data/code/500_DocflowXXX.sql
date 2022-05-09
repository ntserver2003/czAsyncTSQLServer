/*
exec sp_DocFlowApplyMethod @DocumentID = 0
                          --,@MethodID = 0
--*/
GO
CREATE OR ALTER FUNCTION async.f_DocFlowApplyMethodResult_table (@taskId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
  RETURN SELECT er.*, IIF(RC < 0, 1, 0) IsDocFlowError
               ,dfel.Subject DocFlowErrorSubject
               ,dfel.Errortext DocFlowErrorText FROM (SELECT IIF(er.finish_time IS NULL, 0, 1) IsCompleted
                                                            ,IIF(er.error_message IS NOT NULL, 1, 0) IsError
                                                            ,er.error_number
                                                            ,er.error_message
                                                            ,TRY_CAST(er.result AS INT) RC FROM async.ExecResults er
      WHERE er.task_id = @taskId) er
  LEFT JOIN DocFlowErrorLog dfel ON -er.rc = dfel.ID
go

GRANT SELECT, REFERENCES ON async.f_DocFlowApplyMethodResult_table TO [MACROBANK WORKGROUP]
go

CREATE OR ALTER FUNCTION async.fn_DocFlowApplyMethodParams (@DocumentId INT, @MethodId INT, @LockWaitMs INT = NULL, @Next NVARCHAR(MAX) = NULL)
RETURNS NVARCHAR(MAX)
AS
BEGIN
  RETURN (SELECT *
                ,JSON_QUERY(IIF(ISJSON(@Next) = 1, @Next, '{}')) Next FROM (VALUES (@DocumentId, @MethodId, @LockWaitMs)) foo (DocumentId, MethodId, LockWaitMs)
      FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
END;
go
GRANT EXECUTE, REFERENCES ON async.fn_DocFlowApplyMethodParams TO [MACROBANK WORKGROUP]
go

CREATE OR ALTER FUNCTION async.f_DocFlowApplyMethodParams_table (@json NVARCHAR(MAX))
RETURNS TABLE
  RETURN SELECT DocumentId
               ,MethodId
               ,LockWaitMs
               ,Next FROM OPENJSON(IIF(ISJSON(@json) = 1, @json, NULL)) WITH (DocumentId INT, MethodId INT, LockWaitMs INT, Next NVARCHAR(MAX) AS JSON)
go
GRANT SELECT, REFERENCES ON async.f_DocFlowApplyMethodParams_table TO [MACROBANK WORKGROUP]
go

CREATE OR ALTER PROC async.sp_DocflowApplyMethodInvoke @asyncCallerTask UNIQUEIDENTIFIER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @__ErrMsg nvarchar(4000), @__ErrPrefix NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + N'.' + OBJECT_NAME(@@PROCID), N'<Dynamic code>') + N': ';
  
  DECLARE @rc INT
         ,@DocumentID INT
         ,@MethodID INT
         ,@LockWaitMs INT
         ,@Next NVARCHAR(MAX);
--  WAITFOR DELAY '00:01:10'
  SELECT @DocumentID = p.DocumentId
        ,@MethodID = p.MethodId
        ,@LockWaitMs = p.LockWaitMs
        ,@Next = p.Next FROM async.ExecResults er
    CROSS APPLY async.f_DocFlowApplyMethodParams_table(er.extra_info) p
    WHERE er.queued_id = @asyncCallerTask
  IF (@DocumentID IS NULL OR @MethodID IS NULL)
    BEGIN
      SET @__ErrMsg = @__ErrPrefix + FORMATMESSAGE(N'Parameters error. @DocumentID=%d, @MethodID=%d, @asyncCallerTask=%s', @DocumentID, @MethodID, CAST(@asyncCallerTask AS NVARCHAR(64)));
      THROW 51000, @__ErrMsg, 1;
    END
  -- begin transaction with savepoint
  BEGIN TRY
  DECLARE @TransactionID NVARCHAR(64) = ISNULL(OBJECT_NAME(@@PROCID), '<Dynamic code>' + CONVERT(NVARCHAR(64), NEWID()));
  DECLARE @TranCount INT = @@trancount;
  
    IF @TranCount > 0
      SAVE TRANSACTION @TransactionID;
    ELSE BEGIN
      BEGIN TRANSACTION @TransactionID;
    END;
    
    IF @LockWaitMs > 0
      EXEC lib.spg_GetLock @DocumentID = @DocumentID, @waitMs = @LockWaitMs
  
    EXEC @rc = dbo.sp_DocflowApplyMethod @DocumentID = @DocumentID
                                        ,@MethodID = @MethodID;

    IF @TranCount = 0
      COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
  -- debug    SET @ErrMsg = 'XACT_STATE() =' + STR(XACT_STATE()) + ', @TranCount=' + STR(@TranCount) + ', @@trancount=' + STR(@@trancount);
  -- debug    exec sys.sp_trace_generateevent 82, @ErrMsg;
      -- XACT_STATE = 1, @TranCount > 0 - не мы начинали транзакцию, надо вернуться на Savepoint
      IF XACT_STATE() = 1 AND @TranCount > 0
        ROLLBACK TRANSACTION @TransactionID;
      /* Мы начали транзакцию и она есть - откатываем*/
      ELSE IF @TranCount = 0 AND @@trancount > 0
        BEGIN TRY
          ROLLBACK TRANSACTION;
        END TRY BEGIN CATCH
        END CATCH;
      -- XACT_STATE = -1 - все плохо, но не мы начали.
    THROW;
  END CATCH;
  -- end transaction with savepoint
  UPDATE async.ExecResults SET result = FORMATMESSAGE('%d', @rc)
    WHERE queued_id = @asyncCallerTask;
END
  GO

GRANT EXECUTE, REFERENCES ON async.sp_DocflowApplyMethodInvoke TO [MACROBANK WORKGROUP]
GO

CREATE OR ALTER PROC async.sp_DocflowApplyMethodAsync @DocumentId INT, @MethodId INT, @LockWaitMs INT = NULL, @execGroup BIT = NULL, @groupId UNIQUEIDENTIFIER = NULL OUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @sql NVARCHAR(MAX), @context nvarchar(max);  
  SET @sql = 'exec async.sp_DocflowApplyMethodInvoke @asyncCallerTask=''##asyncCallerTask##'''
  SET @context = async.fn_DocFlowApplyMethodParams(@DocumentId, @MethodId, @LockWaitMs, DEFAULT);

  DECLARE @taskId UNIQUEIDENTIFIER;
  EXEC async.sp_ExecInvoke @sentence = @sql
                          ,@extra_info = @context
                          ,@execGroup = @execGroup
                          ,@group_id = @groupId OUT
                          ,@task_id = @taskId OUT
  UPDATE async.ExecResults SET DocumentId = @DocumentId, MethodId = @MethodId WHERE task_id = @taskId;
END
  GO

GRANT EXECUTE, REFERENCES ON async.sp_DocflowApplyMethodAsync TO [MACROBANK WORKGROUP]
GO


/*
DECLARE @groupId UNIQUEIDENTIFIER;
EXEC async.sp_DocflowApplyMethodAsync @DocumentId = 1765192
                                ,@MethodId = 618
--                                ,@LockWaitMs = 30000
--                                ,@execGroup = 1
                                ,@groupId = @groupId out
/*
EXEC async.sp_DocflowApplyMethodAsync @DocumentId = 1765192
                                ,@MethodId = 618
                                ,@groupId = @groupId out
*/
select r.*,er.* from async.ExecResults er
cross apply async.f_DocFlowApplyMethodResult_table(er.task_id) r
where er.group_id = @groupId

waitfor delay '00:00:02'
select r.*,er.* from async.ExecResults er
cross apply async.f_DocFlowApplyMethodResult_table(er.task_id) r
where er.group_id = @groupId
-- */
/*
select d.DocPathFolderID from documents d where d.id  = 1765192
select * from DocPathMethods dpm where dpm.SourceFolderID = 286
*/
/*
select top 2 f.*, er.* from async.ExecResults er--where queued_id = 'cebfe3a4-6cff-468d-b152-fa6d71a44226'
outer apply async.f_DocFlowApplyMethodResult_table(task_id) f
order BY submit_time desc
--*/
/*
select top 10 * from DocFlowErrorLog dfe order by id desc
exec async.sp_DocflowApplyMethodInvoke @asyncCallerTask='57e2ce44-7d2b-48fa-bde5-1f0811c2a5b2'
*/
