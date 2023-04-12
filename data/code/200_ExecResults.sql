declare @objectId INT;
SET @objectId = object_id('async.ExecResults');
if @objectId IS NULL BEGIN
  CREATE TABLE async.ExecResults (
      submit_time   DATETIME2
          CONSTRAINT DF_JsAsyncExecResults_submit_time DEFAULT SYSUTCDATETIME() NOT NULL,
      task_id       UNIQUEIDENTIFIER                                            NOT NULL,
      group_id      UNIQUEIDENTIFIER,
      queued_time   DATETIME2,
      queued_id     UNIQUEIDENTIFIER,
      sentence      NVARCHAR(MAX),
      extra_info    NVARCHAR(MAX),
      start_time    DATETIME2,
      finish_time   DATETIME2,
      error_number  INT,
      error_message NVARCHAR(MAX),
      result        NVARCHAR(MAX),
      next_sentence NVARCHAR(MAX),
      next_task_id  UNIQUEIDENTIFIER,
      next_group_id UNIQUEIDENTIFIER,
      DocumentId    INT,
      MethodId      INT
      CONSTRAINT PK__AsyncExe__CA90DA7B4BD51208
          PRIMARY KEY (submit_time, task_id)
  )
  
  CREATE INDEX [NonClusteredIndex-20180306-130204]
      ON async.ExecResults (group_id)
  
  CREATE UNIQUE INDEX IX_AsyncExecResults
      ON async.ExecResults (task_id)

  CREATE INDEX [IDC_Async_ExecResults_DocumentId]
      ON async.ExecResults (DocumentId)

END

IF NOT EXISTS (SELECT 1
      FROM sys.columns
      WHERE Name = 'asLogin' AND object_id = @objectId) BEGIN

  ALTER TABLE async.ExecResults
  ADD asLogin NVARCHAR(256) NULL

END


