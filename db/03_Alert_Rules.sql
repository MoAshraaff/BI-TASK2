/* ============================================================================
   Smart Customer Alert Rules  --  data layer
   ----------------------------------------------------------------------------
   A rules engine, not a CRUD screen. The manager defines rules; the engine
   evaluates them against order history and raises / refreshes / closes alerts.

   Design decisions worth knowing before changing anything here:

   1. The engine lives in a stored procedure because every rule is a set-based
      aggregate over HH_SalesOrder. Doing it row-by-row in C# would mean pulling
      the whole order history into the API. This also matches the SDK's own
      convention (it ships Get_AuditCriteria as a proc).

   2. Re-running the engine must never duplicate an alert. That is enforced by
      the database, not by application code: UX_HH_AlertLog_Open is a FILTERED
      UNIQUE index allowing one open alert per (RuleID, CustomerNo). Even a
      buggy caller cannot create duplicates.

   3. Alerts close themselves. Every run recomputes the full match set; open
      alerts that no longer match are auto-resolved. So when a "lost" customer
      places an order, the alert disappears on the next run without anyone
      touching it.

   4. Adding a new rule type = adding one INSERT block into #Match plus one
      entry in the RuleType check constraint. Nothing else changes. (Low-stock
      rules would need an inventory table, which this schema does not have.)
   ============================================================================ */

USE [MO_ASHRAF];
GO
SET NOCOUNT ON;
-- Filtered indexes require these; sqlcmd defaults QUOTED_IDENTIFIER to OFF.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ------------------------------------------------------------- rule master */
IF OBJECT_ID('dbo.HH_AlertRule', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HH_AlertRule (
        RuleID            INT IDENTITY(1,1) NOT NULL,
        RuleCode          NVARCHAR(20)  NOT NULL,
        RuleName          NVARCHAR(100) NOT NULL,
        RuleNameA         NVARCHAR(100) NULL,
        RuleType          NVARCHAR(30)  NOT NULL,
        ThresholdValue    DECIMAL(18,2) NOT NULL,
        ComparePeriodDays INT           NULL,   -- SALES_DROP_PCT only; defaults to 30
        ScopeSalesmanNo   NVARCHAR(15)  NULL,   -- NULL = every salesman
        NotifyTarget      NVARCHAR(20)  NOT NULL,
        Severity          TINYINT       NOT NULL,   -- 1 low, 2 medium, 3 high
        IsActive          TINYINT       NOT NULL CONSTRAINT DF_HH_AlertRule_Active DEFAULT (1),
        BUID              NVARCHAR(15)  NOT NULL,
        LastRunOn         DATETIME      NULL,
        CreatedOn         DATETIME      NULL,
        Createdby         NVARCHAR(15)  NULL,
        ModifiedOn        DATETIME      NULL,
        ModifiedBy        NVARCHAR(15)  NULL,
        CONSTRAINT PK_HH_AlertRule PRIMARY KEY (RuleID),
        CONSTRAINT UX_HH_AlertRule_Code UNIQUE (RuleCode),
        CONSTRAINT CK_HH_AlertRule_Type
            CHECK (RuleType IN (N'NO_ORDER_DAYS', N'SALES_DROP_PCT')),
        CONSTRAINT CK_HH_AlertRule_Notify
            CHECK (NotifyTarget IN (N'MANAGER', N'SALES_REP', N'TEAM')),
        CONSTRAINT CK_HH_AlertRule_Severity CHECK (Severity BETWEEN 1 AND 3),
        CONSTRAINT CK_HH_AlertRule_Threshold CHECK (ThresholdValue > 0)
    );
END
GO

/* Added after the initial rollout - guarded separately so re-running this
   script against a database that already has HH_AlertRule (without this
   column) still picks it up. NULL = every customer. */
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.HH_AlertRule') AND name = 'ScopeCustomerNo'
)
BEGIN
    ALTER TABLE dbo.HH_AlertRule ADD ScopeCustomerNo NVARCHAR(15) NULL;
END
GO

