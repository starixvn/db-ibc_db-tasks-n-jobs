ALTER PROCEDURE [dbo].[DBA_Lrf_ChangeLicenseeName_Bets]
    @OldLicenseeName VARCHAR(100),
    @NewLicenseeName VARCHAR(100)
AS
/*
	Create by : 20150623@Daniel for Migrate custDB to new server DBCUST #36216
	Task : Change licensee/ site name - update tickets
	DB: DBTXN/bodb02
	Param's Explanation: 
			*@OldLicenseeName :string, Licensee whose need to rename
			*NewLicenseeName: string,new licensee name 
	Revision:
*/	
	

CREATE TABLE #tblCust (CustID INT, username VARCHAR(100),username2 VARCHAR(100),roleid INT)

INSERT INTO #tblCust
SELECT 	custid
		,replace(username,@OldLicenseeName,@NewLicenseeName) username
		,replace(username2,@OldLicenseeName,@NewLicenseeName) username2
		,roleid 
FROM custDB.dbo.Customer WITH (NOLOCK)
WHERE  srecommend in (SELECT custid FROM custDB.dbo.Dep_CustSuper WITH (NOLOCK) WHERE site=@OldLicenseeName)
--- bettrans
UPDATE dbo.bettrans WITH (rowlock,updlock)
SET username=s.username
FROM dbo.bettrans d
INNER JOIN #tblCust  s
ON s.custid=d.custid 
--- bettrans14
UPDATE  dbo.bettrans14 WITH (rowlock,updlock)
SET username=s.username
FROM dbo.bettrans14 d
INNER JOIN #tblCust  s
ON s.custid=d.custid 

--------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE #tblCust
--------------------------------------------------------------------------------------------------------------------------------------------


