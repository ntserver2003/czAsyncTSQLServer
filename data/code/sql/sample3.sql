/*
create table tempdb..samples_results (
ID INT IDENTITY  PRIMARY KEY
,example_name nvarchar(4000)
,value nvarchar(4000)
)
--*/
--/*
begin
DECLARE @group_id UNIQUEIDENTIFIER = NULL
       ,@task_id UNIQUEIDENTIFIER = NULL
begin tran
declare @sentence nvarchar(max)
EXEC [localhost].teslapay.Async.sp_ExecInvoke
         @sentence = 'insert into tempdb..samples_results (example_name, value) values (''Use case 1'', FORMATMESSAGE(''Executed. @@trancount: %d'', @@trancount))'
         ,@group_id = @group_id out
         ,@task_id = @task_id out
--*/
select @group_id group_id, @task_id task_id
select * from tempdb..samples_results
select * from async.ExecResults er
/*
truncate table tempdb..samples_results
truncate table async.ExecResults
-- */
--waitfor delay '00:00:05'
rollback tran
end

select * from tempdb..samples_results
select * from async.ExecResults er

