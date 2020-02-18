----################--
--DECLARE @FromDate DATETIME
--	,@ToDate DATETIME

--SET @FromDate = '1/1/20'
--SET @ToDate = '1/31/20'

--select CC.[Business Unit],sum(CC.[Markup Total]) [Sum Charge]
--from
--(
--SELECT BB.*
--	,CASE 
--		WHEN BB.[Markup?] = 'Yes'
--			THEN BB.[Net Amount] * BB.Markup
--		ELSE BB.[Net Amount]
--		END [Markup Total]
--FROM (
--	SELECT AA.*
--		,(
--			SELECT max(m.[Shipping Cost Markup])
--			FROM DEP_BILLING_SHIPPING_RATES m
--			WHERE CASE 
--					WHEN AA.[Business Unit] = m.[Company (RBY for all)]
--						THEN AA.[Business Unit]
--					ELSE 'RBY'
--					END = m.[Company (RBY for all)]
--				AND AA.[Deposco Ship Via] = m.[Ship Via]
--				AND CASE 
--					WHEN AA.[Receiver Country] = m.[Country (blank for all)]
--						THEN AA.[Receiver Country]
--					ELSE ''
--					END = COALESCE(m.[Country (blank for all)], '')
--				AND AA.[Weight] <= m.[Weight Threshold (oz)]
--			) [Markup]
--	FROM (
--		SELECT u.[Charge Category Code]
--			,u.[Charge Classification Code]
--			,u.[Charge Description]
--			,[Lead Shipment Number]
--			,(
--				SELECT max(m.Markup)
--				FROM MarkupYN m
--				WHERE m.[Charge Description] = u.[Charge Description]
--				) [Markup?]
--			,u.[Invoice Date]
--			,(
--				SELECT max(usp.[Billed Weight])
--				FROM [UPS SMALL PACKAGE] usp
--				WHERE usp.[Lead Shipment Number] = u.[Lead Shipment Number]
--				) [Weight]
--			,(
--				SELECT CASE 
--						WHEN max([Ship Via]) LIKE 'ups %'
--							THEN max([Ship Via])
--						ELSE 'UPS Ground' --returns are always UPS Ground (Risky)
--						END
--				FROM Ship s
--				WHERE u.ShipID = s.ShipID
--				) [Deposco Ship Via]
--			,u.[Net Amount]
--			,u.[Business Unit]
--			,u.[Receiver Country]
--		FROM [UPS SMALL PACKAGE] u
--		--JOIN ship ON ship.[Tracking Num] = u.[Ship Track]
--		WHERE u.[Invoice Date] BETWEEN @FromDate
--				AND @ToDate
--			AND (
--				[Charge Category Code] IN (
--					'ADJ'
--					,'RTN'
--					,'GOV'
--					)
--				OR [Charge Classification Code] = 'BRK'
--				)
--			AND u.[Recipient Number] NOT LIKE '0000Y%'
--			--AND u.[Business Unit] <> 'Apex'
--			AND [Net Amount] > 0
--			AND u.[Business Unit] is not null
--			--order by u.[Lead Shipment Number]
--		) AA
--	) BB
--	) CC
--	group by CC.[Business Unit]
----	--where [Lead Shipment Number] = '1ZA066479094051907'
----	--where [Business Unit] = 'cubcoats'
----	--and [Deposct Ship Via] = 'UPS Ground'
----	--and [Lead Shipment Number]='1Z2FE6220393776119'
--GO

--################--
DECLARE @FromDate DATETIME
	,@ToDate DATETIME

SET @FromDate = '1/1/20'
SET @ToDate = '1/31/20'

