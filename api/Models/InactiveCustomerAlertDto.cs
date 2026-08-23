namespace api.Models;

public class InactiveCustomerAlertDto
{
    public int RuleId { get; set; }
    public string RuleName { get; set; } = null!;
    public string RuleCode { get; set; } = null!;
    public int InactiveDaysThreshold { get; set; }
    public AlertRulePriority Priority { get; set; }
    public string CustomerNo { get; set; } = null!;
    public string CustomerName { get; set; } = null!;
    public string? SalesmanNo { get; set; }
    public string? Mobile { get; set; }
    public DateTime LastOrderDate { get; set; }
    public int DaysInactive { get; set; }

    public static InactiveCustomerAlertDto FromRow(InactiveCustomerAlertRow row) => new()
    {
        RuleId = row.RuleId,
        RuleName = row.RuleName,
        RuleCode = row.RuleCode,
        InactiveDaysThreshold = row.InactiveDaysThreshold,
        Priority = (AlertRulePriority)row.Severity,
        CustomerNo = row.CustomerNo,
        CustomerName = row.CustomerNameE ?? row.CustomerNameA ?? row.CustomerNo,
        SalesmanNo = row.SalesmanNo,
        Mobile = row.Mobile,
        LastOrderDate = row.LastOrderDate,
        DaysInactive = row.DaysInactive
    };
}
