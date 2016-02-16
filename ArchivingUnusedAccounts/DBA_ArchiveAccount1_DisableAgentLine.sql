ALTER PROCEDURE [dbo].[DBA_ArchiveAccount1_DisableAgentLine]
	@AccName varchar(50),
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: Daniel
	Date: 2016-01-12
	Task: Archive Acc (New) - sp for stage 1 - backup data & disable+clear credit of whole agent line 
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

if @Enabled = 0
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END


--== Check new active trans ==========================

IF EXISTS(select 1 from DBTXN.bodb02.dbo.bettrans with (nolock) where recommend = @AgentID AND bettype <> 20000 and custid <> 0)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent just got active trans while processing!', @ErrCode = 101
	INSERT INTO [dbo].[CustArc_NewActive] (AgentID) VALUES(@AgentID) 
	print @ErrMsg
	return
END

IF EXISTS(select 1 from DBTXN.bodb02.dbo.translog with (nolock) where recommend = @AgentID)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent just got active trans while processing!', @ErrCode = 101
	INSERT INTO [dbo].[CustArc_NewActive] (AgentID) VALUES(@AgentID) 
	print @ErrMsg
	return
END

IF EXISTS(select 1 from DBTXN.bodb02.dbo.bettransLC with (nolock) where recommend = @AgentID)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent just got active trans while processing!', @ErrCode = 101
	INSERT INTO [dbo].[CustArc_NewActive] (AgentID) VALUES(@AgentID) 
	print @ErrMsg
	return
END

IF EXISTS(select 1 from DBTXN.bodb02.dbo.bettransRNG with (nolock) where recommend = @AgentID)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent just got active trans while processing!', @ErrCode = 101
	INSERT INTO [dbo].[CustArc_NewActive] (AgentID) VALUES(@AgentID) 
	print @ErrMsg
	return
END

print  @AccName +':'+ 'START:' + convert(varchar(50), getdate(), 113)
--=============================
--PERFORM BACKUP DATA MEMBERS
--=============================

select @Now = current_timestamp

--Copy members'info to bodb_Customer 
insert into DBARCCUST.bodb_Customer.dbo.customer_old(
	   [custid],[firstname],[lastname],[address] ,[postal],[city]
      ,[state] ,[country]  ,[phone]   ,[mobilephone] ,[fax]
      ,[email] ,[birthday] ,[refcode1],[refcode2],[remark]
      ,[creatdate],[creator],[username],[currency],[userpwd]
      ,[lastlogged],[pwdexpiry],[roleid],[mrecommend],[recommend]
      ,[ugroup],[logincount],[on_sessionid],[site],[iplogin]
      ,[important],[srecommend],[username2]
)
select [custid],[firstname],[lastname],[address] ,[postal],[city]
      ,[state] ,[country]  ,[phone]   ,[mobilephone] ,[fax]
      ,[email] ,[birthday] ,[refcode1],[refcode2],[remark]
      ,[creatdate],[creator],[username],[currency],[userpwd]
      ,[lastlogged],[pwdexpiry],[roleid],[mrecommend],[recommend]
      ,[ugroup],[logincount],[on_sessionid],[site],[iplogin]
      ,[important],[srecommend],[username2]
from	customer (nolock)
where	custid IN (	select custid from custinfo with (nolock) where roleid = 1 and recommend = @AgentID)

--Copy agent+members' custinfo to bodb_Customer 
insert into DBARCCUST.bodb_Customer.dbo.custinfo_old(
	   [ArchiveDate],
		username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, MatchLimit, 
                      VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12, 
                      maxpermatch99, Enabled, danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino, SyncCasino, danger2, 
                      danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT, MaxPerMatch99MP, DisableBingo, DisableNumber, maxpermatch161, SyncBingo, 
                      MaxPerBall161, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, Disable151_AU, Disable152_UK, 
                      Disable152_AU, Disable153_AU, MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, SyncLiveCasino, 
                      DisableVirtualSports, HideVirtualSports, maxpermatch180, Abnormal, DoubleCommLosing, isAutoResetLiveCasino, MaxWinLiveCasino, 
                      maxpermatch186, maxpermatch181, maxpermatch182, DisableCasinoBonus, maxpermatch184, DisableHRFixedOdds, maxpermatch154, 
                      autosuspend2, maxpermatch183, maxpermatch185, HideKeno, DisableEsports, HideGoldDeluxe, DisableGoldDeluxe, DisableMicrogame, 
                      DisableSuperLive, DisableColossusBet, HideColossusBet, MaxPerMatch44, DisableMicrogameLC, DisableMicrogameRNG, DisableBinaryOptions, 
                      LockUpd
)
select	@Now, 
		username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, MatchLimit, 
                      VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12, 
                      maxpermatch99, Enabled, danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino, SyncCasino, danger2, 
                      danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT, MaxPerMatch99MP, DisableBingo, DisableNumber, maxpermatch161, SyncBingo, 
                      MaxPerBall161, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, Disable151_AU, Disable152_UK, 
                      Disable152_AU, Disable153_AU, MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, SyncLiveCasino, 
                      DisableVirtualSports, HideVirtualSports, maxpermatch180, Abnormal, DoubleCommLosing, isAutoResetLiveCasino, MaxWinLiveCasino, 
                      maxpermatch186, maxpermatch181, maxpermatch182, DisableCasinoBonus, maxpermatch184, DisableHRFixedOdds, maxpermatch154, 
                      autosuspend2, maxpermatch183, maxpermatch185, HideKeno, DisableEsports, HideGoldDeluxe, DisableGoldDeluxe, DisableMicrogame, 
                      DisableSuperLive, DisableColossusBet, HideColossusBet, MaxPerMatch44, DisableMicrogameLC, DisableMicrogameRNG, DisableBinaryOptions, 
                      LockUpd    
