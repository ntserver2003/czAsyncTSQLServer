DECLARE @_groupId UNIQUEIDENTIFIER;
EXEC async.sp_DocflowApplyMethodAsync @DocumentId = 1765192 
                                ,@MethodId = 618
                                ,@LockWaitMs = 30000
                                ,@execGroup = 0
                                ,@groupId = @_groupId out

EXEC async.sp_DocflowApplyMethodAsync @DocumentId = 1765192 
                                ,@MethodId = 618
                                ,@LockWaitMs = 30000
                                ,@groupId = @_groupId out

declare @r int
exec @r = async.sp_Await @groupId = @_groupId
                        ,@maxWaitMs = 0 -- ждем вечно
IF @r = 1
  -- выполнилось
  SELECT r.* FROM Async.ExecResults er
    CROSS APPLY Async.f_DocFlowApplyMethodResult_table(er.task_id) r
    WHERE er.group_id = @_groupId
ELSE
  -- не выполнилось...
  SELECT 'not executed'
