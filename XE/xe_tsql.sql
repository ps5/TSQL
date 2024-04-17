/*
Extended Events: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-event-session-transact-sql?view=sql-server-ver16
*/

DROP EVENT SESSION [xe_tsql] ON SERVER 
GO

CREATE EVENT SESSION [xe_tsql] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.sql_text,sqlserver.username)
    WHERE (
        sqlserver.server_principal_name<>N'sa'
        AND sqlserver.database_name<>'master'
        /* AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_hostname],N'%name%') 
           AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[client_hostname],N'name') 
           AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%name%') */
        )
),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.sql_text,sqlserver.username)
    WHERE (
        sqlserver.server_principal_name<>N'sa'
        AND sqlserver.database_name<>'master'
    )
) /*,
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.sql_text,sqlserver.username)
    WHERE (/*NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_hostname],N'%name%') 
            AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[client_hostname],N'name') 
            AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%name%') 
            AND */[sqlserver].[server_principal_name]<>N'CABLE\!cetsqlsvr'))
			*/
ADD TARGET package0.ring_buffer (SET max_memory = 2048 /* KB */);
-- ADD TARGET package0.event_file(SET filename=N'D:\XE\xe_tsql.xel',max_file_size=(5120)) WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
-- ADD TARGET package0.event_counter  
GO

ALTER EVENT SESSION [xe_tsql] ON SERVER  STATE=STOP
GO

ALTER EVENT SESSION [xe_tsql] ON SERVER  STATE=START
GO

