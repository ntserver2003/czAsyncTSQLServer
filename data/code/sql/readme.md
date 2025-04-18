## Workers

### Создать новый worker

Если QUEUE воркера уже существует, упадет с ошибкой

```sql
DECLARE @worker NVARCHAR(255), @maxReaders INT, @debug INT
SELECT @worker = 't1'  -- Суффикс воркера
     , @maxReaders = 8 -- кол-во reader'ов очереди
     , @debug = 0      -- режим отладки. Вместо исполнения выводится SQL

EXEC async.sp_CreateWorker @worker = @worker
                          ,@maxReaders = @maxReaders
                          ,@debug = @debug
```

### Удалить worker

```sql
DECLARE @worker NVARCHAR(255), @debug INT
SELECT @worker = 't1'  -- Суффикс воркера
     , @debug = 0      -- режим отладки. Вместо исполнения выводится SQL

EXEC async.sp_DeleteWorker @worker = @worker
                          ,@debug = @debug
```

## Service broker tips

Включить Service Broker на новой базе
```sql
USE [master]
GO
ALTER DATABASE [] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

ALTER DATABASE [] SET  ENABLE_BROKER WITH NO_WAIT
ALTER DATABASE [] SET MULTI_USER
GO
```

Если восстановили базу на тот же сервер, но с другим именем
```sql
USE [master]
GO
ALTER DATABASE [] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

ALTER DATABASE [] SET NEW_BROKER
ALTER DATABASE [] SET MULTI_USER
GO
