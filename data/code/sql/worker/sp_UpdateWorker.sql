/*
data\code\sql\worker\sp_UpdateWorker.sql
*/
CREATE OR ALTER PROC async.sp_UpdateWorker @worker NVARCHAR(255), @maxReaders INT, @debug INT
AS
BEGIN
  DECLARE @ExecQueueName NVARCHAR(128)
  SELECT @ExecQueueName = ExecQueue FROM async.f_ObjectNames_table(@worker)
  DECLARE @sql NVARCHAR(max)
  SELECT @sql = FORMATMESSAGE('ALTER QUEUE async.%s WITH ACTIVATION(MAX_QUEUE_READERS = %d)', @ExecQueueName, @maxReaders)
      IF @debug > 0
     SELECT @sql ExecQueue
    ELSE
     EXEC (@sql)
END
GO
/* Test
exec async.sp_UpdateWorker @worker = 't1', @maxReaders = 18, @debug = 0
select * from sys.service_queues where name = 'ExecQueue_t1'
--*/