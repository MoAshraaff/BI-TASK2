namespace api.Models;

// Raw projection of a customer who currently exceeds one of their business
// unit's NO_ORDER_DAYS rules, computed live from HH_Customer/HH_SalesOrder.
public class InactiveCustomerAlertRow
{
    public int RuleId { get; set; }
    public string RuleName { get; set; } = null!;
    public string RuleCode { get; set; } = null!;
    public int InactiveDaysThreshold { get; set; }
    public byte Severity { get; set; }
    public string CustomerNo { get; set; } = null!;
    public string? CustomerNameE { get; set; }
    public string? CustomerNameA { get; set; }
    public string? SalesmanNo { get; set; }
    public string? Mobile { get; set; }
    public DateTime LastOrderDate { get; set; }
    public int DaysInactive { get; set; }
}
