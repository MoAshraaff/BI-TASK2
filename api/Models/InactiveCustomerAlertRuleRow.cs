namespace api.Models;

// Raw projection of a dbo.HH_AlertRule row (RuleType = 'NO_ORDER_DAYS'),
// used with SqlQuery/SqlQueryRaw the same way BusinessUnit/Customer are.
public class InactiveCustomerAlertRuleRow
{
    public int Id { get; set; }
    public string RuleCode { get; set; } = null!;
    public string RuleName { get; set; } = null!;
    public string? RuleNameA { get; set; }
    public int InactiveDays { get; set; }
    public byte Severity { get; set; }
    public byte IsActive { get; set; }
    public DateTime? LastRunOn { get; set; }
    public DateTime CreatedOn { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? ModifiedOn { get; set; }
    public string? ModifiedBy { get; set; }
}
