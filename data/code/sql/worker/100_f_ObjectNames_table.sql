/*
data\code\sql\worker\100_f_ObjectNames_table.sql 
*/
CREATE OR ALTER FUNCTION async.f_ObjectNames_table (@worker NVARCHAR(128))
RETURNS TABLE
AS
  RETURN
  SELECT sp_ExecActivated
        ,ExecQueue
        ,AsyncExecService
        ,sp_ExecInvoke
        ,sp_DocflowApplyMethodAsync
        ,sp_DocflowApplyMethodByGuidAsync
        ,sp_DocflowApplyMethodInvoke
        --
        FROM (VALUES (
    --
    'sp_ExecActivated_' + @worker
    , 'ExecQueue_' + @worker
    , 'AsyncExecService_' + @worker
    , 'sp_ExecInvoke_' + @worker
    , 'sp_DocflowApplyMethodAsync_' + @worker
    , 'sp_DocflowApplyMethodByGuidAsync_' + @worker
    , 'sp_DocflowApplyMethodInvoke_' + @worker
    --
    )) foo (sp_ExecActivated, ExecQueue, AsyncExecService, sp_ExecInvoke, sp_DocflowApplyMethodAsync, sp_DocflowApplyMethodByGuidAsync, sp_DocflowApplyMethodInvoke)
GO
GRANT SELECT, REFERENCES ON async.f_ObjectNames_table TO [MACROBANK WORKGROUP]
GO
