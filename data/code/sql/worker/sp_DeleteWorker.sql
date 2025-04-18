create or alter proc async.sp_DeleteWorker @worker NVARCHAR(255), @debug int
as begin
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
  
  declare @sql nvarchar(max)
  set @sql = 'drop proc if exists async.['+@newExecActivatedName+']'
  IF @debug > 0 SELECT @sql sp_ExecActivated ELSE EXEC (@sql)
  
  set @sql = 'drop proc if exists async.['+@newExecInvoke+']'
  IF @debug > 0 SELECT @sql ExecInvoke ELSE EXEC (@sql)
  
  set @sql = 'drop proc if exists async.['+@newDocflowApplyMethodAsync+']'
  IF @debug > 0 SELECT @sql sp_DocflowApplyMethodAsync ELSE EXEC (@sql)
  
  set @sql = 'drop proc if exists async.['+@newDocflowApplyMethodByGuidAsync+']'
  IF @debug > 0 SELECT @sql sp_DocflowApplyMethodByGuidAsync ELSE EXEC (@sql)
  
  set @sql = 'drop service '+@newServiceName
  if exists (select 1 from sys.services s where s.name = @newServiceName)
    IF @debug > 0 SELECT @sql Service ELSE EXEC (@sql)
  
  set @sql = 'drop queue async.'+@newExecQueueName
  if exists (select 1 from sys.service_queues where  schema_id = SCHEMA_ID('async') and name = @newExecQueueName)
    IF @debug > 0 SELECT @sql ExecQueue ELSE EXEC (@sql)
  end
GO

/* Test
declare @worker NVARCHAR(255), @debug int
select @worker = 't1', @debug = 0
exec async.sp_DeleteWorker @worker = @worker, @debug = @debug
--*/