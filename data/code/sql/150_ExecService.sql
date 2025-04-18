if not exists (select 1 from sys.services where name = 'AsyncExecService')
  CREATE SERVICE [AsyncExecService]  ON QUEUE [async].[ExecQueue] ([DEFAULT])
