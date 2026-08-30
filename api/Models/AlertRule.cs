namespace api.Models;

/// <summary>
/// A manager-defined rule. Rows come back from HH_AlertRule via SqlQueryRaw
/// rather than a DbSet - see CLAUDE.md on why this project avoids adding
/// entity types to the SalesBuzz base context.
/// </summary>
public class AlertRule
{
    public int RuleID { get; set; }
    public string RuleCode { get; set; } = null!;
    public string RuleName { get; set; } = null!;
    public string? RuleNameA { get; set; }
    public string RuleType { get; set; } = null!;
    public decimal ThresholdValue { get; set; }
    public int? ComparePeriodDays { get; set; }
    public string? ScopeSalesmanNo { get; set; }
    public string? ScopeCustomerNo { get; set; }
    public string NotifyTarget { get; set; } = null!;
    public byte Severity { get; set; }
    public byte IsActive { get; set; }
    public string BUID { get; set; } = null!;
    public DateTime? LastRunOn { get; set; }

    // Read by BiNavComponent's "Info" toolbar button (bi-modules) to populate
    // its record-information popup - it looks these up case-insensitively by
    // exactly these names, so the C# casing here doesn't need to match.
    public DateTime? CreatedOn { get; set; }
    public string? Createdby { get; set; }
    public DateTime? ModifiedOn { get; set; }
    public string? ModifiedBy { get; set; }
}

/// <summary>What the client may send when creating or updating a rule.</summary>
public class AlertRuleInput
{
    public string? RuleCode { get; set; }
    public string? RuleName { get; set; }
    public string? RuleNameA { get; set; }
    public string? RuleType { get; set; }
    public decimal ThresholdValue { get; set; }
    public int? ComparePeriodDays { get; set; }
    public string? ScopeSalesmanNo { get; set; }
    public string? ScopeCustomerNo { get; set; }
    public string? NotifyTarget { get; set; }
    public byte Severity { get; set; }
    public byte IsActive { get; set; } = 1;

    /// <summary>
    /// Mirrors the CHECK constraints in 03_Alert_Rules.sql. Validating here as
    /// well means the client gets a readable 400 instead of a raw SQL error,
    /// while the database stays the real authority.
    /// </summary>
    public string? Validate()
    {
        if (string.IsNullOrWhiteSpace(RuleName))
            return "RuleName is required.";
        if (RuleType is not ("NO_ORDER_DAYS" or "SALES_DROP_PCT"))
            return "RuleType must be NO_ORDER_DAYS or SALES_DROP_PCT.";
        if (NotifyTarget is not ("MANAGER" or "SALES_REP" or "TEAM"))
            return "NotifyTarget must be MANAGER, SALES_REP or TEAM.";
        if (Severity is < 1 or > 3)
            return "Severity must be 1 (low), 2 (medium) or 3 (high).";
        if (ThresholdValue <= 0)
            return "ThresholdValue must be greater than zero.";
        if (RuleType == "SALES_DROP_PCT" && ThresholdValue > 100)
            return "A percentage drop cannot exceed 100.";
        if (RuleType == "SALES_DROP_PCT" && ComparePeriodDays is <= 0)
            return "ComparePeriodDays must be greater than zero.";
        return null;
    }
}

/// <summary>
/// What the client may send for a partial update (PATCH) - the Alert Rules
/// grid's Save button only ever has the columns it actually shows to send
/// (Rule Name/Scope/Threshold/Priority/Status), never the fields it hides
/// (RuleType, NotifyTarget, ...), so every property here is optional and
/// left out of the SQL SET list when absent rather than nulling the column.
/// </summary>
public class AlertRulePatchInput
{
    public string? RuleCode { get; set; }
    public string? RuleName { get; set; }
    public string? RuleType { get; set; }
    public decimal? ThresholdValue { get; set; }
    public int? ComparePeriodDays { get; set; }
    public string? ScopeSalesmanNo { get; set; }
    public string? ScopeCustomerNo { get; set; }
    public string? NotifyTarget { get; set; }
    public byte? Severity { get; set; }
    public byte? IsActive { get; set; }
}

/// <summary>A generated alert, joined with its rule for display.</summary>
public class AlertLogRow
{
    public long AlertID { get; set; }
    public int RuleID { get; set; }
    public string RuleCode { get; set; } = null!;
    public string RuleName { get; set; } = null!;
    public string CustomerNo { get; set; } = null!;
    public string? CustomerName { get; set; }
    public string? SalesmanNo { get; set; }
    public DateTime AlertDate { get; set; }
    public DateTime? LastOrderDate { get; set; }
    public decimal? MetricValue { get; set; }
    public string AlertMessage { get; set; } = null!;
    public string? AlertMessageA { get; set; }
    public byte Severity { get; set; }
    public string SeverityText { get; set; } = null!;
    public byte Status { get; set; }
    public string StatusText { get; set; } = null!;
}

/// <summary>What usp_EvaluateAlertRules reports back after a run.</summary>
public class EvaluationResult
{
    public DateTime RunOn { get; set; }
    public int OpenAlerts { get; set; }
    public int NewAlerts { get; set; }
    public int Resolved { get; set; }
}
