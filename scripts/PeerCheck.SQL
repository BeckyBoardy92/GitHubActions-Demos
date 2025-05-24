-- Accept variables from sqlcmd or :setvar
-- :setvar EnvironmentCategory Prd
-- :setvar ExpectedSQLPatch CU19

DECLARE @EnvironmentCategory NVARCHAR(20) = '$(EnvironmentCategory)';
DECLARE @ExpectedSQLPatch VARCHAR(5) = '$(ExpectedSQLPatch)';

-- SELECT @@VERSION 

CREATE Table #PeerCheckResults (PeerCheck varchar(255), Results Varchar(max), outcome varchar (50))

--SQL Patch Level Check

Declare @SQLEdition varchar(100) = (select cast (serverproperty('edition') as varchar (100)))
Declare @SQLVersion varchar(max) = @@version

if @EnvironmentCategory = 'Prd'
begin
if @SQLVersion LIKE '%' + @ExpectedSQLPatch + '%' and @SQLEdition like '%Enterprise%'
insert into #PeerCheckResults
select 'SQL Patch Level Check' as PeerCheck, CONCAT(substring(@SQLVersion,1,(charindex('(X64)',@SQLVersion,1)+LEN('X64)'))-1),',',@SQLEDITION) AS RESULTS, 'SUCCESS' as Outcome
else
insert into #PeerCheckResults
select 'SQL Patch Level Check' as PeerCheck, CONCAT(substring(@SQLVersion,1,(charindex('(X64)',@SQLVersion,1)+LEN('X64)'))-1),',',@SQLEDITION) AS RESULTS, 'FAIL' as Outcome
end


if @EnvironmentCategory = 'Dev'
begin
if @SQLVersion LIKE '%' + @ExpectedSQLPatch + '%' and @SQLEdition like '%Developer%'
insert into #PeerCheckResults
select 'SQL Patch Level Check' as PeerCheck, CONCAT(substring(@SQLVersion,1,(charindex('(X64)',@SQLVersion,1)+LEN('X64)'))-1),',',@SQLEDITION) AS RESULTS, 'SUCCESS' as Outcome
else
insert into #PeerCheckResults
select 'SQL Patch Level Check' as PeerCheck, CONCAT(substring(@SQLVersion,1,(charindex('(X64)',@SQLVersion,1)+LEN('X64)'))-1),',',@SQLEDITION) AS RESULTS, 'FAIL' as Outcome
end


-- Sanity check: Server collation is LATIN1_GENERAL_CI_AS
DECLARE @collation NVARCHAR(128), @collation_result NVARCHAR(1000), @collation_outcome VARCHAR(50);

SELECT @collation = CAST(SERVERPROPERTY('Collation') AS NVARCHAR(128));

IF (@collation = 'LATIN1_GENERAL_CI_AS')
BEGIN
    SET @collation_result = 'PASS: Server collation is LATIN1_GENERAL_CI_AS';
    SET @collation_outcome = 'SUCCESS';
END
ELSE
BEGIN
    SET @collation_result = 'FAIL: Server collation is ' + ISNULL(@collation, 'NULL') + ', expected LATIN1_GENERAL_CI_AS';
    SET @collation_outcome = 'FAIL';
END

INSERT INTO #PeerCheckResults (PeerCheck, Results, outcome)
VALUES ('Server Collation Check', @collation_result, @collation_outcome);


-- Check for all accounts with sysadmin role, return as a single list (collation safe for all columns)
DECLARE @sysadmins NVARCHAR(MAX);

SELECT @sysadmins = STRING_AGG(
    name COLLATE DATABASE_DEFAULT + ' (' + type_desc COLLATE DATABASE_DEFAULT + ')', ', '
)
FROM sys.server_principals
WHERE principal_id IN (
    SELECT member_principal_id
    FROM sys.server_role_members
    WHERE role_principal_id = SUSER_ID('sysadmin')
);

IF @sysadmins IS NULL OR LEN(@sysadmins) = 0
    SET @sysadmins = 'No sysadmin accounts found';

INSERT INTO #PeerCheckResults (PeerCheck, Results, outcome)
VALUES ('Sys Admin Accounts', @sysadmins, 'MANUALLY CHECK');


-- Enable xp_cmdshell if disabled, and restore original state at the end
DECLARE @xp_cmdshell_enabled INT, @xp_cmdshell_was_disabled BIT = 0;

-- Check if xp_cmdshell is enabled
SELECT @xp_cmdshell_enabled = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'xp_cmdshell';

IF (@xp_cmdshell_enabled = 0)
BEGIN
    SET @xp_cmdshell_was_disabled = 1;
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;
END

