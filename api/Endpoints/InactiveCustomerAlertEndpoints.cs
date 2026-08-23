using api.Models;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;

namespace api.Endpoints;

// Read-only view of customers who currently exceed one of their business
// unit's active NO_ORDER_DAYS rules. Computed live from HH_Customer /
// HH_SalesOrder using the exact same condition dbo.usp_EvaluateAlertRules
// uses for its NO_ORDER_DAYS block - but as a plain SELECT, so it never
// writes to HH_AlertLog and never evaluates SALES_DROP_PCT rules the way
// running that stored procedure would (it has no rule-type filter).
public static class InactiveCustomerAlertEndpoints
{
    private const string SelectSql = """
        SELECT
            r.RuleID AS RuleId, r.RuleName, r.RuleCode,
            CAST(r.ThresholdValue AS int) AS InactiveDaysThreshold, r.Severity,
            c.CustomerNo, c.CustomerNameE, c.CustomerNameA, c.SalesmanNo, c.Mobile,
            lo.LastOrderDate,
            DATEDIFF(DAY, lo.LastOrderDate, GETDATE()) AS DaysInactive
        FROM dbo.HH_AlertRule r
        JOIN dbo.HH_Customer c
          ON c.BUID = r.BUID
         AND (r.ScopeSalesmanNo IS NULL OR c.SalesmanNo = r.ScopeSalesmanNo)
        CROSS APPLY (
            SELECT MAX(o.OrderDate) AS LastOrderDate
            FROM dbo.HH_SalesOrder o
            WHERE o.CustomerNo = c.CustomerNo AND o.OrderStatus <> 3
        ) lo
        WHERE r.IsActive = 1
          AND r.RuleType = 'NO_ORDER_DAYS'
          AND ISNULL(c.InActive, 0) = 0
          AND lo.LastOrderDate IS NOT NULL
          AND DATEDIFF(DAY, lo.LastOrderDate, GETDATE()) >= r.ThresholdValue
        ORDER BY DaysInactive DESC
        """;

    public static void MapInactiveCustomerAlertEndpoints(this WebApplication app)
    {
        app.MapGet("/api/inactive-customer-alerts", GetAll).WithName("GetInactiveCustomerAlerts");
    }

    private static async Task<Ok<List<InactiveCustomerAlertDto>>> GetAll(AppDbContext db, CancellationToken ct)
    {
        var rows = await db.Database.SqlQueryRaw<InactiveCustomerAlertRow>(SelectSql).ToListAsync(ct);
        return TypedResults.Ok(rows.Select(InactiveCustomerAlertDto.FromRow).ToList());
    }
}
