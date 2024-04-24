/* Tables */

-- Table sizes
SELECT ObjectId = s.object_id
  , [Schema] = object_schema_name(s.object_id)
  , [Table] = object_name(s.object_id)
  , DataSizeMB = convert(float, round(sum(reserved_page_count / 1024. / 1024 * 8192), 1))
  , Rows = SUM(CASE WHEN (index_id < 2) THEN row_count ELSE 0 END)
  , ReservedPages = SUM(reserved_page_count)
  , UsedPages = SUM(used_page_count)
  , Pages = SUM (CASE WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) ELSE 0 END)
FROM sys.dm_db_partition_stats s 
INNER JOIN sys.tables t on t.object_id = s.object_id
GROUP BY object_schema_name(s.object_id), object_name(s.object_id), s.object_id
ORDER BY (4) DESC
GO

-- Tables by filegroup
SELECT [FileGroup] = f.name
  , [Schema] = s.name
  , [Table] = o.[name]
  , [Index] = i.[name]
  , IndexId = i.[index_id]
FROM sys.indexes i
INNER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id] 
LEFT JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE i.data_space_id = f.data_space_id
AND o.type = 'U' -- User Created Tables
-- AND f.name like '%'
ORDER BY (1), (2), (3), (4)
GO
