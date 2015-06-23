ALTER PROCEDURE [dbo].[DBA_InsertMemberBATicket_UpdBetPT]
	@custID INT
AS
/*
	Created by: 20150623@Daniel for Separate custDB to new server DBCUST [Redmine:#36216]
	Task: Insert Member BA Ticket (Dela problem) - update PT for tickets
	DB: DBTXN/bodb02
	
	Revisions:
	
*/
SET NOCOUNT ON

UPDATE dbo.bettrans WITH (ROWLOCK,UPDLOCK)
SET tpositiontaking=0,
	apositiontaking=0,
	awinlost=0
WHERE 
	custid = @CustID
	and (bettype <31 or bettype between 121 AND 999)
	and tpositiontaking<>0