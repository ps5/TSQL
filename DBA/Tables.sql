/* Tables */

-- Table sizes
SELECT s.object_id
  , table_name = object_schema_name(s.object_id) as schema_name, object_name(s.object_id)
  , data_MB = convert(float, round(sum(reserved_page_count / 1024. / 1024 * 8192), 1))
  , row_count = SUM(CASE WHEN (index_id < 2) THEN row_count ELSE 0 END)
  , reservedpages = SUM(reserved_page_count)
  , usedpages = SUM(used_page_count)
  , pages = SUM (CASE WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) ELSE 0 END)
FROM sys.dm_db_partition_stats s 
INNER JOIN sys.tables t on t.object_id = s.object_id
GROUP BY object_schema_name(s.object_id), object_name(s.object_id), s.object_id

