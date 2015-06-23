USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_SettleOutright_Undo_Event]    Script Date: 06/23/2015 01:54:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_SettleOutright_Undo_Event]
	@matchid int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: Elodie
Task : sp for Undo outright

DB: DBPRO/BODB02
Original: 

Revisions:
    20150623@Daniel: Restrict ins/upd permission of link server
		
Param's Explanation:
*/
SET NOCOUNT ON

---- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM DBTXN.bodb02.dbo.TempVariableNumber WHERE KeyID = 2 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

DECLARE @Remark VARCHAR(500), @ActionID INT
DECLARE @LogData NVARCHAR(300)
SELECT @ActionID = 140

EXEC DBTXN.bodb02.dbo.NAP_UpdateTempVariableNumber
	@MatchId = @matchid	
	,@ActionId = 1
	,@KeyId = 2
	
IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH			
		SELECT @LogData = 'ADD SUCCESS SPName = DBA_SettleOutright_Undo_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData
	END CATCH
ELSE 
BEGIN
	SELECT @ErrCode = 102, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---------

UPDATE outright  with (updlock,rowlock) 
SET oddsstatus = 'running', status = NULL 
WHERE orid = @matchid

EXEC DBTXN.bodb02.dbo.NAP_UpdateTempVariableNumber
	@MatchId = @matchid	
	,@ActionId = 0
	,@KeyId = 2

IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'DEL SUCCESS SPName = DBA_SettleOutright_Undo_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData	
	END CATCH
END	
ELSE
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = 'DEL FAILED' 
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'DEL FAILED SPName = DBA_SettleOutright_Undo_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC WriteLog_UserLog @UserID = 5838421, --dbaAdmin
							  @Doing = @LogData			
	END CATCH
END

-- WRITE LOG
BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
		@UserID = 5838421, 
		@MatchID = @matchid, 
		@ActionID = @ActionID, 
		@LeagueID = 0, 
		@EventDate = NULL,
		@Result = 'UNDO'
		
END TRY
BEGIN CATCH		
	SELECT @Remark = 'ErrMsg=' + left(error_message(), 400)		
	EXEC DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_SettleOutright 
		@UserID = 5838421, 
		@MatchID = @matchid, 
		@ActionID = @ActionID, 
		@LeagueID = 0, 
		@EventDate = NULL,
		@Result = 'UNDO',
		@Remark = @Remark
END CATCH

