USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_ChangeCurrency]    Script Date: 06/19/2015 04:39:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.DBA_ChangeCurrency    Script Date: 12/23/2013 4:27:30 PM ******/
ALTER PROCEDURE [dbo].[DBA_ChangeCurrency] 
	@UserName varchar(50),
	@NewCurrency varchar(5),
	@UserID	INT = 360418
AS
--REMEMBER TO CHECK THE RUNNING MIX PARLAY TICKETS
/*
Created: 
Task : Update Super currency: Update all the ticket within that day including bets and transfer trans
DB: DBCUST/CustDB
Original:

Revisions:
	2008-11-22: Add update status disable Horseracing
	- 20090527@Kiwi: + Add checking for for Finance, Horse, Casino
					+ Use function dbo.f_GetHRAllowedCurr()
    - 20091212@Kiwi: Add to write logs
    - 20100205@Daniel: Enable back the check Casino
    - 20101019@Henry: Record execution time + Check Bingo
    - 20101225@Henry: change bettype to new range
    - 20110817@Henry: include Combination Mixed Parlay (bettype = 29)
    - 20111006@Tom:	Add bet type of P2P: 1000
	- 20111226@Thien: not update virtual rate for transfer transaction
	- 20130402@Kiwi: add Dep_custsuper
	- 20130918@Jamie: Racing allowed to all currencies 
	- 20131108@Elodie: Splitting bodb02 into CustDB (Move update bettrans to DBA_ChangeCurrency_Bettrans)
	- 20150619@Daniel: Separate custDB to new server DBCUST [Redmine:#36216]  
	
Param's Explanation: 

*/	
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

Declare @CustID int, @RoleID tinyint, @ExchangeID int, @actualrate float,
		@syncCasino bit,@syncBingo bit, @OldCurrency varchar(5)
select	@CustID = CustID, 
		@RoleID = RoleID,
		@syncCasino = SyncCasino,
		@syncBingo = SyncBingo,
		@OldCurrency = e.currency 
from custinfo ci with (nolock)
inner join exchange e with (nolock) on ci.currency = e.exchangeid
where username = @UserName

/*
---Check Casino
-- Need not to check Disable HR and FI 
if @syncCasino = 1
BEGIN
	raisError ('This customer is already enabled Casino. Cannot Change Currency', 16, 1)
		RETURN
END

if @syncBingo = 1
BEGIN
	raisError ('This customer is already enabled Bingo. Cannot Change Currency', 16, 1)
		RETURN
END

*/
select @ExchangeID = ExchangeID, @actualrate = actualrate
from Exchange with (nolock) where currency = @NewCurrency

if @RoleID = 4
BEGIN
	Update Customer with (updlock,rowlock) set currency = @ExchangeID where srecommend = @CustID
	
	Update Custinfo with (updlock,rowlock) set currency = @ExchangeID where srecommend = @CustID
	
	Update Dep_custsuper with (updlock,rowlock) set currency = @ExchangeID where custid = @CustID
	
	exec DBTXN.bodb02.dbo.DBA_ChangeCurrency_Bettrans @CustID = @CustID, @RoleID = 4, @actualrate = @actualrate, @ExchangeID = @ExchangeID, @NewCurrency = @NewCurrency

END

--Write log

declare @LogSPData nvarchar(200)
Select @LogSPData = '<DBA_ChangeCurrency CustId="' + convert(varchar(30),@CustID)
					 + '" CustName="' + convert(varchar(30), @UserName) 
					 + '" Old="' + convert(varchar(10), @OldCurrency)
					 + '" New="' + convert(varchar(10),@NewCurrency) + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 804,
	@TrackingValue = @LogSPData	,
	@duration = @duration
