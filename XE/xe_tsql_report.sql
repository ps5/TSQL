-- List XE targets
SELECT * -- name, target_name, CAST(xet.target_data AS xml)  
FROM sys.dm_xe_session_targets AS xet
	JOIN sys.dm_xe_sessions AS xe ON (xe.address = xet.event_session_address)  
WHERE xe.name = 'xe_tsql' 
GO


-- Parse RingBuffer target data
DECLARE @target_data xml = (
	SELECT CONVERT(xml, target_data)
	FROM sys.dm_xe_sessions AS s 
	JOIN sys.dm_xe_session_targets AS t ON t.event_session_address = s.address
	WHERE s.name = 'xe_tsql' AND t.target_name = N'ring_buffer' 
	);

 ;WITH src AS (
    SELECT xeXML = xm.s.query('.') FROM @target_data.nodes('/RingBufferTarget/event') AS xm(s)
)
, parsed AS (
	SELECT [xeTimeStamp] = src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')
	, [event_name] = src.xeXML.value('(/event/@name)[1]', 'nvarchar(max)')
	, [sql_text] = src.xeXML.value('(/event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)')
	, [statement] = src.xeXML.value('(/event/data[@name="statement"]/value)[1]', 'nvarchar(max)')
	, [client_hostname] = src.xeXML.value('(/event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)')
	, [server_principal_name] = src.xeXML.value('(/event/action[@name="server_principal_name"]/value)[1]', 'nvarchar(max)')
	, [database_name] = src.xeXML.value('(/event/action[@name="database_name"]/value)[1]', 'nvarchar(max)')
	, [client_app_name] = src.xeXML.value('(/event/action[@name="client_app_name"]/value)[1]', 'nvarchar(max)')
	, [user_defined] = src.xeXML.value('(/event/data[@name="user_defined"]/value)[1]', 'nvarchar(max)')
	, [is_intercepted] = src.xeXML.value('(/event/data[@name="is_intercepted"]/value)[1]', 'nvarchar(max)')	
	, src.xeXML     
	FROM src
)
SELECT * FROM parsed
-- WHERE [database_name] != 'master' AND server_principal_name != 'sa'
-- AND isnull(message, '') not like 'Warning: Null value is eliminated by an aggregate or other SET operation.%'
ORDER BY 1 DESC;

