DROP EVENT SESSION [xe_tsql_ddl] ON SERVER 
GO

-- Excluding: USRTAB, STATISTICS, SRVXESES 17747 (telemetry) EVENTS; excluding tempdb
CREATE EVENT SESSION [xe_tsql_ddl] ON SERVER 
ADD EVENT sqlserver.object_altered(
    ACTION(sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name, sqlserver.server_principal_name, sqlserver.session_id, sqlserver.sql_text)
    WHERE(sqlserver.sql_text NOT LIKE 'EXEC%' AND sqlserver.sql_text NOT LIKE 'INSERT%' AND sqlserver.sql_text NOT LIKE 'UPDATE%' 
	AND ([ddl_phase]=(1) AND [object_type]<>(21587) AND [object_type]<>(8277) AND [object_type]<>(17747) AND [database_id]<>(2)
	)))
, ADD EVENT sqlserver.object_created(
    ACTION(sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name, sqlserver.server_principal_name, sqlserver.session_id, sqlserver.sql_text)
    WHERE(sqlserver.sql_text NOT LIKE 'EXEC%' AND sqlserver.sql_text NOT LIKE 'INSERT%' AND sqlserver.sql_text NOT LIKE 'UPDATE%' 
	AND ([ddl_phase]=(1) AND [object_type]<>(21587) AND [object_type]<>(8277) AND [object_type]<>(17747) AND [database_id]<>(2)
	)))
,ADD EVENT sqlserver.object_deleted(
    ACTION(sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name, sqlserver.server_principal_name, sqlserver.session_id, sqlserver.sql_text)
    WHERE(sqlserver.sql_text NOT LIKE 'EXEC%' AND sqlserver.sql_text NOT LIKE 'INSERT%' AND sqlserver.sql_text NOT LIKE 'UPDATE%' 
	AND ([ddl_phase]=(1) AND [object_type]<>(21587) AND [object_type]<>(8277) AND [object_type]<>(17747) AND [database_id]<>(2)
	)))
ADD TARGET package0.ring_buffer(SET max_events_limit=0,max_memory=102400)
WITH (STARTUP_STATE=ON)
GO

ALTER EVENT SESSION [xe_tsql_ddl] ON SERVER  STATE=START
GO



    