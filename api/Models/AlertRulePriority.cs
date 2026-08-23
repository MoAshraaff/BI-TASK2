namespace api.Models;

// Mirrors the 1-3 range enforced by the existing CK_HH_AlertRule_Severity
// check constraint on HH_AlertRule.Severity - not a new priority scheme.
public enum AlertRulePriority
{
    Low = 1,
    Medium = 2,
    High = 3
}
