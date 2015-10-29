
CREATE PROCEDURE dbo.DBA_CustSetting_GroupedPTSettingMaintenance
(
	@agentID INT, @Threshold INT = 20
)	
AS
/*
	Created By: Helen
	Created Date: 20151027
	Description: Scripts to maintain PT Group
	
	Param explaination:
		@agentID: recommend
		@Threshold: default 20, it means that it will be re-grouped 
					if number of grouped member is more than 20 percent the current one 
	
	
	EXEC DBA_CustSetting_GroupedPTSettingMaintenance @agentid = 1262, @Threshold = 20

*/	
BEGIN
	SET NOCOUNT ON
		
	CREATE TABLE #tempData (custid int, cs1 bigint, cs2 int)
	
	CREATE TABLE #tempGroup(cs1 bigint, cs2 int, memberCNT int, repCustID int)
	
	SELECT CustID
	INTO #tmpMembers
	FROM CustInfo WITH (NOLOCK) WHERE Recommend = @AgentID AND roleid = 1
	
	;WITH _s as (
		SELECT c.custid	
			,rdSetting = CAST(DENSE_RANK() OVER(ORDER BY sporttype, bettype, islive, superPT, masterPT, agentPT, isAutoMasterPT, AutoMasterPT, isAutoSuperPT, AutoSuperPT) as INT)
			,rdProduct = CAST(DENSE_RANK() OVER(ORDER BY sporttype, bettype, islive) as INT)
		FROM #tmpMembers c WITH(NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Member pt WITH(NOLOCK) ON c.custid = pt.custid		
	)
	
	INSERT INTO #tempdata (custid, cs1, cs2)
	SELECT custid, SUM(CONVERT(bigint,rdSetting) + POWER(2, rdProduct%10+1)), CHECKSUM_AGG(CHECKSUM(HASHBYTES('SHA1', CONVERT(nvarchar(max), rdSetting))))
	FROM _s
	GROUP BY custid

	INSERT INTO #tempGroup(cs1, cs2, memberCNT, repCustID)
	SELECT cs1, cs2, memberCnt, repCustID
	FROM (
		SELECT cs1, cs2, rn = ROW_NUMBER() OVER (ORDER BY count(1) desc), memberCnt = count(1), repCustID = max(custid)
		FROM #tempdata
		GROUP BY cs1, cs2
	) x
	WHERE rn = 1
	
	DECLARE @GroupedPlayers_Current INT
	DECLARE @GroupedPlayers_New INT
	
	SET @GroupedPlayers_Current = (SELECT COUNT(*) 
								  FROM CustSettingMode3rd CS WITH (NOLOCK) 
									JOIN #tmpMembers CI ON CS.CustID = CI.CustID
								  WHERE IsGrouped = 1)
	
	SET @GroupedPlayers_Current = @GroupedPlayers_Current + @GroupedPlayers_Current * @Threshold / 100
	
	SET @GroupedPlayers_New = (SELECT memberCNT FROM #tempGroup)
	
	/* Debug
	
	SELECT @GroupedPlayers_Current, @GroupedPlayers_New
	SELECT * FROM #tempGroup
	SELECT * FROM #tempdata
	
	SELECT DISTINCT sporttype, bettype, islive, superPT, masterPT, agentPT, isAutoMasterPT, AutoMasterPT, isAutoSuperPT, AutoSuperPT  
	FROM CustPTSetting3rd_Member T1  
	  JOIN #tempdata T2 ON T1.CustID = T2.CustID  
	  JOIN #tempGroup T3 ON T3.CS1 = T2.CS1 AND T3.CS2=T2.CS2  
	ORDER BY  sporttype, bettype, islive  


	SELECT DISTINCT sporttype, bettype, islive  
	FROM CustPTSetting3rd_Member T1  
	JOIN #tmpMembers T2 ON T1.CustID = t2.Custid  
	order by sporttype, bettype, islive  
	 
	RETURN
	
	*/
	
	--SELECT @GroupedPlayers_Current, @GroupedPlayers_New
	
	IF @GroupedPlayers_New > = @GroupedPlayers_Current
	BEGIN
			PRINT 'Starting regroup ....'
			
			DECLARE @repCustID INT = (SELECT repCustID FROM #tempGroup)
			IF EXISTS( SELECT 1 
						FROM CustPTGroupSetting3rd_Member T1 WITH (NOLOCK) 
							JOIN  CustPTSetting3rd_Member T2 ON T1.SportType =  T2.SportType AND T1.BetType = T2.BetType AND T1.IsLive = T2.IsLive
																	AND T1.SuperPT = T2.SuperPT AND T1.MasterPT = T2.MasterPT AND T1.AgentPT = T2.AgentPT
																	AND T1.IsAutoMasterPT = T2.IsAutoMasterPT AND T1.AutoMasterPT =  T2.AutoMasterPT 
																	AND T1.IsAutoSuperPT = T2.IsAutoSuperPT	AND T1.AutoSuperPT = T2.AutoSuperPT
						WHERE T1.agentID = @AgentID	AND T2.CustID = @repCustID)
			BEGIN
				PRINT 'Processing for old group and new group has the same setting for this agent ...'
				-- Update isGroup for player
				UPDATE T
				SET IsGrouped = 1
				FROM CustSettingMode3rd T
					JOIN #tempdata T1 ON T1.CustID = T.CustID  
					JOIN #tempGroup T3 ON T3.CS1 = T1.CS1 AND T3.CS2=T1.CS2  
				
				-- Delete individual Setting
				DELETE T
				FROM CustPTSetting3rd_Member T
					JOIN #tempdata T1 ON T1.CustID = T.CustID  
					JOIN #tempGroup T3 ON T3.CS1 = T1.CS1 AND T3.CS2=T1.CS2  
		
			END			
			ELSE
			BEGIN
				PRINT 'Starting creating new group for this agent ...'
				-- Move Old PT Group to individual Setting
				INSERT INTO CustPTSetting3rd_Member
				SELECT  cs.custid,T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT
				FROM CustSettingMode3rd CS WITH (NOLOCK) 
					JOIN #tmpMembers m ON CS.Custid = m.Custid
					JOIN CustPTGroupSetting3rd_Member T1 WITH (NOLOCK) ON T1.AgentID = @AgentID
				WHERE cs.IsGrouped = 1 
				
				UPDATE CSM
					SET IsGrouped = 0
				FROM CustSettingMode3rd CSM
					JOIN #tmpMembers m ON m.CustID = CSM.custid
				WHERE CSM.IsGrouped = 1 
				
				-- Create new Group PT for agent
				DELETE FROM CustPTGroupSetting3rd_Member WHERE AgentID = @AgentID
				
				INSERT INTO CustPTGroupSetting3rd_Member
				SELECT @agentID AS agentID ,
						T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT
				FROM CustPTSetting3rd_Member T1
				WHERE T1.CustID = @repCustID

				-- Delete Individual setting for grouped players 
				DELETE T
				FROM CustPTSetting3rd_Member T
					JOIN #tempdata TempD ON t.Custid = tempD.CustID
					JOIN #tempGroup TempG ON TempG.cs2 = TempD.cs2 AND TempD.cs1 = TempG.cs1
			END	
			
	END
	
	DROP TABLE #TempData
	DROP TABLE #tempGroup
	DROP TABLE #tmpMembers

END