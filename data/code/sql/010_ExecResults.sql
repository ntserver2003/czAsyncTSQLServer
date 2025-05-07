SET XACT_ABORT ON;

declare @objectId INT, @object SYSNAME;
SET @object = 'async.ExecResults';
SET @objectId = object_id(@object);

if @objectId IS NULL BEGIN
  CREATE TABLE async.ExecResults (
      id INT IDENTITY,
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
      ,CONSTRAINT PK_ExecResults_id PRIMARY KEY CLUSTERED (id)
  )
  
  CREATE INDEX [NonClusteredIndex-20180306-130204]
      ON async.ExecResults (group_id)
  
  CREATE UNIQUE INDEX IX_AsyncExecResults
      ON async.ExecResults (task_id)

  CREATE INDEX [IDC_Async_ExecResults_DocumentId]
      ON async.ExecResults (DocumentId)

END

IF COL_LENGTH(@object, 'asLogin') IS NULL BEGIN
  ALTER TABLE async.ExecResults
  ADD asLogin NVARCHAR(256) NULL
END

IF COL_LENGTH(@object, 'id') IS NULL BEGIN
  ALTER TABLE Async.ExecResults
    ADD id int IDENTITY
END

IF EXISTS (
    SELECT 1
    FROM sys.key_constraints 
    WHERE name = 'PK__AsyncExe__CA90DA7B4BD51208'
    AND parent_object_id = @objectId
) BEGIN
  ALTER TABLE Async.ExecResults
    DROP CONSTRAINT PK__AsyncExe__CA90DA7B4BD51208
  ALTER TABLE Async.ExecResults
    ADD CONSTRAINT PK_ExecResults_id PRIMARY KEY CLUSTERED (id)
END

IF COL_LENGTH(@object, 'worker') IS NULL BEGIN
  ALTER TABLE async.ExecResults
    ADD worker VARCHAR(50) NOT NULL DEFAULT 'default'
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE name = 'IDX_ExecResults_queued_id') BEGIN
    CREATE INDEX IDX_ExecResults_queued_id
    ON async.ExecResults (queued_id)
END
