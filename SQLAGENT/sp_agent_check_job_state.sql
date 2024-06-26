USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ANSI_WARNINGS ON;
SET NUMERIC_ROUNDABORT OFF;
SET ARITHABORT ON;
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_agent_check_job_state')
	EXEC ('CREATE PROC dbo.sp_agent_check_job_state AS SELECT ''stub version, to be replaced''')
GO

/*
Checks if a given SQL Agent job succeeded today (or on a date supplied in a param).
Default date value: today

Assumptions and limitations: job is assumed to run once a day only; so the check is for run_date only

*/
ALTER PROC [dbo].[sp_agent_check_job_state] @job_id UNIQUEIDENTIFIER, @run_date date = NULL, @ThrowOnStatus int = null AS

DECLARE @run_status INT
	,@job_status VARCHAR(max)

	
SELECT @run_status = run_status
	, @job_status = 'Job ' + job_name + ' '
	 + CASE WHEN run_status = 3 THEN 'is stopped (cancelled)'
			WHEN run_status = 2 THEN 'is running'
			WHEN run_status = 1 THEN 'has succeeded' + isnull(' at ' + convert(varchar, run_time), '')
			WHEN run_status = 0 THEN 'has failed'
			WHEN run_status = -1 THEN 'did not run'
			ELSE 'not found' END
FROM (
	SELECT TOP 1 run_status = CASE WHEN s.session_id IS NOT NULL THEN 2 -- running now (2)
			ELSE 
				  CASE WHEN jh.step_id IS NULL THEN -1 -- did not run (-1)
					   WHEN jh.step_id = 0 THEN 
							CASE WHEN jh.run_status = 1 THEN 1 -- succeeded (1)
								ELSE 0 -- failed (0)
							END
					   ELSE 2 END -- 'is still running' END
			END

		   , run_time = dateadd(hour, jh.run_duration / 10000, dateadd(minute, jh.run_duration / 100 % 100, dateadd(second, jh.run_duration % 100
					, dateadd(hour, jh.run_time / 10000, dateadd(minute, jh.run_time / 100 % 100, dateadd(second, jh.run_time % 100
					, convert(DATETIME, convert(VARCHAR, jh.run_date)))))) ))  

			, job_name = sj.name
	FROM msdb.dbo.sysjobs sj 
	LEFT JOIN [msdb].[dbo].sysjobhistory jh ON jh.job_id = sj.job_id 
		AND (jh.run_date = isnull(convert(int, convert(varchar, @run_date, 112)), convert(INT, convert(VARCHAR, getdate(), 112))))
	OUTER APPLY (SELECT session_id FROM  (SELECT job_uid = substring(program_name , 30, 34), session_id FROM sys.dm_exec_sessions WHERE program_name like 'SQLAgent%' and substring(program_name , 30, 2) = '0x') s
		WHERE job_uid = convert(varchar(max), convert(binary(16), convert(UNIQUEIDENTIFIER, sj.job_id), 1),1) 
		) s
	WHERE sj.job_id = @job_id
	ORDER BY jh.instance_id DESC
	) x


IF @ThrowOnStatus = @run_status RAISERROR (@job_status, 17, 0)
ELSE PRINT @job_status

RETURN @run_status 



