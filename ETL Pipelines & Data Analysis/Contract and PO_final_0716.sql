WITH 
-- extract Supplier Name description from Address Table F0101
cte1 as (
  -- select [ABAN8], [ABALPH], CAST(ABAN8 AS VARCHAR(20)) + ' - ' + [ABALPH] AS Description
    select [ABAN8], [ABALPH], format([ABAN8],'0') + ' - ' + [ABALPH] AS Description

  from [JDE_PRODUCTION].[PRODDTA].[F0101]
),

Plant as (
  select [MCMCU], [MCDL01], cast([MCMCU] as varchar) + ' - ' + [MCDL01] AS Description
  from [JDE_PRODUCTION].[PRODDTA].[F0006]
),
-- Order Type description table F0005
OrTy as (
      select  LTRIM(DRKY) as DRKY,  LTRIM(DRKY) + ' - ' + [DRDL01] AS OrTyDesc
      FROM [JDE_PRODUCTION].[PRODCTL].[F0005]
    WHERE DRSY = '00' AND DRRT = 'DT' AND LTRIM(DRKY) in ('GR', 'OC', 'OG', 'OP', 'OS', 'OE', 'OJ', 'O4', 'OB', 'OL')
),
-- Contract Type description table F0005
ConTy as (
    SELECT LTRIM(rtrim(DRKY)) as DRKY,  LTRIM(rtrim(DRKY)) + ' - ' + [DRDL01] AS ConTyDesc
    FROM [JDE_PRODUCTION].[PRODCTL].[F0005]
  WHERE DRSY = '41' AND DRRT = 'P5' 
),
-- Price Group description table F0005
PriceGp as (
   SELECT LTRIM(rtrim(DRKY)) as DRKY,  LTRIM(rtrim(DRKY)) + ' - ' + [DRDL01] AS PriceGpDesc
    FROM [JDE_PRODUCTION].[PRODCTL].[F0005]
  WHERE DRSY = '40' AND DRRT = 'PC'   
),
ServiceCd as (
SELECT LTRIM(rtrim(DRKY)) as DRKY,  LTRIM(rtrim(DRKY)) + ' - ' + [DRDL01] AS ServiceCdDesc
    FROM [JDE_PRODUCTION].[PRODCTL].[F0005]
  WHERE DRSY = '40' AND DRRT = 'AS'   
)

SELECT  
[PHAN8] as 'Supplier Number',  --to delete
SupName.[Description] as 'Supplier'  ---supplierID
-- ,[PHORBY] as 'Ordered By'  --to delete
, [PHANBY] as 'Buyer Number' --to delete
,BuyerName.[ABALPH] as 'Ordered By'

-- BuyerName.[Description] as "Buyer" ---Buyer Login as UserID in 0092, then F0101 to get description?
,[PHMCU] as 'PHMCU_Business Unit' --to delete
-- -- 'Branch Plant' changes to 'Branch Plant/ Dept' as per dashboard steps
,Plant.[Description] as "Branch Plant/ Dept" 
	-- ,[PHDCTO] as 'Order Type' --to delete
, OrTy.[OrTyDesc] as 'Order Type' 
, ConTy.[ConTyDesc] as 'Contract Type'
, PriceGp.[PriceGpDesc] as 'Competitive Process'
, [PHPOHC01] as 'Funding Source'
-- 'Order No. - Header' changes to 'Order No' as per dashboard steps
, [PHDOCO] as 'Order No.'
, [PDSFXO] as 'Change Order Number'
, [PHDESC] as 'Description'
, [PHVR01] as 'Reference'
, [PHVR02] as 'Description - Reference 2'
-- 'Name - Remark' changes to 'Remark' as per dashboard steps
, [PHRMK] as 'Remark'
, ServiceCd.[ServiceCdDesc] as 'Service Code'
, PDetail.[PDTX] as 'Purchasing Taxable (Y/N)'
-- , PHeader.[PHTRDJ] as 'PHTRDJ_Effective Date' --to delete
, DATEADD(DAY, (PHeader.[PHTRDJ] % 1000) - 1, 
              DATEFROMPARTS( (PHeader.[PHTRDJ] / 1000) + 1900, 1, 1)) AS 'Effective Date'