-- Check OS regional settings using PowerShell via xp_cmdshell
DECLARE @locale NVARCHAR(100), @result NVARCHAR(1000), @outcome VARCHAR(50);

CREATE TABLE #LocaleResult (output NVARCHAR(100));
INSERT INTO #LocaleResult
EXEC xp_cmdshell 'powershell -Command "Get-WinSystemLocale | Select-Object -ExpandProperty Name"';

SELECT TOP 1 @locale = output FROM #LocaleResult WHERE output IS NOT NULL AND output <> 'NULL';

IF (@locale = 'en-GB')
BEGIN
    SET @result = 'PASS: OS regional settings are set to United Kingdom (en-GB)';
    SET @outcome = 'SUCCESS';
END
ELSE
BEGIN
    SET @result = 'FAIL: OS regional settings are NOT set to United Kingdom. Current setting: ' + ISNULL(@locale, 'Unknown');
    SET @outcome = 'FAIL';
END

INSERT INTO #PeerCheckResults (PeerCheck, Results, outcome)
VALUES ('OS Regional Settings', @result, @outcome);

DROP TABLE #LocaleResult;

-- Restore xp_cmdshell state if it was originally disabled
IF (@xp_cmdshell_was_disabled = 1)
BEGIN
    EXEC sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;
END


-- Check if server authentication is set to Windows only
DECLARE @auth_mode INT, @auth_result NVARCHAR(1000), @auth_outcome VARCHAR(50);

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    N'LoginMode',
    @auth_mode OUTPUT,
    'no_output';

IF (@auth_mode = 1)
BEGIN
    SET @auth_result = 'PASS: Server authentication is set to Windows Authentication only';
    SET @auth_outcome = 'SUCCESS';
END
ELSE IF (@auth_mode = 2)
BEGIN
    SET @auth_result = 'FAIL: Server authentication is set to SQL Server and Windows Authentication (Mixed Mode)';
    SET @auth_outcome = 'FAIL';
END
ELSE
BEGIN
    SET @auth_result = 'FAIL: Could not determine server authentication mode.';
    SET @auth_outcome = 'FAIL';
END

INSERT INTO #PeerCheckResults (PeerCheck, Results, outcome)
VALUES ('Server Authentication Mode', @auth_result, @auth_outcome);


-- Send an email with all results from #PeerCheckResults in a clear HTML table
DECLARE @body NVARCHAR(MAX) = N'';
DECLARE @subject NVARCHAR(255);
DECLARE @servername NVARCHAR(128) = CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128));
DECLARE @instancename NVARCHAR(128) = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128));

-- Build HTML body with color coding and clear table headings
SET @body = N'<html><body>' +
    N'<h2>Peer Check Results for ' + @servername + '</h2>' +
    N'<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">' +
    N'<tr style="background-color:#f2f2f2;"><th>Check</th><th>Results</th><th>Outcome</th></tr>';

DECLARE @check NVARCHAR(255), @resultemail NVARCHAR(MAX), @outcomeemail VARCHAR(50), @color NVARCHAR(20);
DECLARE cur CURSOR FOR
    SELECT PeerCheck, Results, outcome FROM #PeerCheckResults;

OPEN cur;
FETCH NEXT FROM cur INTO @check, @resultemail, @outcomeemail;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @outcomeemail = 'FAIL'
        SET @color = 'red';
    ELSE IF @outcomeemail = 'SUCCESS'
        SET @color = 'green';
    ELSE IF @outcomeemail = 'MANUALLY CHECK'
        SET @color = 'orange';
    ELSE
        SET @color = 'black';

    SET @body = @body + N'<tr>' +
        N'<td>' + ISNULL(@check, '') + N'</td>' +
        N'<td>' + ISNULL(@resultemail, '') + N'</td>' +
        N'<td><b><span style="color:' + @color + '">' + ISNULL(@outcomeemail, '') + N'</span></b></td>' +
        N'</tr>';
    FETCH NEXT FROM cur INTO @check, @resultemail, @outcomeemail;
END
CLOSE cur;
DEALLOCATE cur;

SET @body = @body + N'</table></body></html>';
SET @subject = 'Peer Check Results for ' + @servername + ' (' + @instancename + ')';

-- Send the email (replace profile and recipients as needed)
BEGIN TRY
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'GmailProfile1',
        @recipients = 'rebeccamboardman@gmail.com',
        @subject = @subject,
        @body = @body,
        @body_format = 'HTML';
END TRY
BEGIN CATCH
    INSERT INTO #PeerCheckResults (PeerCheck, Results, outcome)
    VALUES ('Script Error', ERROR_MESSAGE(), 'FAIL');
END CATCH;


-- Only output the results table at the end
select * from #PeerCheckResults
DROP TABLE #PeerCheckResults



