DECLARE @FromDate date
DECLARE @ToDate date
SET @FromDate = '1/1/2020'
SET @ToDate = '1/31/2020'
--Incorrect syntax near the keyword 'with'. If this statement is a common table expression, an xmlnamespaces clause or a change tracking context clause, the previous statement must be terminated with a semicolon.
;
WITH qry
AS (


	SELECT /* us.*
	,ff.* */
		ROW_NUMBER() OVER (
			PARTITION BY us.ShipID ORDER BY us.ShipID
			) RN
		,us.ShipID
		,[Ship Via]
		,Variance
		,[Deposco Weight]
		,[UPS Weight]
		,[Deposco Charge]
		,[Net Amount] [UPS Detail Charge]		
		,[UPS Charge] [UPS Total Charge]
		,[UPS Markup Charge]
		,myn.Markup [MarkupYN]
		,ff.Markup
		,us.[Business Unit]
		,us.[Tracking Number]
		,CASE 
			WHEN [Deposco Charge] = 0
				THEN 'Deposco Error'
			WHEN [Deposco Weight] < [UPS Weight]
				THEN 'Weight Difference'
			ELSE 'Fee incorrectly applied'
			END REASON
		,us.[Charge Description]
	FROM (
		SELECT ee.*
			,[UPS Markup Charge] - [Deposco Charge] [Variance]
		FROM (
			SELECT dd.*
				,(
					/* todo: deal with duty in ups markup charge.  */
					SELECT sum(bb.[Markup Total])
					FROM (
						SELECT CASE 
								WHEN (aa.[Markup?]) = 'Yes'
									THEN (aa.[Net Amount]) * dd.Markup
								ELSE /* No or NULL */ (aa.[Net Amount])
								END [Markup Total]
						FROM (
							SELECT u.[Net Amount]
								,(
									SELECT max(m.Markup)
									FROM MarkupYN m
									WHERE m.[Charge Description] = u.[Charge Description]
									) [Markup?]
							FROM [UPS SMALL PACKAGE] u
							WHERE u.ShipID = dd.ShipID
								AND [Invoice Date] BETWEEN @FromDate
									AND @ToDate
								AND [Charge Category Code] NOT IN (
									'ADJ'
									,'RTN'
									)
								AND [Charge Classification Code] not in ( 'GOV','BRK')
								AND u.[Recipient Number] NOT LIKE '0000Y%'
							) aa
						) bb
					) [UPS Markup Charge]
			FROM (
				SELECT cc.*
					,CASE 
						WHEN cc.[Deposco Scale Weight] > cc.[Deposco Dim Weight]
							THEN cc.[Deposco Scale Weight]
						ELSE cc.[Deposco Dim Weight]
						END [Deposco Weight]
				FROM (
					SELECT bb.*
						,ceiling([Deposco Volume] / BB.[Dim Divisor]) [Deposco Dim Weight]
					FROM (
						SELECT aa.*
							,(
								SELECT dl.[Dim Divisor]
								FROM [Dims Lookup] dl
								WHERE dl.[Ship Via] = CASE 
										WHEN AA.[Ship Via] = 'UPS Surepost'
											AND AA.[Deposco Volume] <= 1728
											AND AA.[UPS Weight] <= 9
											THEN 'UPS Surepost Small'
										WHEN AA.[Ship Via] = 'UPS Surepost'
											AND (
												AA.[Deposco Volume] > 1728
												OR AA.[UPS Weight] > 9
												)
											THEN 'UPS Surepost Large'
										ELSE AA.[Ship Via]
										END
								) [Dim Divisor]
						FROM (
							SELECT s.ShipID
								/*	,[Recipient Number]
									,[Invoice Date]
									,[Invoice Number]
									,[Invoice Amount] */
								,[Ship Track]
								,[Ship Via]
								,s.[Business Unit]
								,u.[Receiver Country]
								,sum([Net Amount]) [UPS Charge]
								,s.[Total Cost] [Deposco Charge]
								,sum(u.[Billed Weight]) [UPS Weight]
								,(
									SELECT sum([Weight])
									FROM cont
									WHERE cont.[Ship ID] = s.ShipID
									) [Deposco Scale Weight]
								,(
									SELECT sum(Height * [Length] * Width)
									FROM cont
									WHERE cont.[Ship ID] = s.ShipID
									) [Deposco Volume]
								,(
									SELECT max(m.[Shipping Cost Markup])
									FROM DEP_BILLING_SHIPPING_RATES m
									WHERE CASE 
											WHEN s.[Business Unit] = m.[Company (RBY for all)]
												THEN s.[Business Unit]
											ELSE 'RBY'
											END = m.[Company (RBY for all)]
										AND s.[Ship Via] = m.[Ship Via]
										AND CASE 
											WHEN u.[Receiver Country] = m.[Country (blank for all)]
												THEN u.[Receiver Country]
											ELSE ''
											END = COALESCE(m.[Country (blank for all)],'')
										AND sum(u.[Billed Weight]) <= m.[Weight Threshold (oz)]
									) [Markup]
							FROM [UPS SMALL PACKAGE] u
							JOIN ship s ON u.ShipID = s.ShipID
							WHERE [Invoice Date] BETWEEN @FromDate
									AND @ToDate
								AND [Charge Category Code] NOT IN (
									'ADJ'
									,'RTN'
									)
								AND [Charge Classification Code] not in ( 'GOV','BRK') /* GOV Should be handled together with ADJ's */
								AND u.[Recipient Number] NOT LIKE '0000Y%'
							--AND s.ShipID = 4464368
							--AND s.ShipID = 4114564
							GROUP BY /*[Recipient Number]
					,[Invoice Date]
					,[Invoice Number]
					,[Invoice Amount] */
								s.ShipID
								,[Ship Track]
								,s.[Ship Via]
								,s.[Business Unit]
								,u.[Receiver Country]
								,s.[Total Cost]
							) aa
						) bb
					) cc
				) dd
			) ee
		) ff
	JOIN [UPS SMALL PACKAGE] us ON ff.ShipID = us.ShipID
		AND us.[Invoice Date] BETWEEN @FromDate
			AND @ToDate
		AND [Charge Category Code] NOT IN (
			'ADJ'
			,'RTN'
			)
		AND us.[Net Amount] > 0
		AND [Charge Classification Code] not in ( 'GOV','BRK')
		AND Variance > .01
	LEFT OUTER JOIN MarkupYN myn ON myn.[Charge Description] = us.[Charge Description]
		--ORDER BY us.ShipID
	)