select CC.[Business Unit],sum(CC.[Markup Total]) [Sum Charge]
from
(
SELECT BB.*
	,CASE 
		WHEN BB.[Markup?] = 'Yes'
			THEN BB.[Net Amount] * BB.Markup
		ELSE BB.[Net Amount]
		END [Markup Total]
FROM (
	SELECT AA.*
		,(
			SELECT max(m.[Shipping Cost Markup])
			FROM DEP_BILLING_SHIPPING_RATES m
			WHERE CASE 
					WHEN AA.[Business Unit] = m.[Company (RBY for all)]
						THEN AA.[Business Unit]
					ELSE 'RBY'
					END = m.[Company (RBY for all)]
				AND AA.[Deposco Ship Via] = m.[Ship Via]
				AND CASE 
					WHEN AA.[Receiver Country] = m.[Country (blank for all)]
						THEN AA.[Receiver Country]
					ELSE ''
					END = COALESCE(m.[Country (blank for all)], '')
				AND AA.[Weight] <= m.[Weight Threshold (oz)]
			) [Markup]
	FROM (
		SELECT u.[Charge Category Code]
			,u.[Charge Classification Code]
			,u.[Charge Description]
			,u.[Sender Name]
			,u.[Sender Company Name]
			,u.[Receiver Name]
			,u.[Receiver Company Name]
			,u.[Shipment Reference Number 1]
			,u.[Shipment Reference Number 2]
			,[Lead Shipment Number]
			,(
				SELECT max(m.Markup)
				FROM MarkupYN m
				WHERE m.[Charge Description] = u.[Charge Description]
				) [Markup?]
			,u.[Invoice Date]
			,(
				SELECT max(usp.[Billed Weight])
				FROM [UPS SMALL PACKAGE] usp
				WHERE usp.[Lead Shipment Number] = u.[Lead Shipment Number]
				) [Weight]
				,(
					SELECT --Next Day Air Commercial
						CASE 
							WHEN max(usp.[Charge Description]) LIKE '%worldwide%saver%'
								THEN 'UPS Worldwide Saver'
							WHEN max(usp.[Charge Description]) LIKE '%worldwide%express%'
								THEN 'UPS Worldwide Express'
							WHEN max(usp.[Charge Description]) LIKE '%worldwide%ddp%'
								THEN 'UPS Worldwide Expedited DDP'
							WHEN max(usp.[Charge Description]) LIKE '%worldwide%'
								THEN 'UPS Worldwide Expedited'
							WHEN max(usp.[Charge Description]) LIKE '%next day%early%'
								THEN 'UPS Next Day Early A.M.'
							WHEN max(usp.[Charge Description]) LIKE '%next day%saver%'
								THEN 'UPS Next Day Air Saver'
							WHEN max(usp.[Charge Description]) LIKE '%next day%'
								THEN 'UPS Next Day Air'
							WHEN max(usp.[Charge Description]) LIKE '%3 day%'
								THEN 'UPS 3-Day Select'
							WHEN max(usp.[Charge Description]) LIKE '%2nd day%air%'
								THEN 'UPS 2nd Day Air'
							WHEN max(usp.[Charge Description]) LIKE '%2nd day%'
								THEN 'UPS 2nd Day'
							WHEN max(usp.[Charge Description]) LIKE '%ground%'
								THEN 'UPS Ground'
							WHEN max(usp.[Charge Description]) LIKE '%surepost%'
								THEN 'UPS SurePost'
							WHEN max(usp.[Charge Description]) LIKE '%standard%'
								THEN 'UPS Standard'
							WHEN max(usp.[Charge Description]) LIKE '%worldwide%'
								THEN 'UPS Worldwide Expedited'
							WHEN max(usp.[Charge Description]) LIKE '%WW Saver%'
								THEN 'UPS Worldwide Saver'
							END
					FROM [UPS SMALL PACKAGE] usp
					WHERE usp.[Lead Shipment Number] = u.[Lead Shipment Number]
						AND (
							usp.[Charge Description] LIKE '%worldwide%'
							OR usp.[Charge Description] LIKE '%next day%'
							OR usp.[Charge Description] LIKE '%3 day%'
							OR usp.[Charge Description] LIKE '%2nd day%'
							OR usp.[Charge Description] LIKE '%ground%'
							OR usp.[Charge Description] LIKE '%surepost%'
							OR usp.[Charge Description] LIKE '%WW Saver%'
							)
					) [Deposco Ship Via]
			,u.[Net Amount]
				,(
					SELECT MAX(LL.bu) FROM (
					SELECT max(bu.[Business Unit]) bu
					-- This lookup is by business unit
					FROM [Business Unit Lookup] bu
					WHERE bu.[Lookup Name] = CASE 
							WHEN u.[Sender Name] =  bu.[Lookup Name]
								THEN bu.[Lookup Name]
							WHEN u.[Sender Company Name]= bu.[Lookup Name] 
								THEN bu.[Lookup Name]
							WHEN u.[Receiver Name]= bu.[Lookup Name]
								THEN bu.[Lookup Name]
							WHEN u.[Receiver Company Name]= bu.[Lookup Name]
								THEN bu.[Lookup Name]
							END
					UNION
					SELECT max(bu.[Business Unit]) bu
					FROM [Code Lookup] bu
					-- This lookup is by business code
					WHERE bu.[Lookup Name] = CASE 	
							WHEN (
								u.[Shipment Reference Number 1] LIKE bu.[Lookup Name] + ' [0-9]%' 
								OR
								u.[Shipment Reference Number 1] LIKE bu.[Lookup Name] + '-[0-9]%' 
								)
								THEN bu.[Lookup Name]
							WHEN (
								u.[Shipment Reference Number 2] LIKE bu.[Lookup Name] + ' [0-9]%' 
								OR
								u.[Shipment Reference Number 2] LIKE bu.[Lookup Name] + '-[0-9]%' 
								)
								THEN bu.[Lookup Name]
							END
					) LL
					) [Business Unit]
			,u.[Receiver Country]
		FROM [UPS SMALL PACKAGE] u
		--JOIN ship ON ship.[Tracking Num] = u.[Ship Track]
		WHERE u.[Invoice Date] BETWEEN @FromDate
				AND @ToDate
			AND (
				[Charge Category Code] IN (
					'ADJ'
					,'RTN'
					,'GOV'
					)
				OR [Charge Classification Code] = 'BRK'
				)
			AND u.[Recipient Number] NOT LIKE '0000Y%'
			--AND u.[Business Unit] <> 'Apex'
			AND [Net Amount] > 0
			AND u.[Business Unit] is  null			
			--order by u.[Lead Shipment Number]
		) AA
	) BB
	) CC
	group by CC.[Business Unit]

GO


