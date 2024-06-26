/* DISPLAY ALL PRINCIPALS HAVING PERMISSIONS GRANTED TO A DATABASE OBJECT (TABLE / VIEW)
*/
DECLARE @ObjectName nvarchar(max) = 'DatabaseName.SchemaName.TableName'; -- DB name is optional; iterates through all user DBs if empty

-- 
set nocount on
declare @ParamObjectName nvarchar(max) = replace(replace(@ObjectName, '[', ''), ']', '');
declare @database_name nvarchar(255) = isnull(PARSENAME(@ParamObjectName, 3), DB_NAME());
declare @schema_name nvarchar(255) = isnull(PARSENAME(@ParamObjectName, 2), 'dbo');
declare @object_name nvarchar(255) = PARSENAME(@ParamObjectName, 1)

if exists(select null from sys.databases where name = @database_name)
begin
	declare @execsql varchar(max);

	declare @tblObjectID table (xtype varchar(10));
	set @execsql = 'select xtype from ' + quotename(@database_name) + '.sys.sysobjects where object_schema_name(id, db_id(''' + @database_name + ''')) = ''' + @schema_name + ''' and name = ''' + @object_name + ''''
		+ ' and xtype in (''U'',''V'',''P'');';
	insert into @tblObjectID exec (@execsql);
	if @@rowcount > 0
	begin
		declare @xtype varchar(10) = (select max(xtype) from @tblObjectID);
		declare @permissions table (state_desc nvarchar(max)
		, permission_name nvarchar(max)
		, grantee_type nvarchar(max)
		, grantee_name nvarchar(max)
		, permission_level nvarchar(max)
		);
		set @execsql = 'select state_desc
		, permission_name
		, grantee_type = case when isapprole=1 then ''APPLICATION ROLE'' when islogin = 1 then ''LOGIN'' 
		when isntgroup = 1 then ''NT GROUP'' when isntuser = 1 then ''NT USER'' when  issqlrole = 1 then ''SQL ROLE'' when issqluser = 1 then ''SQL USER'' else ''N/A'' end 
		, grantee_name = name
		, via = class_desc
		from (/* via object level */
			SELECT p.permission_name, p.state_desc, p.grantee_principal_id, p.class_desc FROM ' + quotename(@database_name) + '.sys.database_permissions P JOIN ' + quotename(@database_name) + '.sys.tables T ON P.major_id = T.object_id 
			where  P.class_desc = ''OBJECT_OR_COLUMN'' AND OBJECT_SCHEMA_NAME(p.major_id) = ''' + @schema_name + ''' AND OBJECT_NAME(p.major_id) = ''' + @object_name + '''/* and t.type_desc = ''USER_TABLE'' */
			/* via schema */
			union all select p.permission_name, p.state_desc, p.grantee_principal_id, p.class_desc from ' + quotename(@database_name) + '.sys.database_permissions P JOIN ' + quotename(@database_name) + '.sys.schemas S ON P.major_id = S.schema_id 
			where P.class_desc = ''SCHEMA'' AND S.name = ''' + @schema_name + ''' 
			/* via database level */
			union all select p.permission_name, p.state_desc, p.grantee_principal_id, p.class_desc from ' + quotename(@database_name) + '.sys.database_permissions P 
			where P.class_desc = ''DATABASE'' AND p.type in (''AL'',''DL'',''EX'',''IN'',''RF'',''SL'',''UP'',''VW'')
			) X
			JOIN ' + quotename(@database_name) + '.sys.sysusers U ON U.uid = X.grantee_principal_id
		where state_desc = ''GRANT''
		order by 1, 2, 3, 4'

		insert into @permissions exec (@execsql)
		select * from @permissions
		where (@xtype = 'P' and permission_name not in ('DELETE','INSERT','SELECT','UPDATE'))
			OR (@xtype != 'P' and permission_name not in ('EXECUTE'))
	end
	else begin
		print @execsql
		declare @error_msg nvarchar(max) = 'Object ' + @ObjectName + ' not exists ' + isnull('in ' + @database_name, '');
		throw 50000, @error_msg, 1;
	end
end



