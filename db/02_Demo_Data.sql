/* ============================================================================
   SalesBuzz demo dataset  --  SUPSEAL Nutrition (supplement distributor)
   ----------------------------------------------------------------------------
   Domain story (mirrors the SalesBuzz overview doc):
     A supplements distributor selling to gyms and supplement shops in Egypt.
     3 salesmen cover Cairo East / Cairo West & Giza / Delta & Alexandria.

   IMPORTANT - order dates are RELATIVE to GETDATE(), never hard-coded, so the
   dataset keeps telling the same story no matter when it is re-seeded. The
   customer behaviour below is deliberately shaped to exercise the alert rules:

     Gold Gym Nasr City      -> silent 48 days   (lost-customer alert)
     Body Center Zamalek     -> silent 65 days   (lost-customer alert)
     Vital Nutrition Tanta   -> silent 38 days   (lost-customer alert)
     Power House Heliopolis  -> revenue -60%     (sales-drop alert)
     Supplement World Oct.   -> revenue -55%     (sales-drop alert)
     the rest                -> ordering normally (must NOT alert)

   Idempotent: safe to re-run. Re-running rebuilds the order history so the
   relative dates slide forward with the current date.
   ============================================================================ */

USE [MO_ASHRAF];
GO
SET NOCOUNT ON;
-- Required for the PERSISTED computed column on HH_SalesOrderDetail: sqlcmd
-- defaults QUOTED_IDENTIFIER to OFF, and CREATE TABLE with a computed column
-- refuses to run under that setting.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ---------------------------------------------------------------- salesmen */
IF NOT EXISTS (SELECT 1 FROM HH_AR_SalesmenCats WHERE CategoryId = N'CAT-VAN')
    INSERT INTO HH_AR_SalesmenCats (CategoryId, Description, ArabicDescription, buid, RecordSource, CreatedOn, Createdby)
    VALUES (N'CAT-VAN', N'Van Sales', N'بيع مباشر', N'C100', 1, GETDATE(), N'seed');

IF NOT EXISTS (SELECT 1 FROM HH_AR_SalesmenCats WHERE CategoryId = N'CAT-PRE')
    INSERT INTO HH_AR_SalesmenCats (CategoryId, Description, ArabicDescription, buid, RecordSource, CreatedOn, Createdby)
    VALUES (N'CAT-PRE', N'Pre Sales', N'بيع بالطلب', N'C100', 1, GETDATE(), N'seed');

MERGE HH_Salesman AS t
USING (VALUES
    (N'SM01', N'Ahmed Mostafa',  N'أحمد مصطفى',  N'CAT-PRE', N'Cairo East'),
    (N'SM02', N'Mahmoud Khaled', N'محمود خالد',  N'CAT-PRE', N'Giza & West Cairo'),
    (N'SM03', N'Youssef Ibrahim',N'يوسف إبراهيم',N'CAT-VAN', N'Delta & Alexandria')
) AS s (SalesmanNo, SalesmanNameE, SalesmanNameA, CategoryId, WareHouse)
    ON t.SalesmanNo = s.SalesmanNo
WHEN NOT MATCHED THEN
    INSERT (SalesmanNo, SalesmanNameE, SalesmanNameA, CategoryId, BUID, BranchNo, SalesManType, IsUser, WareHouse, CreatedOn, Createdby)
    VALUES (s.SalesmanNo, s.SalesmanNameE, s.SalesmanNameA, s.CategoryId, N'C100', N'BR01', 1, 0, s.WareHouse, GETDATE(), N'seed');
GO

/* ------------------------------------------------------------------- items */
IF NOT EXISTS (SELECT 1 FROM HH_IC_UOMDetail WHERE UOMID = N'PCS')
    INSERT INTO HH_IC_UOMDetail (UOMID, LinkedUOM, Factor, MultiplyDivide, buid, RecordSource, CreatedOn, Createdby)
    VALUES (N'PCS', N'PCS', 1, 1, N'C100', 1, GETDATE(), N'seed');

IF NOT EXISTS (SELECT 1 FROM HH_IC_UOMDetail WHERE UOMID = N'BOX')
    INSERT INTO HH_IC_UOMDetail (UOMID, LinkedUOM, Factor, MultiplyDivide, buid, RecordSource, CreatedOn, Createdby)
    VALUES (N'BOX', N'PCS', 12, 1, N'C100', 1, GETDATE(), N'seed');

