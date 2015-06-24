ALTER PROCEDURE [dbo].[DBA_CustomerDel_Bets]
	@srecommend INT
AS
/*
Created: 20150622@Daniel
Task : Delete trans of customer(super)
DB: DBTXN/bodb02
Original:

Revisions:

*/		
delete bodb02.dbo.bettrans where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)
delete bodb02.dbo.bettrans14 where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)

delete bodb02.dbo.bettransG where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)
delete bodb02.dbo.bettransG14 where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)

delete bodb02.dbo.bettransM where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)
delete bodb02.dbo.bettransM14 where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)

delete bodb02.dbo.sum_winloss where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)

delete bodb02.dbo.zzzbettrans where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)	
delete bodb02.dbo.zzzbettransm where custid in (select custid from custinfo with (NOLOCK) where srecommend = @srecommend)