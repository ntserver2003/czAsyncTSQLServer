CREATE OR ALTER PROCEDURE async.[sp_ExecInvoke] @sentence NVARCHAR(MAX) = NULL,
                                              @next_sentence NVARCHAR(MAX) = NULL,
                                              @extra_info NVARCHAR(MAX) = NULL,
                                              @execGroup BIT = NULL,
                                              @group_id UNIQUEIDENTIFIER = NULL OUTPUT,
                                              @task_id UNIQUEIDENTIFIER = NULL OUTPUT,
                                              @methodId INT = NULL, -- MB MethodId
                                              @documentId INT = NULL, -- MB DocumentId
                                              /*
                                              Execute sentence mode. Default: as system user
                                              0 - as current login
                                              1 - as system user
                                              */
                                              @asSystemUser BIT = 1
AS
BEGIN
    ------------------------------------------------------------------------
    -- Author: Cesar Pedro Zea Gomez <cesarzea@jaunesistemas.com>
    -- https://www.cesarzea.com
    ------------------------------------------------------------------------
    DECLARE @h UNIQUEIDENTIFIER,
        @xmlBody XML,
        @queued_time DATETIME2,
        @submit_time DATETIME2 = SYSUTCDATETIME(),
        @queued_id UNIQUEIDENTIFIER;

    IF (@task_id IS NOT NULL)
        BEGIN

            SELECT @group_id = group_id,
                   @sentence = sentence
                FROM async.ExecResults
                WHERE task_id = @task_id

        END
    ELSE
        BEGIN

            IF (@group_id IS NULL)
                SET @group_id = NEWID()

        END

    BEGIN TRY

        IF (@sentence IS NOT NULL OR @next_sentence IS NOT NULL)
            BEGIN

                IF ((@execGroup IS NULL OR @execGroup = 1))
                    BEGIN
                        BEGIN DIALOG CONVERSATION @h
                            FROM SERVICE [AsyncExecService]
                            TO SERVICE N'AsyncExecService', 'current database'
                            WITH ENCRYPTION = OFF;

                        SELECT @queued_id = [conversation_id]
                            FROM sys.conversation_endpoints
                            WHERE [conversation_handle] = @h;

                        SET @queued_time = @submit_time;

                        SELECT @xmlBody =
                               (
                                   SELECT @sentence AS [name]
                                       FOR XML PATH ('procedure'), TYPE
                               );

                        SEND ON CONVERSATION @h(@xmlBody);
                    END

                --select * from sys.dm_broker_queue_monitors
                --select * from sys.service_queues
                --select is_broker_enabled, * from sys.databases
                --ALTER QUEUE [dbo].[AsyncExecQueue] WITH ACTIVATION (STATUS = OFF);
                --ALTER QUEUE [dbo].[AsyncExecQueue]  WITH ACTIVATION (STATUS = ON);

                IF (@task_id IS NULL)
                    BEGIN

                        SET @task_id = NEWID();

                        INSERT INTO async.ExecResults ([task_id],
                                                          group_id,
                                                          [sentence],
                                                          extra_info,
                                                          next_sentence,
                                                          queued_id,
                                                          queued_time,
                                                          MethodId,
                                                          DocumentId,
                                                          asLogin)
                            VALUES (@task_id,
                                    @group_id,
                                    @sentence,
                                    @extra_info,
                                    @next_sentence,
                                    @queued_id,
                                    @queued_time,
                                    @methodId,
                                    @documentId,
                                    IIF(ISNULL(@asSystemUser, 1) = 1, NULL, SUSER_NAME()));

                    END
                ELSE
                    BEGIN

                        UPDATE async.ExecResults
                        SET queued_id   = @queued_id,
                            queued_time = @queued_time
                            WHERE task_id = @task_id

                    END

            END

        -- if @execGroup = true -> check if exists non programed task in the group
        IF (@execGroup IS NULL OR @execGroup = 1)
            BEGIN

                DECLARE @task_to_program UNIQUEIDENTIFIER

                SELECT @task_to_program = task_id
                    FROM async.ExecResults
                    WHERE queued_id IS NULL
                      AND sentence IS NOT NULL
                      AND group_id = @group_id

                WHILE (@task_to_program IS NOT NULL)
                    BEGIN

                        EXEC async.sp_ExecInvoke
                             @task_id = @task_to_program,
                             @group_id = @group_id

                        SET @task_to_program = NULL

                        SELECT @task_to_program = task_id
                            FROM async.ExecResults
                            WHERE queued_id IS NULL
                              AND sentence IS NOT NULL
                              AND group_id = @group_id

                    END
            END

    END TRY
    BEGIN CATCH

        DECLARE @error INT, @message NVARCHAR(2048), @xactState SMALLINT;

        SELECT @error = ERROR_NUMBER(),
               @message = ERROR_MESSAGE(),
               @xactState = XACT_STATE();

        RAISERROR (N'Error: %i, %s', 16, 1, @error, @message);

    END CATCH;
END;
go

GRANT EXECUTE, REFERENCES ON async.[sp_ExecInvoke] to [MACROBANK WORKGROUP]
GO