MERGE HH_Item AS t
USING (VALUES
    (N'ITM-WHEY-2K',  N'Whey Protein 2kg',          N'واي بروتين 2 كجم',        N'BRD-SUP', N'GRP-PROTEIN'),
    (N'ITM-CREA-300', N'Creatine Monohydrate 300g', N'كرياتين مونوهيدرات 300 جم',N'BRD-SUP', N'GRP-PERF'),
    (N'ITM-BCAA-400', N'BCAA 400g',                 N'بي سي إيه إيه 400 جم',    N'BRD-SUP', N'GRP-PERF'),
    (N'ITM-PREW-300', N'Pre-Workout 300g',          N'بري وورك أوت 300 جم',     N'BRD-SUP', N'GRP-PERF'),
    (N'ITM-GAIN-3K',  N'Mass Gainer 3kg',           N'ماس جينر 3 كجم',          N'BRD-SUP', N'GRP-PROTEIN'),
    (N'ITM-OMG3-100', N'Omega 3 - 100 caps',        N'أوميجا 3 - 100 كبسولة',   N'BRD-VIT', N'GRP-VITAMIN')
) AS s (ItemNo, ItemNameE, ItemNameA, BrandNo, GroupID)
    ON t.ItemNo = s.ItemNo
WHEN NOT MATCHED THEN
    INSERT (ItemNo, ItemNameE, ItemNameA, DefaultUOM, BrandNo, GroupID, CategoryID, buid,
            barcode1, barcode2, Type, SalesUOM, SmallUOM, LargeUOM, RecordSource, EnableReturn, CreatedOn, Createdby)
    VALUES (s.ItemNo, s.ItemNameE, s.ItemNameA, N'PCS', s.BrandNo, s.GroupID, N'CAT-SUPP', N'C100',
            s.ItemNo, s.ItemNo, 1, N'PCS', N'PCS', N'BOX', 1, 1, GETDATE(), N'seed');
GO

/* --------------------------------------------------------------- customers */
MERGE HH_Customer AS t
USING (VALUES
    (N'CUS0001', N'Gold Gym Nasr City',        N'جولد جيم مدينة نصر',      N'SM01', N'010 1122 3301', N'12 Abbas El Akkad St., Nasr City, Cairo',      30.0566, 31.3450, 0),
    (N'CUS0002', N'Fitness First Maadi',       N'فيتنس فيرست المعادي',     N'SM01', N'010 1122 3302', N'45 Road 9, Maadi, Cairo',                      29.9603, 31.2570, 0),
    (N'CUS0003', N'Power House Heliopolis',    N'باور هاوس مصر الجديدة',   N'SM01', N'010 1122 3303', N'8 El Merghany St., Heliopolis, Cairo',         30.0876, 31.3260, 0),
    (N'CUS0004', N'Muscle Shop Dokki',         N'ماسل شوب الدقي',          N'SM02', N'010 1122 3304', N'22 Tahrir St., Dokki, Giza',                   30.0387, 31.2110, 0),
    (N'CUS0005', N'Body Center Zamalek',       N'بودي سنتر الزمالك',       N'SM02', N'010 1122 3305', N'17 Brazil St., Zamalek, Cairo',                30.0614, 31.2200, 0),
    (N'CUS0006', N'Iron Temple Sheikh Zayed',  N'آيرون تمبل الشيخ زايد',   N'SM02', N'010 1122 3306', N'Beverly Hills Mall, Sheikh Zayed, Giza',       30.0180, 30.9760, 0),
    (N'CUS0007', N'Supplement World October',  N'سبليمنت وورلد أكتوبر',    N'SM02', N'010 1122 3307', N'Mall of Arabia, 6th of October, Giza',         29.9720, 30.9410, 0),
    (N'CUS0008', N'Titan Gym Smouha',          N'تايتن جيم سموحة',         N'SM03', N'010 1122 3308', N'30 Victor Emanuel Sq., Smouha, Alexandria',    31.2140, 29.9430, 0),
    (N'CUS0009', N'Vital Nutrition Tanta',     N'فيتال نيوتريشن طنطا',     N'SM03', N'010 1122 3309', N'5 El Geish St., Tanta, Gharbia',               30.7880, 31.0000, 0),
    (N'CUS0010', N'Peak Fitness Mansoura',     N'بيك فيتنس المنصورة',      N'SM03', N'010 1122 3310', N'19 El Gomhoreya St., Mansoura, Dakahlia',      31.0410, 31.3790, 0),
    (N'CUS0011', N'Alpha Gym Shubra',          N'ألفا جيم شبرا',           N'SM01', N'010 1122 3311', N'60 Shubra St., Shubra, Cairo',                 30.0780, 31.2440, 0),
    (N'CUS0012', N'Olympia Store Faisal',      N'أوليمبيا ستور فيصل',      N'SM02', N'010 1122 3312', N'101 Faisal St., Giza',                         30.0180, 31.1900, 1)
) AS s (CustomerNo, CustomerNameE, CustomerNameA, SalesmanNo, Mobile, Address, Latitude, Longitude, InActive)
    ON t.CustomerNo = s.CustomerNo