, CASE 
   WHEN PHeader.[PHCNDJ] = 0 THEN NULL
    ELSE 
      -- Convert CYYDDD to proper date
      DATEADD(DAY, (PHeader.[PHCNDJ] % 1000) - 1, 
              DATEFROMPARTS( (PHeader.[PHCNDJ] / 1000) + 1900, 1, 1))
  END AS 'Expiration Date' 
, CAST(PDetail.[PDAEXP] as float) / 100 as 'PO Amount (not including tax)'
, CAST(PDetail.[PDFTN1] as float) / 100 as 'Amount - Tax Commitment' 
, (CAST(PDetail.[PDAEXP] as float) / 100 + CAST(PDetail.[PDFTN1] as float) / 100) as 'Total PO Amount including tax'
--   Amount Relieved  Column + Tax Relieved  Column
, (CAST(PDetail.[PDARLV] as float) / 100 + CAST(PDetail.[PDTRLV] as float) / 100) as 'Total Spend' ---check it match? sorted column
, CAST(PDetail.[PDAOPN] as float) / 100 as 'Amount Remaining'
, PDetail.[PDANI] as 'Account Number'


-- , CASE 
--     WHEN PHCNDJ = 0 THEN NULL
--     ELSE 
--       -- Convert CYYDDD to proper date
--       DATEADD(DAY, (PHCNDJ % 1000) - 1, 
--               DATEFROMPARTS( (PHCNDJ / 1000) + 1900, 1, 1))
--   END AS PHCNDJ_DATE
-- --   Supplier (CALC_3) - F4301.AN8   
-- CAST(PHeader.PHAN8 AS VARCHAR) + ' - ' + cte1.[ALPH] AS Supplier

FROM [JDE_PRODUCTION].[PRODDTA].[F4301] as PHeader
INNER JOIN [JDE_PRODUCTION].[PRODDTA].[F4311] as PDetail
-- Join info from Design note
  ON PHeader.[PHDCTO] = PDetail.[PDDCTO]
 AND PHeader.[PHDOCO] = PDetail.[PDDOCO]

-- Join to get Supplier Name
LEFT JOIN cte1 as SupName ON PHeader.PHAN8 = SupName.ABAN8 

-- Join to get Buyer Name (Ordered By) buyerNumber matched F0101.ABAN8 and return F0101.ABALPH
LEFT JOIN cte1 as BuyerName ON PHeader.PHANBY = BuyerName.ABAN8  

-- -- Join to get column name "Buyer" (Buyer Login)
LEFT JOIN [JDE920].[SY920].[F0092] AS LoginID ON PHeader.PHORBY COLLATE SQL_Latin1_General_CP1_CI_AS = LoginID.ULUSER 
-- -- Join to get Buyer (Buyer Login)
LEFT JOIN cte1 as Branch ON LoginID.ULAN8 = Branch.[ABAN8] 

-- -- Join to get Branch Plant
LEFT JOIN Plant ON PHeader.[PHMCU] = Plant.[MCMCU] 

-- Join to get Order Type description (F4301.PHDCTO ordertype & F0005.DRKY)
LEFT JOIN OrTy ON PHeader.[PHDCTO] = OrTy.[DRKY]

-- Join to get Contract Type description (F4301.PRP5 Cotract type & F0005.DRKY)
LEFT JOIN ConTy ON PHeader.[PHPRP5] = ConTy.[DRKY]

-- Join to get Contract Type description (F4301.PHPRGP Price Group & F0005.DRKY)
LEFT JOIN PriceGp ON PHeader.[PHPRGP] = PriceGp.[DRKY]

-- Join to get Service Code description (F4301.PHPRGP Price Group & F0005.DRKY)
LEFT JOIN ServiceCd ON PHeader.[PHASN] = ServiceCd.[DRKY]

 where PHeader.[PHDCTO] in ('GR', 'OC', 'OG', 'OP', 'OS', 'OE', 'OJ', 'O4', 'OB', 'OL')
 AND PDetail.[PDLTTR] != 980
--  Expiration Date =  | Expiration Date > 12/31/22
 AND (PHeader.PHCNDJ = 0 OR PHeader.[PHCNDJ] > 122365)
  
 --  --Order sequence for output comparision with excel 
ORDER BY PHeader.[PHDOCO], OrTy.[OrTyDesc], 
SupName.[Description], 
[Effective Date], ConTy.[ConTyDesc], [Remark]
--, BuyerName.[Description]

