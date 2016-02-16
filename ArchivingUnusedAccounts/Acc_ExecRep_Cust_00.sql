ALTER PROCEDURE [dbo].[Acc_ExecRep_Cust_00]
	@AgentID	INT,
	@Type		BIT = 0 
WITH RECOMPILE	
AS 
/*
	Created by: Daniel
	Date: 2015-01-12
	Task: For archive Acc (New) - update/delete part in stage 1,2,3 
	DB: DBCUST/CustDB
	Original: Acc_ExecRep_Cust_01
	Revision:

	Param's Explanation:
		@Type: 
			+ 0-Stage 1: update enable = 0 & credit = 0 for whole agent line
			+ 1-Stage 2: Delete cust setting for members under agent
			+ 2-Stage 3: Delete cust info for members under agent
			
 
*/
BEGIN
	IF @Type = 0 
	BEGIN 
		IF dbo.f_CheckRepTable('Custinfo') = 0
			RETURN
		ELSE 
		BEGIN
			WHILE (1=1)
			BEGIN 
				UPDATE TOP(10000) dbo.Custinfo WITH (UPDLOCK,ROWLOCK)
				SET		[enabled] = 0, closed = 1, credit = 0
				WHERE	recommend = @AgentID AND ([enabled] = 1 OR closed = 0) 
				IF @@ROWCOUNT < 10000
					BREAK
			END 
		END 
	END	
	ELSE IF @Type = 1
	BEGIN
		IF dbo.f_CheckRepTable('CustVirtualRate') = 1
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE TOP(10000) 
				FROM dbo.CustVirtualRate WITH(ROWLOCK,UPDLOCK)	
				WHERE custid IN (SELECT custid 
								 FROM custinfo WITH(NOLOCK) 
								 WHERE roleid = 1 AND recommend = @AgentID
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END

		IF dbo.f_CheckRepTable('CustVirtualSetting') = 1
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE TOP(10000)
				FROM dbo.CustVirtualSetting WITH(ROWLOCK,UPDLOCK)
				WHERE custid IN (SELECT custid 
								 FROM custinfo WITH(NOLOCK) 
								 WHERE roleid = 1 AND recommend = @AgentID
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END


	     IF (dbo.f_CheckRepTable('CustSetting') = 1 
		  AND dbo.f_CheckRepTable('CustSetting3rd') = 1 
	     )
		BEGIN
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.CustSetting WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) WHERE roleid = 1 AND recommend = @AgentID)
						
				IF @@ROWCOUNT < 10000 
					BREAK
			END
			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.CustSetting3rd WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) WHERE roleid = 1 AND recommend = @AgentID)
							
				IF @@ROWCOUNT < 10000
					BREAK			
			END
		END
	
	     IF (dbo.f_CheckRepTable('P2PGameSetting') = 1 
		  AND dbo.f_CheckRepTable('P2PGroupComm') = 1 
	     )
		BEGIN			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[P2PGameSetting] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
									WHERE roleid = 1 
										AND recommend = @AgentID
										)
				IF @@ROWCOUNT < 10000 
					BREAK
			END			
			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[P2PGroupComm] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
										WHERE roleid = 1 
											AND recommend = @AgentID
											)
				IF @@ROWCOUNT < 10000 
					BREAK
			END				
		END		

	     IF (dbo.f_CheckRepTable('CustSettingGame') = 1 
		  AND dbo.f_CheckRepTable('CustGameType') = 1 
	     )
		BEGIN			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[CustSettingGame] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
									WHERE roleid = 1 
										AND recommend = @AgentID
										)
				IF @@ROWCOUNT < 10000 
					BREAK
			END			
			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[CustGameType] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
										WHERE roleid = 1 
											AND recommend = @AgentID
											)
				IF @@ROWCOUNT < 10000 
					BREAK
			END				
		END	
	END 
	ELSE IF @Type = 2
	BEGIN
		IF @@SERVERNAME = 'DBTRANS'
		BEGIN
			IF dbo.f_CheckRepTable('BalCreditSports') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditSports WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitSports') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitSports WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
			IF dbo.f_CheckRepTable('BalCreditCasino') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditCasino WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitCasino') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitCasino WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
			IF dbo.f_CheckRepTable('BalCreditOthers') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditOthers WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitOthers') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitOthers WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
			IF dbo.f_CheckRepTable('BalCreditTransfer') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditTransfer WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitTransfer') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitTransfer WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
		END
				
	     IF (dbo.f_CheckRepTable('Custinfo') = 1 
		  AND dbo.f_CheckRepTable('Customer') = 1 
	     )
		BEGIN
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.Custinfo WITH (UPDLOCK,ROWLOCK)
				WHERE	roleid = 1 AND recommend = @AgentID 
				IF @@ROWCOUNT < 10000
					BREAK

			END 
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.Customer WITH (UPDLOCK,ROWLOCK)
				WHERE	roleid = 1 AND recommend = @AgentID 
				IF @@ROWCOUNT < 10000
					BREAK			
			END
		END
		
	END 
END