/* -------------------------------------------------------------- alert log  */
IF OBJECT_ID('dbo.HH_AlertLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.HH_AlertLog (
        AlertID       BIGINT IDENTITY(1,1) NOT NULL,
        RuleID        INT           NOT NULL,
        CustomerNo    NVARCHAR(15)  NOT NULL,
        AlertDate     DATETIME      NOT NULL,
        MetricValue   DECIMAL(18,2) NULL,     -- 48 (days silent) or 64.70 (percent drop)
        AlertMessage  NVARCHAR(500) NOT NULL,
        AlertMessageA NVARCHAR(500) NULL,
        Severity      TINYINT       NOT NULL, -- snapshot: the rule may change later
        Status        TINYINT       NOT NULL CONSTRAINT DF_HH_AlertLog_Status DEFAULT (1),
        ResolvedOn    DATETIME      NULL,
        BUID          NVARCHAR(15)  NOT NULL,
        CreatedOn     DATETIME      NULL,
        Createdby     NVARCHAR(15)  NULL,
        ModifiedOn    DATETIME      NULL,
        ModifiedBy    NVARCHAR(15)  NULL,
        CONSTRAINT PK_HH_AlertLog PRIMARY KEY (AlertID),
        CONSTRAINT FK_HH_AlertLog_Rule FOREIGN KEY (RuleID) REFERENCES dbo.HH_AlertRule (RuleID),
        CONSTRAINT CK_HH_AlertLog_Status CHECK (Status IN (1, 2, 3))  -- New / Acknowledged / Resolved
    );

    /* The idempotency guarantee: at most one OPEN (new or acknowledged) alert
       per rule per customer. Resolved rows are excluded, so the same customer
       can legitimately be flagged again months later. */
    CREATE UNIQUE INDEX UX_HH_AlertLog_Open
        ON dbo.HH_AlertLog (RuleID, CustomerNo)
        WHERE Status IN (1, 2);

    CREATE INDEX IX_HH_AlertLog_Status_Date
        ON dbo.HH_AlertLog (Status, AlertDate DESC) INCLUDE (CustomerNo, Severity);
END
GO