SELECT DISTINCT RN
	,ShipID
	,[Business Unit]
	,[Ship Via]
	,CASE 
		WHEN RN = 1
			THEN cast([Deposco Weight] AS NVARCHAR(20))
		ELSE ''
		END [Deposco Weight]
	,CASE 
		WHEN RN = 1
			THEN cast([UPS Weight] AS NVARCHAR(20))
		ELSE ''
		END [UPS Weight]
	,qry.[UPS Detail Charge]
	,qry.[Charge Description]
	,CASE 
		WHEN RN = 1
			THEN cast([Deposco Charge] AS NVARCHAR(20))
		ELSE ''
		END [Deposco Charge]
	,CASE 
		WHEN RN = 1
			THEN cast([UPS Total Charge] AS NVARCHAR(20))
		ELSE ''
		END [UPS Total Charge]
	,CASE 
		WHEN RN = 1
			THEN cast([UPS Markup Charge] AS NVARCHAR(20))
		ELSE ''
		END [UPS Markup Charge]
	,qry.[Markup]
	,qry.[MarkupYN]
	,CASE 
		WHEN RN = 1
			THEN cast(Variance AS NVARCHAR(20))
		ELSE ''
		END [Variance]
	,CASE 
		WHEN RN = 1
			THEN REASON
		ELSE ''
		END [REASON]	
	,qry.[Tracking Number]
FROM qry
ORDER BY ShipID
	,RN
