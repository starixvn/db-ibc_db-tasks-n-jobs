ALTER PROCEDURE [dbo].[DBA_ArchiveAccount2_CustomerInsert]
	@AgentID INT,	
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created: 20150619@Daniel
	Task: Archive unused Account - sp insert data from DBCUST 
	DB: DBARCCUST/bodb_customer
	
	Revisions:
		- 20150619@Daniel: 
		  + No more allow ins/upd data directly via Linked-server => call this SP in DBCUST
		  
*/
SET NOCOUNT ON

--==========================================================
--CREATING TEMP TABLES
--==========================================================

CREATE TABLE #Member 
(
	custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int,
	membername varchar(50), agentname varchar(50), mastername varchar(50), supername varchar(50)
)
		
INSERT INTO #Member (custid)
SELECT c.custid
FROM DBCUST.custDB.dbo.custinfo c (nolock)
WHERE  c.recommend = @AgentID AND c.roleid = 1
	
	
--=============================
--PERFORM COPY MEMBERS
--=============================

DECLARE @Now datetime
select @Now = current_timestamp

insert into dbo.customer_old(
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
from	DBCUST.custDB.dbo.customer WITH(nolock) where custid IN (select custid from #Member with (nolock))
IF @@Error<>0
BEGIN
	Select	@ErrMsg = 'Failed INSERT from CUSTOMER table to CUSTOMER_OLD table', 
			@ErrCode = 102
	return
END 

insert into dbo.custinfo_old(
		[ArchiveDate],
		username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, 
		MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, 
		maxpermatch12, maxpermatch99, Enabled, danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino, 
		SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT, MaxPerMatch99MP, DisableBingo, DisableNumber, maxpermatch161, SyncBingo, 
		MaxPerBall161, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, 
		Disable151_AU, Disable152_UK, Disable152_AU, Disable153_AU, MaxTransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, 
		SyncLiveCasino, maxpermatch180, DisableVirtualSports, HideVirtualSports, Abnormal, isAutoResetLiveCasino, 
		MaxWinLiveCasino, DoubleCommLosing, maxpermatch186, maxpermatch181, maxpermatch182, DisableCasinoBonus, maxpermatch184, 
		DisableHRFixedOdds, maxpermatch154, autosuspend2, maxpermatch183, maxpermatch185, 
		HideKeno, maxpermatch203, DisableEsports, HideGoldDeluxe, DisableGoldDeluxe
)
select	@Now, 
		username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, 
		MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, 
		maxpermatch12, maxpermatch99, Enabled, danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino, 
		SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT, MaxPerMatch99MP, DisableBingo, DisableNumber, maxpermatch161, SyncBingo, 
		MaxPerBall161, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, 
		Disable151_AU, Disable152_UK, Disable152_AU, Disable153_AU, MaxTransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, 
		SyncLiveCasino, maxpermatch180, DisableVirtualSports, HideVirtualSports, Abnormal, isAutoResetLiveCasino, 
		MaxWinLiveCasino, DoubleCommLosing, maxpermatch186, maxpermatch181, maxpermatch182, DisableCasinoBonus, maxpermatch184, 
		DisableHRFixedOdds, maxpermatch154, autosuspend2, maxpermatch183, maxpermatch185, 
		HideKeno, maxpermatch203, DisableEsports, HideGoldDeluxe, DisableGoldDeluxe  			     
from	DBCUST.custDB.dbo.custinfo WITH(nolock) where custid IN (select custid from #Member with (nolock))
IF @@Error<>0
BEGIN
	Select	@ErrMsg = 'Failed INSERT from CUSTINFO table to CUSTINFO_OLD table', 
			@ErrCode = 103
	return
END 

DROP TABLE #Member