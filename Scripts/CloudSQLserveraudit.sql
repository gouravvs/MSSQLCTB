-- 1. Create the Server Audit object
CREATE SERVER AUDIT [Audit_login]--- give the name of the Audit 
TO FILE
(
    FILEPATH = N'/var/opt/mssql/audit', -- This is the internal Cloud SQL path which we have to always use 
    MAXSIZE = 50 MB,
    MAX_ROLLOVER_FILES = UNLIMITED,
    RESERVE_DISK_SPACE = OFF
)
        -- If the audit fails, connections can continue (recommended for production)
WITH (QUEUE_DELAY = 1000,ON_FAILURE = CONTINUE );-- will flush the logs in every 1000ms/ 1 sec 
GO

-- 2. Enable the Server Audit
ALTER SERVER AUDIT [Audit_login] WITH (STATE = ON);
GO

-- 3. Create the Server Audit Specification
CREATE SERVER AUDIT SPECIFICATION [Login_Alerts]
FOR SERVER AUDIT [Audit_login] -- Links to the audit created above
ADD (SUCCESSFUL_LOGIN_GROUP), -- for sucessfull logins 
ADD (FAILED_LOGIN_GROUP),       -- for failed logins
ADD (LOGOUT_GROUP)             -- for logouts 
WITH (STATE = ON);
GO

-- to check the logs 

SELECT * FROM msdb.dbo.gcloudsql_fn_get_audit_file('/var/opt/mssql/audit/*', NULL, NULL) 

--- Reading the events from the outout file 

 Select
    session_id,
    server_principal_name,
   CASE
        WHEN action_id = 'LGIS' THEN 'SUCCESSFUL LOGIN'
        WHEN action_id = 'LGIF' THEN 'FAILED LOGIN'
        WHEN action_id = 'LGO' THEN 'LOGOUT'
        WHEN action_id = 'AUSC' THEN 'AUDIT SESSION START/CREATE'
        ELSE 'OTHER EVENT (' + action_id + ')'
    END AS [Event Type],
   succeeded,
    event_time,
    client_ip,
    host_name,
    application_name,
    statement
    FROM msdb.dbo.gcloudsql_fn_get_audit_file('/var/opt/mssql/audit/*', NULL, NULL)
    WHERE server_principal_name NOT IN (
        'NT AUTHORITY\SYSTEM',
        'NT AUTHORITY\NETWORK SERVICE',
        'NT SERVICE\SQLSERVERAGENT',
        'NT SERVICE\SQLWriter',
        '##MS_PolicyEventProcessingLogin##',
        '##MS_PolicyTsqlExecutionLogin##',
        'BUILTIN\Administrators',
        'CloudDbSqlAgent',
        'CloudDbSqlAgent_2',
        'CloudDbSqlRoot',
        'CloudDbSqlRoot_2'
      )
      and action_id IN ('LGO', 'LGIS' ,'LGIF')
ORDER BY
    event_time DESC;