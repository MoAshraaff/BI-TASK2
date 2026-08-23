namespace api.Models;

public class InactiveCustomerAlertRuleRequest
{
    public string RuleName { get; set; } = string.Empty;
    public string? RuleNameA { get; set; }
    public int InactiveDays { get; set; }
    public AlertRulePriority Priority { get; set; }
    public bool IsActive { get; set; } = true;
}
