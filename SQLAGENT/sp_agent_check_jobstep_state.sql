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

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_agent_check_jobstep_state')
	EXEC ('CREATE PROC dbo.sp_agent_check_jobstep_state AS SELECT ''stub version, to be replaced''')
GO

/*
Checks if a given step for a CURRENTLY RUNNING SQL Agent job has succeeded today 
Returns:
	 3 - cancelled
	 2 - failed; pending retry
	 1 - step succeeded
	 0 - step failed
	-1 - did not run / currently running
	
Assumptions and limitations: job is assumed to be currently running (in progress) when you run this when @currently_running_job_only is set to 1;
							 if set to 0 - all runs for current day are checked


*/

ALTER PROC [dbo].[sp_agent_check_jobstep_state] @job_id UNIQUEIDENTIFIER, @step_name varchar(255) = null, @step_id int = null, @currently_running_job_only bit = 1, @ThrowOnStatus int = null AS

DECLARE @run_status INT = -1
	,@last_instance_id INT
	,@message VARCHAR(max)
	--,@step_id INT
	-- ,@step_name varchar(255)
	,@run_time varchar(255)

set @message = 'Unknown step ' + isnull('ID ' + convert(varchar, @step_id), 'name: ' + @step_name)

if @step_id is null
	select @step_id = step_id, @step_name = step_name from msdb.dbo.sysjobsteps where job_id = @job_id AND step_name = @step_name
else
begin
	set @step_id = @step_id
	select @step_name = step_name from msdb.dbo.sysjobsteps where job_id = @job_id AND step_id = @step_id
end

if @step_id is null
BEGIN
	RAISERROR (@message, 17, 0) -- Unknown step
	-- RETURN NULL
END
ELSE
BEGIN

	IF @currently_running_job_only = 1 -- currently running job
		SELECT @last_instance_id = isnull(max(instance_id), 0) FROM  [msdb].[dbo].sysjobhistory WHERE job_id = @job_id AND step_id = 0 -- record ID of the most recent completed run; or 0 if running job for the first time
	ELSE -- any completed today
	begin
		-- get last completed job record ID for today
		SELECT @last_instance_id = (select max(instance_id) from [msdb].[dbo].sysjobhistory WHERE job_id = @job_id AND step_id = 0 and instance_id < (select min(instance_id) FROM  [msdb].[dbo].sysjobhistory WHERE job_id = @job_id AND step_id = 0 and run_date = convert(int, convert(varchar(8), convert(date, getdate()), 112))) )

		IF @last_instance_id is null -- no successfully completed jobs today
			SELECT  @last_instance_id = ISNULL((select max(instance_id) from [msdb].[dbo].sysjobhistory WHERE job_id = @job_id and run_date < convert(int, convert(varchar(8), convert(date, getdate()), 112))) , 0) -- last step before today

	end

	IF @last_instance_id IS NOT NULL
	begin
		SELECT TOP 1 @run_status = ISNULL(run_status, -1) -- last run status or a step or -1 if didn't run
		, @run_time = 'ID: ' + convert(varchar, instance_id) + ' @ ' + convert(varchar, run_date) + ' ' +  convert(varchar, run_time)
		FROM [msdb].[dbo].sysjobhistory
		WHERE job_id = @job_id AND step_id = @step_id AND instance_id > @last_instance_id
		ORDER BY instance_id DESC

	
		--if exists (select null from [msdb].[dbo].sysjobhistory WHERE job_id = @job_id AND step_id = @step_id AND instance_id > @last_instance_id and run_status = 1) -- succeeded once
		--	set @run_status = 1
	end
	ELSE
		SET @run_status = -1 -- did not run
		
	set @message = 'Step ' + convert(varchar, @step_id) + ': '	+ isnull(@step_name + ' ','')
	 + case isnull(convert(varchar,@run_status),'') 
	 when '3' then 'cancelled'
	 when '2' then 'failed; pending retry'
	 when '1' then 'step succeeded'
	 when '0' then 'step failed'
	 when '-1' then 'did not run / currently running' 
	 else 'undefined' end
	 + ' (' + convert(varchar, @run_status) + isnull('; ' + @run_time,'') + ')' --ID > ' + convert(varchar, @last_instance_id) + ')' 

END

IF @ThrowOnStatus = @run_status RAISERROR (@message, 17, 1)
	ELSE PRINT @message;

RETURN @run_status


