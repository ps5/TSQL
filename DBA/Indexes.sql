-- List index size
SELECT TableName = object_schema_name(i.[object_id]) + '.' + object_name(i.[object_id])
	, IndexName = i.[name]
    , IndexSizeMB = SUM(s.[used_page_count]) * 8 / 1024
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id] AND s.[index_id] = i.[index_id]
-- WHERE object_schema_name(i.[object_id]) + '.' + object_name(i.[object_id]) = 'dbo.TableName'
GROUP BY i.[name], object_schema_name(i.[object_id]) + '.' + object_name(i.[object_id])
ORDER BY (1), (2);


-- Index usage (current db)
SELECT TableName = object_schema_name(i.[object_id]) + '.' + OBJECT_NAME(I.OBJECT_ID)
    , IndexName = I.[name]
    , I.INDEX_ID
    , S.*
FROM SYS.INDEXES I
INNER JOIN SYS.OBJECTS O ON I.OBJECT_ID = O.OBJECT_ID
INNER JOIN SYS.DM_DB_INDEX_USAGE_STATS S ON S.OBJECT_ID = I.OBJECT_ID AND I.INDEX_ID = S.INDEX_ID AND DATABASE_ID = DB_ID()
WHERE object_schema_name(i.[object_id]) + '.' + OBJECT_NAME(I.OBJECT_ID) = 'dbo.TableName'
    AND OBJECTPROPERTY(O.OBJECT_ID,'IsUserTable') = 1
    AND I.NAME IS NOT NULL 
    AND OBJECT_NAME(I.OBJECT_ID) not like 'sys%'
    AND I.NAME not like 'PK%'    -- Ignore Pk's
    AND I.NAME not like 'UC%'    -- Ignore unique constraints.
ORDER BY (s.user_seeks+s.user_scans+s.user_lookups+s.user_updates) ASC;


