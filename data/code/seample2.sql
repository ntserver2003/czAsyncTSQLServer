--/*
begin tran
exec lib.spg_GetLock 1765192
--*/
/*
declare @groupId UNIQUEIDENTIFIER;
set @groupId = newid()
set @groupId = 'e12cf7d7-13ae-48e0-81b0-5a43ad45f3c9'
declare @r int
exec @r = async.sp_Await @groupId
select @r
select * from async.ExecResults
*/
select f.*, er.* from async.ExecResults er
outer apply async.f_DocFlowApplyMethodResult_table(er.task_id) f
 order by submit_time desc