/* ---------------------------------------------------------- the engine ---- */
CREATE OR ALTER PROCEDURE dbo.usp_EvaluateAlertRules
    @BUID  NVARCHAR(15) = NULL,     -- NULL = every business unit
    @RunBy NVARCHAR(15) = N'system'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME = GETDATE();

    /* Every rule that fires lands here first. Building the complete match set
       up front is what makes the run idempotent AND lets us auto-resolve:
       anything currently open but absent from #Match has recovered. */
    CREATE TABLE #Match (
        RuleID        INT           NOT NULL,
        CustomerNo    NVARCHAR(15)  NOT NULL,
        MetricValue   DECIMAL(18,2) NULL,
        AlertMessage  NVARCHAR(500) NOT NULL,
        AlertMessageA NVARCHAR(500) NULL,
        Severity      TINYINT       NOT NULL,
        BUID          NVARCHAR(15)  NOT NULL,
        PRIMARY KEY (RuleID, CustomerNo)
    );

    /* ---- rule type: NO_ORDER_DAYS -------------------------------------- */
    INSERT INTO #Match (RuleID, CustomerNo, MetricValue, AlertMessage, AlertMessageA, Severity, BUID)
    SELECT
        r.RuleID,
        c.CustomerNo,
        DATEDIFF(DAY, lo.LastOrderDate, @now),
        c.CustomerNameE + N' has not ordered for '
            + CAST(DATEDIFF(DAY, lo.LastOrderDate, @now) AS NVARCHAR(10))
            + N' days (last order ' + CONVERT(NVARCHAR(10), lo.LastOrderDate, 23) + N').',
        ISNULL(c.CustomerNameA, c.CustomerNameE) + N' لم يطلب منذ '
            + CAST(DATEDIFF(DAY, lo.LastOrderDate, @now) AS NVARCHAR(10))
            + N' يوم (آخر طلب ' + CONVERT(NVARCHAR(10), lo.LastOrderDate, 23) + N').',
        r.Severity,
        r.BUID
    FROM dbo.HH_AlertRule r
    JOIN dbo.HH_Customer  c
      ON c.BUID = r.BUID
     AND (r.ScopeSalesmanNo IS NULL OR c.SalesmanNo = r.ScopeSalesmanNo)
     AND (r.ScopeCustomerNo IS NULL OR c.CustomerNo = r.ScopeCustomerNo)
    CROSS APPLY (
        SELECT MAX(o.OrderDate) AS LastOrderDate
        FROM dbo.HH_SalesOrder o
        WHERE o.CustomerNo = c.CustomerNo
          AND o.OrderStatus <> 3            -- ignore cancelled orders
    ) lo
    WHERE r.IsActive = 1
      AND r.RuleType = N'NO_ORDER_DAYS'
      AND (@BUID IS NULL OR r.BUID = @BUID)
      AND ISNULL(c.InActive, 0) = 0         -- never chase a deactivated customer
      AND lo.LastOrderDate IS NOT NULL
      AND DATEDIFF(DAY, lo.LastOrderDate, @now) >= r.ThresholdValue;

    /* ---- rule type: SALES_DROP_PCT ------------------------------------- */
    INSERT INTO #Match (RuleID, CustomerNo, MetricValue, AlertMessage, AlertMessageA, Severity, BUID)
    SELECT
        w.RuleID,
        w.CustomerNo,
        w.DropPct,
        w.CustomerNameE + N' sales dropped ' + CAST(w.DropPct AS NVARCHAR(10))
            + N'% over the last ' + CAST(w.Days AS NVARCHAR(10)) + N' days ('
            + CAST(CAST(w.Recent AS DECIMAL(18,0)) AS NVARCHAR(20)) + N' vs '
            + CAST(CAST(w.Prior  AS DECIMAL(18,0)) AS NVARCHAR(20)) + N').',
        ISNULL(w.CustomerNameA, w.CustomerNameE) + N' انخفضت مبيعاته بنسبة '
            + CAST(w.DropPct AS NVARCHAR(10)) + N'% خلال آخر '
            + CAST(w.Days AS NVARCHAR(10)) + N' يوم.',
        w.Severity,
        w.BUID
    FROM (
        SELECT
            r.RuleID, c.CustomerNo, c.CustomerNameE, c.CustomerNameA,
            r.Severity, r.BUID, p.Days,
            /* ELSE 0 instead of ISNULL(SUM(...)): stops SQL Server raising
               "null value is eliminated by an aggregate" on every single run. */
            Recent  = SUM(CASE WHEN o.OrderDate >= DATEADD(DAY, -p.Days, @now)
                               THEN o.NetAmount ELSE 0 END),
            Prior   = SUM(CASE WHEN o.OrderDate >= DATEADD(DAY, -2 * p.Days, @now)
                                AND o.OrderDate <  DATEADD(DAY, -p.Days, @now)
                               THEN o.NetAmount ELSE 0 END),
            DropPct = CAST(100.0 * (1 -
                          SUM(CASE WHEN o.OrderDate >= DATEADD(DAY, -p.Days, @now)
                                   THEN o.NetAmount ELSE 0 END)
                          / NULLIF(SUM(CASE WHEN o.OrderDate >= DATEADD(DAY, -2 * p.Days, @now)
                                             AND o.OrderDate <  DATEADD(DAY, -p.Days, @now)
                                            THEN o.NetAmount ELSE 0 END), 0)
                      ) AS DECIMAL(18,2)),
            r.ThresholdValue
        FROM dbo.HH_AlertRule r
        CROSS APPLY (SELECT Days = ISNULL(r.ComparePeriodDays, 30)) p
        JOIN dbo.HH_Customer c
          ON c.BUID = r.BUID
         AND (r.ScopeSalesmanNo IS NULL OR c.SalesmanNo = r.ScopeSalesmanNo)
         AND (r.ScopeCustomerNo IS NULL OR c.CustomerNo = r.ScopeCustomerNo)
        LEFT JOIN dbo.HH_SalesOrder o
          ON o.CustomerNo = c.CustomerNo
         AND o.OrderStatus <> 3
        WHERE r.IsActive = 1
          AND r.RuleType = N'SALES_DROP_PCT'
          AND (@BUID IS NULL OR r.BUID = @BUID)
          AND ISNULL(c.InActive, 0) = 0
        GROUP BY r.RuleID, c.CustomerNo, c.CustomerNameE, c.CustomerNameA,
                 r.Severity, r.BUID, p.Days, r.ThresholdValue
    ) w
    /* Two exclusions that keep this rule meaningful rather than merely correct:

       Prior = 0  -> nothing to drop from; that is a new customer, not a
                     churning one. NULLIF above already makes DropPct NULL.

       Recent = 0 -> the customer stopped ordering altogether. Reporting that
                     as "sales dropped 100%" duplicates the NO_ORDER_DAYS alert
                     the same customer already gets, and double-alerting is how
                     real systems train their users to ignore alerts. A sales
                     DROP means still buying, but less. Churn is a separate
                     rule with a separate response. */
    WHERE w.DropPct IS NOT NULL
      AND w.Recent > 0
      AND w.DropPct >= w.ThresholdValue;

    /* ---- 1. close alerts whose condition has cleared -------------------- */
    UPDATE l
    SET Status     = 3,
        ResolvedOn = @now,
        ModifiedOn = @now,
        ModifiedBy = @RunBy
    FROM dbo.HH_AlertLog l
    JOIN dbo.HH_AlertRule r ON r.RuleID = l.RuleID
    WHERE l.Status IN (1, 2)
      AND (@BUID IS NULL OR l.BUID = @BUID)
      AND (r.IsActive = 0                       -- rule switched off -> stand down
           OR NOT EXISTS (SELECT 1 FROM #Match m
                          WHERE m.RuleID = l.RuleID AND m.CustomerNo = l.CustomerNo));

    /* ---- 2. refresh alerts that still hold ------------------------------ */
    UPDATE l
    SET MetricValue   = m.MetricValue,
        AlertMessage  = m.AlertMessage,
        AlertMessageA = m.AlertMessageA,
        AlertDate     = @now,
        ModifiedOn    = @now,
        ModifiedBy    = @RunBy
    FROM dbo.HH_AlertLog l
    JOIN #Match m ON m.RuleID = l.RuleID AND m.CustomerNo = l.CustomerNo
    WHERE l.Status IN (1, 2);

    /* ---- 3. raise genuinely new alerts ---------------------------------- */
    INSERT INTO dbo.HH_AlertLog
        (RuleID, CustomerNo, AlertDate, MetricValue, AlertMessage, AlertMessageA,
         Severity, Status, BUID, CreatedOn, Createdby)
    SELECT m.RuleID, m.CustomerNo, @now, m.MetricValue, m.AlertMessage, m.AlertMessageA,
           m.Severity, 1, m.BUID, @now, @RunBy
    FROM #Match m
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.HH_AlertLog l
        WHERE l.RuleID = m.RuleID AND l.CustomerNo = m.CustomerNo AND l.Status IN (1, 2)
    );

    UPDATE dbo.HH_AlertRule
    SET LastRunOn = @now
    WHERE IsActive = 1 AND (@BUID IS NULL OR BUID = @BUID);

    DROP TABLE #Match;

    /* run summary for the caller */
    SELECT
        RunOn      = @now,
        OpenAlerts = (SELECT COUNT(*) FROM dbo.HH_AlertLog WHERE Status IN (1,2) AND (@BUID IS NULL OR BUID = @BUID)),
        NewAlerts  = (SELECT COUNT(*) FROM dbo.HH_AlertLog WHERE Status = 1 AND CreatedOn = @now),
        Resolved   = (SELECT COUNT(*) FROM dbo.HH_AlertLog WHERE Status = 3 AND ResolvedOn = @now);
