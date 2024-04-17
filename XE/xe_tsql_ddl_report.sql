;WITH raw_data(t) AS (
    SELECT CONVERT(XML, target_data)
    FROM sys.dm_xe_sessions AS s
    INNER JOIN sys.dm_xe_session_targets AS st
    ON s.[address] = st.event_session_address
    WHERE s.name = 'xe_tsql_ddl' AND st.target_name = 'ring_buffer'
), xml_data (ed) AS (
    SELECT e.query('.') 
    FROM raw_data 
    CROSS APPLY t.nodes('RingBufferTarget/event') AS x(e)
)

SELECT DatabaseName = DB_NAME(database_id)
, SchemaName = OBJECT_SCHEMA_NAME(object_id, database_id)
, ObjectName = OBJECT_NAME(object_id, database_id)
, EventPath = CASE object_type
	WHEN 'ROLE' THEN 'DatabaseRole'
	WHEN 'PARTITION_FUNCTION' THEN 'PartitionFunction'
	WHEN 'PARTITION_SCHEME' THEN 'PartitionScheme'
	WHEN 'SCHEMA' THEN 'Schema'
	WHEN 'PROC' THEN 'StoredProcedure'
	WHEN 'SYNONYM' THEN 'Synonym'
	WHEN 'TABLE' THEN 'Table'
	WHEN 'USER' THEN 'User'
	WHEN 'FUNCTION' THEN 'UserDefinedFunction'
	WHEN 'VIEW' THEN 'View'
	ELSE '' END
, Author = stuff(login, 1, charindex('\', login), '') + '@' 
	+ iif(charindex('\', login) > 0, substring(login, 1, charindex('\', login) - 1) + '.', '')
	+ 'domain.name'
, *
FROM (
  SELECT DISTINCT 
    [timestamp]       = ed.value('(event/@timestamp)[1]', 'datetime'),
    [database_id]     = ed.value('(event/data[@name="database_id"]/value)[1]', 'int'),
    [database_name]   = ed.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(128)'),
    [object_type_id]     = ed.value('(event/data[@name="object_type"]/value)[1]', 'nvarchar(128)'),
    [object_type]     = ed.value('(event/data[@name="object_type"]/text)[1]', 'nvarchar(128)'),
    [object_id]       = ed.value('(event/data[@name="object_id"]/value)[1]', 'int'),
    [object_name]     = ed.value('(event/data[@name="object_name"]/value)[1]', 'nvarchar(128)'),
    [session_id]      = ed.value('(event/action[@name="session_id"]/value)[1]', 'int'),
    [login]           = ed.value('(event/action[@name="server_principal_name"]/value)[1]', 'nvarchar(128)'),
    [client_hostname] = ed.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(128)'),
    [client_app_name] = ed.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)'),
    [sql_text]        = ed.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)'),
    [phase]           = ed.value('(event/data[@name="ddl_phase"]/text)[1]',    'nvarchar(128)')
  FROM xml_data
) AS x
-- WHERE database_id > 4
ORDER BY [timestamp] asc;