from	custinfo (nolock)
where	custid IN (	select custid from custinfo with (nolock) where recommend = @AgentID)

--Copy custSetting data to bodb_Customer before delete
insert into DBARCCUST.bodb_Customer.dbo.custSetting_old(
	custid, 
	bettype, 
	sporttype, 
	apositiontaking, 
	mpositiontaking, 
	spositiontaking, 
	alivepositiontaking, 
	mlivepositiontaking, 
	slivepositiontaking,
	playerdiscount, 
	discount, 
	adiscount, 
	sdiscount, 
	groupa, 
	groupb, 
	groupc, 
	groupd, 
	groupe, 
	groupf, 
	minbet, 
	maxbet, 
	autopositiontaking,
	autolivepositiontaking, 
	isautopositiontaking, 
	isautolivepositiontaking, 
	autompositiontaking, 
	autolivempositiontaking, 
	isautompositiontaking,
	isautolivempositiontaking 
)
select 	custid, 
		bettype, 
		sporttype, 
		apositiontaking, 
		mpositiontaking, 
		spositiontaking, 
		alivepositiontaking, 
		mlivepositiontaking, 
		slivepositiontaking,
		playerdiscount, 
		discount, 
		adiscount, 
		sdiscount, 
		groupa, 
		groupb, 
		groupc, 
		groupd, 
		groupe, 
		groupf, 
		minbet, 
		maxbet, 
		autopositiontaking,
		autolivepositiontaking, 
		isautopositiontaking, 
		isautolivepositiontaking, 
		autompositiontaking, 
		autolivempositiontaking, 
		isautompositiontaking,
		isautolivempositiontaking  
from	custSetting (nolock) 
where	custid IN (	select custid from custinfo with (nolock) where roleid = 1 and recommend = @AgentID)

--Copy custSetting3rd data to bodb_Customer 
insert into DBARCCUST.bodb_Customer.dbo.custSetting3rd_old(
	 [custid]
	,[bettype]
	,[sporttype]
	,[apositiontaking]
	,[mpositiontaking]
	,[spositiontaking]
	,[playerdiscount]
	,[discount]
	,[adiscount]
	,[sdiscount]
	,[minbet]
	,[maxbet]
	,[autopositiontaking]
	,[isautopositiontaking]
	,[autompositiontaking]
	,[isautompositiontaking]
	,[alivepositiontaking]
      ,[mlivepositiontaking]
      ,[slivepositiontaking]
      ,[autolivepositiontaking]
      ,[isautolivepositiontaking]
      ,[autolivempositiontaking]
      ,[isautolivempositiontaking]
) 
SELECT	[custid]
	   ,[bettype]
	   ,[sporttype]
	   ,[apositiontaking]
	   ,[mpositiontaking]
	   ,[spositiontaking]
	   ,[playerdiscount]
	   ,[discount]
	   ,[adiscount]
	   ,[sdiscount]
	   ,[minbet]
	   ,[maxbet]
	   ,[autopositiontaking]
	   ,[isautopositiontaking]
	   ,[autompositiontaking]
	   ,[isautompositiontaking]
	   ,[alivepositiontaking]
      ,[mlivepositiontaking]
      ,[slivepositiontaking]
      ,[autolivepositiontaking]
      ,[isautolivepositiontaking]
      ,[autolivempositiontaking]
      ,[isautolivempositiontaking]
FROM	CustSetting3rd WITH (NOLOCK)
WHERE	custid IN (SELECT custid FROM custInfo WITH (NOLOCK) WHERE roleid = 1 and recommend = @AgentID)		

--- copy DBTRANS.BODB02.dbo.CustSettingGame data to DB05.bodb_Customer.dbo.CustSettingGame_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustSettingGame_Old(
			CustID
			,Bettype
			,Sporttype
			,apositiontaking
			,mpositiontaking
			,spositiontaking
			,playerdiscount
			,discount
			,adiscount
			,sdiscount
			,autopositiontaking
			,isautopositiontaking
			,autompositiontaking
			,isautompositiontaking)
SELECT CustID
		,Bettype
		,Sporttype
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,autopositiontaking
		,isautopositiontaking
		,autompositiontaking
		,isautompositiontaking
FROM [dbo].[CustSettingGame] WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

--- copy DBTRANS.BODB02.dbo.CustGameType data to DB05.bodb_Customer.dbo.CustGameType_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustGameType_Old(CustID, GameTypeID, StakeLevelList, MaxPerGameType, MinBet, MaxBet, IsDisabled)
SELECT CustID, GameTypeID, StakeLevelList, MaxPerGameType, MinBet, MaxBet, IsDisabled
FROM [dbo].CustGameType WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

--- copy DBTRANS.BODB02.dbo.CustVirtualRate data to DB05.bodb_Customer.dbo.CustVirtualRate_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustVirtualRate_Old(custid, sporttype, bettype, isLive, virtualMultiplier)
SELECT custid, sporttype, bettype, isLive, virtualMultiplier
FROM [dbo].CustVirtualRate WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

--- copy DBTRANS.BODB02.dbo.CustVirtualSetting data to DB05.bodb_Customer.dbo.CustVirtualSetting_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustVirtualSetting_Old(custid, seqNo, bitmapVirtual)
SELECT custid, seqNo, bitmapVirtual
FROM [dbo].CustVirtualSetting WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

-- update enable = 0, credit = 0 for whole agent line (use new execRep SP)
Exec Acc_ExecRep_Cust_00 @AgentID = @AgentID, @Type = 0
----------------------------------------------------------------
print  @AccName +':'+ 'END:' + convert(varchar(50), getdate(), 113)

------------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<DBA_ArchiveAccount1_DisableAgentLine AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1))+ '" ' +
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