END
GO

/* --------------------------------------------------------- starter rules  */
MERGE dbo.HH_AlertRule AS t
USING (VALUES
    (N'LOST-30', N'Lost Customer',   N'عميل متوقف',        N'NO_ORDER_DAYS',  30, NULL, N'MANAGER',   2),
    (N'LOST-60', N'Critical Churn',  N'فقدان عميل حرج',    N'NO_ORDER_DAYS',  60, NULL, N'MANAGER',   3),
    (N'DROP-50', N'Sales Drop 50%',  N'انخفاض مبيعات 50%', N'SALES_DROP_PCT', 50, 30,   N'SALES_REP', 3)
) AS s (RuleCode, RuleName, RuleNameA, RuleType, ThresholdValue, ComparePeriodDays, NotifyTarget, Severity)
    ON t.RuleCode = s.RuleCode
WHEN NOT MATCHED THEN
    INSERT (RuleCode, RuleName, RuleNameA, RuleType, ThresholdValue, ComparePeriodDays,
            ScopeSalesmanNo, NotifyTarget, Severity, IsActive, BUID, CreatedOn, Createdby)
    VALUES (s.RuleCode, s.RuleName, s.RuleNameA, s.RuleType, s.ThresholdValue, s.ComparePeriodDays,
            NULL, s.NotifyTarget, s.Severity, 1, N'C100', GETDATE(), N'seed');
GO

PRINT '';
PRINT '=====================================================';
PRINT ' Alert rules engine installed';
PRINT '=====================================================';
GO
