USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_CustomerDel]    Script Date: 07/01/2015 06:15:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.DBA_CustomerDel    Script Date: 12/23/2013 4:27:31 PM ******/
ALTER PROCEDURE [dbo].[DBA_CustomerDel]
	@username varchar(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg varchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Delete Customer
DB: DBCUST/CustDB
Original:

Revisions:
	- 20090527@Kiwi: add checking for Casino
	- 20091203@Kiwi: Delete customer from CustSetting3rd and CustOverride3rd.
	- 20111028@Sophia: Delete Balance table
	- 20121015@Dan: Delete Live casino Balance table 
	- 20130108@Lukas: delete data in Dep_custsetting, custsettingGame, P2PGameSetting 
	- 20130306@Jim: change link server
	- 20131108@Elodie: Splitting bodb02 into CustDB (Move delete balance's customer to DBA_CustomerDel_Balance)
	- 20141022@Lukas: delete data in table custgameType
	- 20150622@Daniel: Separated custDB to server DBCUST
	
Param's Explanation:
	@username: pass the username of customer you want to delete.
*/		
Declare @roleid int, @custid int, @syncCasino bit
select @roleid = 0 
select	@roleid=roleid, 
		@custid = custid, 
		@syncCasino = SyncCasino
from custinfo with (NOLOCK)
where username = @username

if @roleid = 0
	select @ErrMsg = N'USERNAME not existed!'
	

---Check Horse Racing, Financials, Casino
/*
if @syncCasino = 1
BEGIN
	raisError ('This customer is already enabled Casino. Cannot delete', 16, 1)
		RETURN
END
*/

DECLARE @tmp_custID TABLE (CustID int)

if @roleid = 4
BEGIN
	if exists (select 1 from DBTXN.bodb02.dbo.bettrans with (nolock) where srecommend = @custid)
	BEGIN
		select @ErrMsg = N'Got bettrans already. Cannot delete.', @ErrCode = 100
		RETURN
	END
	delete CustSuper where custid = @custid	
	delete CustMaster where custid in (select custid from custinfo with (NOLOCK) where srecommend = @custid and roleid = 3)
	delete CustAgent where custid in (select custid from custinfo with (NOLOCK) where srecommend = @custid and roleid = 2)
	--delete subacc
	delete custsub where custid in (select custid from custinfo with (NOLOCK) where srecommend = @custid and roleid in(4,3,2))
	
	-- delete licensee superid
	delete Dep_CustSuper where custid = @custid	
		
	--insert downline custids into @tmp_custID	
	DELETE @tmp_custID
	INSERT INTO @tmp_custID
	SELECT custID FROM custinfo WITH (NOLOCK) WHERE srecommend = @custid
		
	delete custsetting where custid IN (SELECT custID FROM @tmp_custID)
	delete CustSetting3rd where custid IN (SELECT custID FROM @tmp_custID)
	delete CustSettingGame where custid IN (SELECT custID FROM @tmp_custID)
	delete Dep_CustSetting where custid IN (SELECT custID FROM @tmp_custID)
	delete Dep_CustSetting3rd where custid IN (SELECT custID FROM @tmp_custID)
	
	delete custoverride where custid IN (SELECT custID FROM @tmp_custID)
	delete CustOverride3rd where custid IN (SELECT custID FROM @tmp_custID)
	delete CustOverrideGame where custid IN (SELECT custID FROM @tmp_custID)
	
		
	delete P2PGameSetting where custid IN (SELECT custID FROM @tmp_custID)
	delete P2PGroupComm where custid IN (SELECT custID FROM @tmp_custID)
	
	delete from CustGameType WITH(ROWLOCK,UPDLOCK) WHERE CustID IN (SELECT custID FROM @tmp_custID)
	
	EXEC DBTXN.bodb02.dbo.DBA_CustomerDel_Balance @custid = @custid, @roleid = @roleid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	delete custinfo where custid IN (SELECT custID FROM @tmp_custID)
	delete customer where custid IN (SELECT custID FROM @tmp_custID)		
	
	IF @@ERROR <> 0
	BEGIN	
		select @ErrMsg = N'Delete customer failed.', @ErrCode = 101
		RETURN
	END
END

if @roleid = 3
BEGIN
	if exists (select 1 from DBTXN.bodb02.dbo.bettrans with (nolock) where mrecommend = @custid)
	BEGIN
		select @ErrMsg = N'Got bettrans already. Cannot delete.', @ErrCode = 100
		RETURN
	END
	delete CustMaster where custid = @custid
	delete CustAgent where custid in (select custid from custinfo with (NOLOCK) where mrecommend = @custid and roleid = 2)
	--delete subacc
	delete custsub where custid in (select custid from custinfo with (NOLOCK) where mrecommend = @custid and roleid in(3,2))

	--insert downline custids into @tmp_custID
	DELETE @tmp_custID
	INSERT INTO @tmp_custID
	SELECT custID FROM custinfo WITH (NOLOCK) WHERE mrecommend = @custid
	
	delete custsetting where custid IN (SELECT custID FROM @tmp_custID)
	delete CustSetting3rd where custid IN (SELECT custID FROM @tmp_custID)
	delete CustSettingGame where custid IN (SELECT custID FROM @tmp_custID)
	delete Dep_CustSetting where custid IN (SELECT custID FROM @tmp_custID)
	delete Dep_CustSetting3rd where custid IN (SELECT custID FROM @tmp_custID)
	
	delete custoverride where custid IN (SELECT custID FROM @tmp_custID)
	delete CustOverride3rd where custid IN (SELECT custID FROM @tmp_custID)
	delete CustOverrideGame where custid IN (SELECT custID FROM @tmp_custID)
	
	delete P2PGameSetting where custid IN (SELECT custID FROM @tmp_custID)
	delete P2PGroupComm where custid IN (SELECT custID FROM @tmp_custID)
	
	delete from CustGameType WITH(ROWLOCK,UPDLOCK) WHERE CustID IN (SELECT custID FROM @tmp_custID)
	
	EXEC DBTXN.bodb02.dbo.DBA_CustomerDel_Balance @custid = @custid, @roleid = @roleid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	delete custinfo where custid IN (SELECT custID FROM @tmp_custID)
	delete customer where custid IN (SELECT custID FROM @tmp_custID)	
	
	IF @@ERROR <> 0
	BEGIN	
		select @ErrMsg = N'Delete customer failed.', @ErrCode = 102
		RETURN
	END
END

if @roleid = 2
BEGIN
	
	if exists (select 1 from DBTXN.bodb02.dbo.bettrans with (nolock) where recommend = @custid)
	BEGIN
		select @ErrMsg = N'Got bettrans already. Cannot delete.', @ErrCode = 100
		RETURN
	END
	delete CustAgent where custid = @custid
	--delete subacc
	delete custsub where custid = @custid	 

	DELETE @tmp_custID
	INSERT INTO @tmp_custID
	SELECT custID FROM custinfo WITH (NOLOCK) WHERE recommend = @custid
	
	delete custsetting where custid IN (SELECT custID FROM @tmp_custID)
	delete CustSetting3rd where custid IN (SELECT custID FROM @tmp_custID)
	delete CustSettingGame where custid IN (SELECT custID FROM @tmp_custID)
	delete Dep_CustSetting where custid IN (SELECT custID FROM @tmp_custID)
	delete Dep_CustSetting3rd where custid IN (SELECT custID FROM @tmp_custID)
	
	delete custoverride where custid IN (SELECT custID FROM @tmp_custID)
	delete CustOverride3rd where custid IN (SELECT custID FROM @tmp_custID)
	delete CustOverrideGame where custid IN (SELECT custID FROM @tmp_custID)
	
	delete P2PGameSetting where custid IN (SELECT custID FROM @tmp_custID)
	delete P2PGroupComm where custid IN (SELECT custID FROM @tmp_custID)
	
	delete from CustGameType WITH(ROWLOCK,UPDLOCK) WHERE CustID IN (SELECT custID FROM @tmp_custID)
	
	EXEC DBTXN.bodb02.dbo.DBA_CustomerDel_Balance @custid = @custid, @roleid = @roleid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	delete custinfo where custid IN (SELECT custID FROM @tmp_custID)
	delete customer where custid IN (SELECT custID FROM @tmp_custID)

	IF @@ERROR <> 0
	BEGIN	
		select @ErrMsg = N'Delete customer failed.', @ErrCode = 103
		RETURN
	END
	/*
	--delete licensee customer on bodb_licensee
	EXEC DBLIC.bodb_licensee.dbo.DBA_LicenseeCustomerDel 
		@custid = @custid, 
		@roleid = @roleid,
		@ErrCode  = @ErrCode OUTPUT,
		@ErrMsg  = @ErrMsg OUTPUT

	IF @ErrCode <> 0 
	BEGIN 
		SELECT @ErrCode = @ErrCode, @ErrMsg = @ErrMsg
		RETURN
	END		
	*/	
END

if @roleid = 1
BEGIN
	if exists (select 1 from DBTXN.bodb02.dbo.bettrans with (nolock) where custid = @custid)
	BEGIN
		select @ErrMsg = N'Got bettrans already. Cannot delete.', @ErrCode = 100
		RETURN
	END
	
	delete custsetting where custid = @custid
	delete CustSetting3rd where custid = @custid
	delete custsettingGame where custid = @custid
	delete Dep_custsetting where custid = @custid
	delete Dep_custsetting3rd where custid = @custid
	
	delete P2PGameSetting where custid = @custid
	delete P2PGroupComm where custid = @custid
	
	delete from CustGameType WITH(ROWLOCK,UPDLOCK) WHERE custid = @custid
	
	EXEC DBTXN.bodb02.dbo.DBA_CustomerDel_Balance @custid = @custid, @roleid = @roleid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	delete custinfo where custid = @custid
	delete customer where custid = @custid
		
	IF @@ERROR <> 0
	BEGIN	
		select @ErrMsg = N'Delete customer failed.', @ErrCode = 104
		RETURN
	END
	
	--delete licensee customer on bodb_licensee
	EXEC DBLIC.bodb_licensee.dbo.DBA_LicenseeCustomerDel 
		@custid = @custid, 
		@roleid = @roleid,
		@ErrCode  = @ErrCode OUTPUT,
		@ErrMsg  = @ErrMsg OUTPUT

	IF @ErrCode <> 0 
	BEGIN 
		SELECT @ErrCode = @ErrCode, @ErrMsg = @ErrMsg
		RETURN
	END
	
END

PRINT @username + ' - '+ @ErrMsg


