namespace api.Models;

public class InactiveCustomerAlertRuleRequest
{
    public string RuleName { get; set; } = string.Empty;
    public string? RuleNameA { get; set; }
    public int InactiveDays { get; set; }
    public AlertRulePriority Priority { get; set; }
    public bool IsActive { get; set; } = true;

    // When set, this rule applies only to this one customer instead of every
    // customer in the business unit. Mirrors the existing ScopeSalesmanNo
    // column's null-means-unscoped convention.
    public string? ScopeCustomerNo { get; set; }
}
