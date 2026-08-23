namespace api.Models;

public class InactiveCustomerAlertRuleDto
{
    public int Id { get; set; }
    public string RuleCode { get; set; } = null!;
    public string RuleName { get; set; } = null!;
    public string? RuleNameA { get; set; }
    public int InactiveDays { get; set; }
    public AlertRulePriority Priority { get; set; }
    public bool IsActive { get; set; }
    public DateTime? LastRunOn { get; set; }
    public DateTime CreatedOn { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? ModifiedOn { get; set; }
    public string? ModifiedBy { get; set; }
    public string? ScopeCustomerNo { get; set; }
    public string? ScopeCustomerName { get; set; }

    public static InactiveCustomerAlertRuleDto FromRow(InactiveCustomerAlertRuleRow row) => new()
    {
        Id = row.Id,
        RuleCode = row.RuleCode,
        RuleName = row.RuleName,
        RuleNameA = row.RuleNameA,
        InactiveDays = row.InactiveDays,
        Priority = (AlertRulePriority)row.Severity,
        IsActive = row.IsActive != 0,
        LastRunOn = row.LastRunOn,
        CreatedOn = row.CreatedOn,
        CreatedBy = row.CreatedBy,
        ModifiedOn = row.ModifiedOn,
        ModifiedBy = row.ModifiedBy,
        ScopeCustomerNo = row.ScopeCustomerNo,
        ScopeCustomerName = row.ScopeCustomerName
    };
}