WHEN NOT MATCHED THEN
    INSERT (CustomerNo, CustomerNameE, CustomerNameA, SalesmanNo, BUID, Mobile, Address,
            InActive, RecordSource, Latitude, Longitude, SalesDivisionID, WorkFLowStatus, ChannelID, CreatedOn, Createdby)
    VALUES (s.CustomerNo, s.CustomerNameE, s.CustomerNameA, s.SalesmanNo, N'C100', s.Mobile, s.Address,
            s.InActive, 1, s.Latitude, s.Longitude, N'01', 1, N'CH-GYM', GETDATE(), N'seed');
GO

/* ------------------------------------------------------- sales order tables
   The SDK's minimal schema ships no transaction tables, but every alert rule
   ("no order for N days", "sales dropped X%") is computed from order history,
   so the feature needs them. Naming/audit columns follow the SDK convention.
*/
IF OBJECT_ID('dbo.HH_SalesOrderDetail', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HH_SalesOrderDetail (
        OrderNo    NVARCHAR(20)  NOT NULL,
        LineNumber INT           NOT NULL,   -- NOT "LineNo": LINENO is a reserved T-SQL keyword
        ItemNo     NVARCHAR(40)  NOT NULL,
        Qty        DECIMAL(18,2) NOT NULL,
        UnitPrice  DECIMAL(18,2) NOT NULL,
        LineTotal  AS (Qty * UnitPrice) PERSISTED,
        CreatedOn  DATETIME NULL,
        Createdby  NVARCHAR(15) NULL,
        ModifiedOn DATETIME NULL,
        ModifiedBy NVARCHAR(15) NULL,
        CONSTRAINT PK_HH_SalesOrderDetail PRIMARY KEY (OrderNo, LineNumber)
    );
END
GO

IF OBJECT_ID('dbo.HH_SalesOrder', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HH_SalesOrder (
        OrderNo     NVARCHAR(20)  NOT NULL,
        OrderDate   DATETIME      NOT NULL,
        CustomerNo  NVARCHAR(15)  NOT NULL,
        SalesmanNo  NVARCHAR(15)  NULL,
        BUID        NVARCHAR(15)  NOT NULL,
        NetAmount   DECIMAL(18,2) NOT NULL CONSTRAINT DF_HH_SalesOrder_Net DEFAULT (0),
        OrderStatus TINYINT       NOT NULL CONSTRAINT DF_HH_SalesOrder_Status DEFAULT (2),
        CreatedOn   DATETIME NULL,
        Createdby   NVARCHAR(15) NULL,
        ModifiedOn  DATETIME NULL,
        ModifiedBy  NVARCHAR(15) NULL,
        CONSTRAINT PK_HH_SalesOrder PRIMARY KEY (OrderNo)
    );
    CREATE INDEX IX_HH_SalesOrder_Customer_Date ON dbo.HH_SalesOrder (CustomerNo, OrderDate DESC) INCLUDE (NetAmount);
END
GO

/* ------------------------------------------------------------ order history
   Rebuilt on every run so the relative dates stay anchored to "today".
*/
DELETE FROM dbo.HH_SalesOrderDetail WHERE OrderNo LIKE N'SO-%';
DELETE FROM dbo.HH_SalesOrder       WHERE OrderNo LIKE N'SO-%';
GO

DECLARE @today DATE = CAST(GETDATE() AS DATE);

/* (customer, days-ago, target order value) - shaped per the story at the top */
DECLARE @plan TABLE (CustomerNo NVARCHAR(15), DaysAgo INT, Amount DECIMAL(18,2));
INSERT INTO @plan (CustomerNo, DaysAgo, Amount) VALUES
    -- CUS0001 Gold Gym  : healthy for months, then silent 48 days  -> LOST
    (N'CUS0001', 48, 8500), (N'CUS0001', 62, 9200), (N'CUS0001', 76, 8800), (N'CUS0001', 90, 9000),
    -- CUS0002 Fitness First Maadi : steady, high value -> no alert
    (N'CUS0002',  3,12400), (N'CUS0002', 11,11800), (N'CUS0002', 19,12100), (N'CUS0002', 27,12600),
    (N'CUS0002', 35,11900), (N'CUS0002', 48,12200), (N'CUS0002', 61,12000), (N'CUS0002', 75,11700),
    -- CUS0003 Power House : last 30d = 6,000 vs previous 30d = 15,000 -> -60%
    (N'CUS0003',  5, 3200), (N'CUS0003', 18, 2800),
    (N'CUS0003', 38, 5200), (N'CUS0003', 47, 5100), (N'CUS0003', 55, 4700),
    (N'CUS0003', 72, 5000), (N'CUS0003', 86, 4900),
    -- CUS0004 Muscle Shop Dokki : steady mid value -> no alert
    (N'CUS0004',  2, 6500), (N'CUS0004',  9, 6300), (N'CUS0004', 16, 6700), (N'CUS0004', 24, 6400),
    (N'CUS0004', 33, 6600), (N'CUS0004', 45, 6200), (N'CUS0004', 58, 6800), (N'CUS0004', 70, 6500),
    -- CUS0005 Body Center Zamalek : silent 65 days -> LOST
    (N'CUS0005', 65, 5400), (N'CUS0005', 79, 5900), (N'CUS0005', 93, 5600),
    -- CUS0006 Iron Temple : the biggest account, steady -> no alert
    (N'CUS0006',  4,15200), (N'CUS0006', 12,14800), (N'CUS0006', 21,15500), (N'CUS0006', 29,14900),
    (N'CUS0006', 38,15100), (N'CUS0006', 50,15300), (N'CUS0006', 63,14700), (N'CUS0006', 77,15000),
    -- CUS0007 Supplement World : last 30d ~5,800 vs previous 30d ~15,200 -> -62%
    (N'CUS0007',  7, 3200), (N'CUS0007', 20, 2600),
    (N'CUS0007', 36, 5300), (N'CUS0007', 44, 5400), (N'CUS0007', 52, 4900),
    (N'CUS0007', 68, 5200), (N'CUS0007', 84, 5100),
    -- CUS0008 Titan Gym Smouha : steady -> no alert
    (N'CUS0008',  6, 9500), (N'CUS0008', 14, 9300), (N'CUS0008', 23, 9700), (N'CUS0008', 31, 9400),
    (N'CUS0008', 40, 9600), (N'CUS0008', 52, 9200), (N'CUS0008', 66, 9800), (N'CUS0008', 80, 9500),
    -- CUS0009 Vital Nutrition Tanta : silent 38 days -> LOST
    (N'CUS0009', 38, 4200), (N'CUS0009', 51, 4600), (N'CUS0009', 64, 4400), (N'CUS0009', 78, 4300),
    -- CUS0010 Peak Fitness Mansoura : steady -> no alert
    (N'CUS0010',  1, 7200), (N'CUS0010',  8, 7000), (N'CUS0010', 17, 7400), (N'CUS0010', 26, 7100),
    (N'CUS0010', 34, 7300), (N'CUS0010', 46, 6900), (N'CUS0010', 59, 7500), (N'CUS0010', 72, 7200),
    -- CUS0011 Alpha Gym Shubra : brand new, one order only -> no alert yet
    (N'CUS0011', 12, 3500),
    -- CUS0012 Olympia Store Faisal : inactive customer, ancient history
    (N'CUS0012',110, 2800), (N'CUS0012',125, 3100);

/* order headers */
INSERT INTO dbo.HH_SalesOrder (OrderNo, OrderDate, CustomerNo, SalesmanNo, BUID, NetAmount, OrderStatus, CreatedOn, Createdby)
SELECT
    N'SO-' + RIGHT(N'00000' + CAST(ROW_NUMBER() OVER (ORDER BY p.CustomerNo, p.DaysAgo) AS NVARCHAR(5)), 5),
    DATEADD(HOUR, 9 + (ABS(CHECKSUM(p.CustomerNo, p.DaysAgo)) % 8), CAST(DATEADD(DAY, -p.DaysAgo, @today) AS DATETIME)),
    p.CustomerNo,
    c.SalesmanNo,
    N'C100',
    0,                       -- recomputed from the lines below
    2,                       -- delivered
    GETDATE(), N'seed'
FROM @plan p
JOIN HH_Customer c ON c.CustomerNo = p.CustomerNo;

/* two order lines per order, split ~60/40 of the target value */
DECLARE @price TABLE (Idx INT, ItemNo NVARCHAR(40), UnitPrice DECIMAL(18,2));
INSERT INTO @price VALUES
    (0, N'ITM-WHEY-2K', 1850), (1, N'ITM-CREA-300', 620), (2, N'ITM-BCAA-400', 780),
    (3, N'ITM-PREW-300', 950), (4, N'ITM-GAIN-3K', 1450), (5, N'ITM-OMG3-100', 340);

WITH o AS (
    SELECT h.OrderNo, p.Amount,
           ABS(CHECKSUM(h.OrderNo)) % 6              AS i1,
           (ABS(CHECKSUM(h.OrderNo)) + 3) % 6        AS i2
    FROM dbo.HH_SalesOrder h
    JOIN @plan p ON p.CustomerNo = h.CustomerNo
                AND CAST(h.OrderDate AS DATE) = DATEADD(DAY, -p.DaysAgo, @today)
)
INSERT INTO dbo.HH_SalesOrderDetail (OrderNo, LineNumber, ItemNo, Qty, UnitPrice, CreatedOn, Createdby)
SELECT o.OrderNo, 1, pr.ItemNo,
       CASE WHEN ROUND(o.Amount * 0.6 / pr.UnitPrice, 0) < 1 THEN 1
            ELSE ROUND(o.Amount * 0.6 / pr.UnitPrice, 0) END,
       pr.UnitPrice, GETDATE(), N'seed'
FROM o JOIN @price pr ON pr.Idx = o.i1
UNION ALL
SELECT o.OrderNo, 2, pr.ItemNo,
       CASE WHEN ROUND(o.Amount * 0.4 / pr.UnitPrice, 0) < 1 THEN 1
            ELSE ROUND(o.Amount * 0.4 / pr.UnitPrice, 0) END,
       pr.UnitPrice, GETDATE(), N'seed'
FROM o JOIN @price pr ON pr.Idx = o.i2;

/* header total = sum of its lines */
UPDATE h
SET NetAmount = d.Total
FROM dbo.HH_SalesOrder h
JOIN (SELECT OrderNo, SUM(LineTotal) AS Total FROM dbo.HH_SalesOrderDetail GROUP BY OrderNo) d
  ON d.OrderNo = h.OrderNo;
GO

PRINT '';
PRINT '=====================================================';
PRINT ' SUPSEAL Nutrition demo data loaded';
PRINT '=====================================================';
GO

SELECT
    c.CustomerNo,
    c.CustomerNameE,
    Orders          = COUNT(o.OrderNo),
    LastOrder       = MAX(CAST(o.OrderDate AS DATE)),
    DaysSilent      = DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()),
    TotalValue      = ISNULL(SUM(o.NetAmount), 0)
FROM HH_Customer c
LEFT JOIN dbo.HH_SalesOrder o ON o.CustomerNo = c.CustomerNo
GROUP BY c.CustomerNo, c.CustomerNameE
ORDER BY c.CustomerNo;
GO
