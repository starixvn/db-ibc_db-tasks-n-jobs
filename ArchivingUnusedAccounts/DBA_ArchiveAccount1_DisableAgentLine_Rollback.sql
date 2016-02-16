ALTER PROCEDURE [dbo].[DBA_ArchiveAccount1_DisableAgentLine_Rollback]
	@AccName varchar(50),
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: Daniel
	Date: 2016-01-12
	Task: Archive Acc (New) - sp for ROLLING BACK stage 1 - enable + restore credit of whole agent line 
	DB: DBCUST/CustDB
	
	Revisions:

*/
    
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int, @Now datetime
set @startRun = getdate()

Declare @roleid int, @AgentID int, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has NOT been archived or has been RESTORED BACK already!!', @ErrCode = 102
	print @ErrMsg
	return
END

print  @AccName +':'+ 'START:' + convert(varchar(50), getdate(), 113)

--================================
--PERFORM RESTORE CUST INFO DATA
--================================

SELECT custid, closed, credit INTO #tmp
FROM DBARCCUST.bodb_Customer.dbo.custinfo_old WITH(NOLOCK)
WHERE custid IN (select custid from custinfo with (nolock) WHERE recommend = @AgentID)

WHILE (1 = 1)
BEGIN
	UPDATE TOP(1000) ci WITH (ROWLOCK, UPDLOCK)
	SET enabled = 1, closed = t.closed, credit = t.credit
	FROM custinfo ci INNER JOIN #tmp t ON ci.custid = t.custid
	WHERE ci.enabled = 0 
	
	WAITFOR DELAY '000:00:00.200'
	
	IF @@ROWCOUNT < 1000
		BREAK
END

DROP TABLE #tmp

--=======================================================
--DELETE BACKUP CUST SETTING & CUSTOMER DATA IN DBARCCUST
--=======================================================
--Pre-check: Make sure cust setting data not deleted yet in main DB
IF NOT EXISTS(
	SELECT 1 FROM dbo.custsetting WITH(NOLOCK) 
	WHERE custid IN(select custid from custinfo with (nolock) WHERE recommend = @AgentID AND roleid = 1)
	)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent already archived cust setting data & need to restore from DBARCCUST', @ErrCode = 10
	print @ErrMsg
	return
END

SELECT custid INTO #tmp1 FROM dbo.custinfo WITH(NOLOCK) 
WHERE recommend = @AgentID AND roleid = 1

DELETE DBARCCUST.bodb_Customer.dbo.customer_old WHERE custid IN(select custid from #tmp1)
DELETE DBARCCUST.bodb_Customer.dbo.custSetting_old WHERE custid IN(select custid from #tmp1)
DELETE DBARCCUST.bodb_Customer.dbo.custSetting3rd_old WHERE custid IN(select custid from #tmp1)
DELETE DBARCCUST.bodb_Customer.dbo.CustSettingGame_Old WHERE custid IN(select custid from #tmp1)
DELETE DBARCCUST.bodb_Customer.dbo.CustGameType_old WHERE custid IN(select custid from #tmp1)
DELETE DBARCCUST.bodb_Customer.dbo.CustVirtualRate_old WHERE custid IN(select custid from #tmp1)
DELETE DBARCCUST.bodb_Customer.dbo.CustVirtualSetting_old WHERE custid IN(select custid from #tmp1)

DROP TABLE #tmp1


--========================================
--DELETE BACKUP CUSTINFO DATA IN DBARCCUST
--========================================
SELECT custid INTO #tmp2 FROM dbo.custinfo WITH(NOLOCK) 
WHERE recommend = @AgentID AND roleid = 1
--Pre-check: Verify cust info data was restored correctly
IF NOT EXISTS(SELECT 1 FROM #tmp2)
	OR EXISTS(
	SELECT 1 FROM dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN DBARCCUST.bodb_Customer.dbo.custinfo_old aci WITH(NOLOCK) ON ci.custid = aci.custid
	WHERE ci.custid IN(select custid from #tmp2)
		AND (ci.credit <> aci.credit OR ci.closed <> aci.closed)
	)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has problem with restored cust-info data, please check from DBARCCUST', @ErrCode = 10
	print @ErrMsg
	return
END

DELETE DBARCCUST.bodb_Customer.dbo.custinfo_old WHERE custid IN(select custid from #tmp2)

DROP TABLE #tmp2


----------------------------------------------------------------
print  @AccName +':'+ 'END:' + convert(varchar(50), getdate(), 113)

------------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<DBA_ArchiveAccount1_DisableAgentLine_Rollback AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1))+ '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))  + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1500,
	@TrackingValue = @LogSPData	,
	@duration = @duration