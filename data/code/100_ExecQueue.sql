if not exists (select 1 from sys.service_queues where name = 'ExecQueue' and schema_id = schema_id('async'))
  CREATE QUEUE [async].[ExecQueue] WITH STATUS = ON ,
      RETENTION = OFF ,
      ACTIVATION ( STATUS = ON , PROCEDURE_NAME = [async].[sp_ExecActivated] , MAX_QUEUE_READERS = 8 , EXECUTE AS OWNER ),
      POISON_MESSAGE_HANDLING (STATUS = ON)
      ON [PRIMARY]

