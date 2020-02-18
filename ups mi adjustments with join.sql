--select top 100 * from [UPS MI] u
--join Ship s
--on u.ShipID = s.ShipID
--join CONT c
--on s.ShipID = c.[Ship ID]
--where u.[Stmt Date] 
--between '11/1/19' and '11/30/19'
GO

DECLARE @FromDate DATE
DECLARE @ToDate DATE

SET @FromDate = '1/1/20'
SET @ToDate = '1/31/20'

SELECT BB.*
	,cast(BB.[DEPOSCO SHOULD CHARGE BASED ON UPS WEIGHT LOGS] - [Deposco Charge] as money ) [Adjustment Charge]
	,CASE 
		WHEN [Deposco Charge] = 0
			THEN 'Fee Not Applied'
		WHEN [UPS Weight] = [Deposco Weight]
			THEN 'Fee Incorrectly Applied'
		ELSE 'Weight Discrepancy'
		END [Reason]
FROM (
	SELECT AA.*
		--,(
		--	SELECT max([Price Per Package])
		--	FROM DEP_BILLING_SHIPPING_RATES m
		--	WHERE CASE 
		--			WHEN AA.[Business Unit] = m.[Company (RBY for all)]
		--				THEN AA.[Business Unit]
		--			ELSE 'RBY'
		--			END = m.[Company (RBY for all)]
		--		AND AA.[Ship Via] = m.[Ship Via]
		--		AND ceiling(m.[Weight Threshold (oz)]) = (AA.[UPS Weight])
		--	) [DEPOSCO SHOULD CHARGE BASED ON UPS WEIGHT NOT LOGS]
		--,(
		--	SELECT max([Price Per Package])
		--	FROM DEP_BILLING_SHIPPING_RATES m
		--	WHERE CASE 
		--			WHEN AA.[Business Unit] = m.[Company (RBY for all)]
		--				THEN AA.[Business Unit]
		--			ELSE 'RBY'
		--			END = m.[Company (RBY for all)]
		--		AND AA.[Ship Via] = m.[Ship Via]
		--		AND ceiling(m.[Weight Threshold (oz)]) = (AA.[Deposco Weight])
		--	) [DEPOSCO SHOULD CHARGE BASED ON DEPOSCO WEIGHT NOT LOGS]
		,(
			SELECT MAX(tt.[To Value])
			FROM [Billing Shipping Rates Logs] tt
			WHERE ID = (
					SELECT MIN(ID)
					FROM DEP_BILLING_SHIPPING_RATES m
					WHERE CASE 
							WHEN AA.[Business Unit] = m.[Company (RBY for all)]
								THEN AA.[Business Unit]
							ELSE 'RBY'
							END = m.[Company (RBY for all)]
						AND AA.[Ship Via] = m.[Ship Via]
						AND ceiling(m.[Weight Threshold (oz)]) = (AA.[UPS Weight])
					)
				AND tt.[Modified Field] = 'Price Per Package'
				AND tt.[Audit Date] <= AA.[Transaction Date ]
			) [DEPOSCO SHOULD CHARGE BASED ON UPS WEIGHT LOGS]
		,(
			SELECT MAX(tt.[To Value])
			FROM [Billing Shipping Rates Logs] tt
			WHERE ID = (
					SELECT MIN(ID)
					FROM DEP_BILLING_SHIPPING_RATES m
					WHERE CASE 
							WHEN AA.[Business Unit] = m.[Company (RBY for all)]
								THEN AA.[Business Unit]
							ELSE 'RBY'
							END = m.[Company (RBY for all)]
						AND AA.[Ship Via] = m.[Ship Via]
						AND ceiling(m.[Weight Threshold (oz)]) = (AA.[Deposco Weight])
					)
				AND tt.[Modified Field] = 'Price Per Package'
				AND tt.[Audit Date] <= AA.[Transaction Date ]
			) [DEPOSCO SHOULD CHARGE BASED ON DEPOSCO WEIGHT LOGS]
	FROM (
		SELECT s.ShipID
			,u.[Transaction Date ]
			,[Ship Track]
			,[Ship Via]
			,s.[Business Unit]
			,sum([Total Chgs Billed]) [UPS Charge]
			,s.[Total Cost] [Deposco Charge]
			,ceiling(sum(u.[Billed Wt])) [UPS Weight]
			,(
				SELECT ceiling(sum([Weight]) * 16)
				FROM cont
				WHERE cont.[Ship ID] = s.ShipID
				) [Deposco Weight]
		FROM [UPS MI] u
		JOIN ship s ON u.ShipID = s.ShipID
		WHERE [Stmt Date] BETWEEN @FromDate
				AND @ToDate
		GROUP BY s.ShipID
			,[Ship Track]
			,s.[Ship Via]
			,s.[Business Unit]
			,s.[Total Cost]
			,u.[Billed Wt]
			,u.[Transaction Date ]
			,u.[USPS PIC Delivery Conf]
		) AA
	) BB
WHERE ([Deposco Charge] < [DEPOSCO SHOULD CHARGE BASED ON UPS WEIGHT LOGS]
OR [DEPOSCO SHOULD CHARGE BASED ON UPS WEIGHT LOGS] is null) -- check these.)
AND [Business Unit] <> 'LuxyHair' -- added by O'M
--and ShipID = 5272888

--select * from [UPS MI]
--where [USPS PIC Delivery Conf] in ('92748963438920543400748526'
--,'92748963438920543475756624')

