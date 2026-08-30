using api.Models;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace api.Endpoints;

/// <summary>
/// Smart Customer Alert Rules endpoints.
///
/// Everything goes through parameterised raw SQL rather than DbSets: the
/// SalesBuzz base context owns a large slice of the schema and overrides
/// SaveChanges for audit logging, so adding entity types risks EF's shared-table
/// validation (see CLAUDE.md). Raw SQL keeps these tables independent of it.
/// </summary>
public static class AlertEndpoints
{
    private const string RuleColumns = """
        RuleID, RuleCode, RuleName, RuleNameA, RuleType, ThresholdValue,
        ComparePeriodDays, ScopeSalesmanNo, ScopeCustomerNo, NotifyTarget, Severity, IsActive, BUID, LastRunOn,
        CreatedOn, Createdby, ModifiedOn, ModifiedBy
        """;

    public static void MapAlertEndpoints(this WebApplication app)
    {
        var rules = app.MapGroup("/api/alert-rules");
        var alerts = app.MapGroup("/api/alerts");

        /* ----------------------------------------------------------- rules */

        rules.MapGet("/", async (AppDbContext db) =>
            await db.Database
                .SqlQueryRaw<AlertRule>($"SELECT {RuleColumns} FROM dbo.HH_AlertRule ORDER BY RuleID")
                .ToListAsync())
            .WithName("GetAlertRules");

        rules.MapGet("/{id:int}", async (int id, AppDbContext db) =>
        {
            var rule = await FindRuleAsync(db, id);
            return rule is null ? Results.NotFound() : Results.Ok(rule);
        }).WithName("GetAlertRule");

        rules.MapPost("/", async (AlertRuleInput input, AppDbContext db) =>
        {
            if (input.Validate() is { } error)
                return Results.BadRequest(new { message = error });

            // Auto-generate a code when the client does not supply one, so the
            // grid's "add row" flow does not force the user to invent keys.
            var code = string.IsNullOrWhiteSpace(input.RuleCode)
                ? $"RULE-{DateTime.Now:yyMMddHHmmss}"
                : input.RuleCode.Trim();

            if (await CodeExistsAsync(db, code, null))
                return Results.Conflict(new { message = $"Rule code '{code}' already exists." });

            var ids = await db.Database.SqlQueryRaw<int>(
                """
                INSERT INTO dbo.HH_AlertRule
                    (RuleCode, RuleName, RuleNameA, RuleType, ThresholdValue, ComparePeriodDays,
                     ScopeSalesmanNo, ScopeCustomerNo, NotifyTarget, Severity, IsActive, BUID, CreatedOn, Createdby)
                VALUES
                    (@code, @name, @nameA, @type, @threshold, @period,
                     @scope, @customerScope, @notify, @severity, @active, @buid, GETDATE(), @user);
                SELECT CAST(SCOPE_IDENTITY() AS INT) AS Value;
                """,
                new SqlParameter("@code", code),
                new SqlParameter("@name", input.RuleName!.Trim()),
                new SqlParameter("@nameA", (object?)input.RuleNameA ?? DBNull.Value),
                new SqlParameter("@type", input.RuleType!),
                new SqlParameter("@threshold", input.ThresholdValue),
                new SqlParameter("@period", (object?)input.ComparePeriodDays ?? DBNull.Value),
                new SqlParameter("@scope", (object?)NormalizeScope(input.ScopeSalesmanNo) ?? DBNull.Value),
                new SqlParameter("@customerScope", (object?)NormalizeScope(input.ScopeCustomerNo) ?? DBNull.Value),
                new SqlParameter("@notify", input.NotifyTarget!),
                new SqlParameter("@severity", input.Severity),
                new SqlParameter("@active", input.IsActive),
                new SqlParameter("@buid", "C100"),
                new SqlParameter("@user", "api"))
                .ToListAsync();

            var created = await FindRuleAsync(db, ids[0]);
            return Results.Created($"/api/alert-rules/{ids[0]}", created);
        }).WithName("CreateAlertRule");

        rules.MapPut("/{id:int}", async (int id, AlertRuleInput input, AppDbContext db) =>
        {
            if (input.Validate() is { } error)
                return Results.BadRequest(new { message = error });

            if (await FindRuleAsync(db, id) is null)
                return Results.NotFound();

            if (!string.IsNullOrWhiteSpace(input.RuleCode) &&
                await CodeExistsAsync(db, input.RuleCode.Trim(), id))
                return Results.Conflict(new { message = $"Rule code '{input.RuleCode}' already exists." });

            await db.Database.ExecuteSqlRawAsync(
                """
                UPDATE dbo.HH_AlertRule
                SET RuleCode          = ISNULL(@code, RuleCode),
                    RuleName          = @name,
                    RuleNameA         = @nameA,
                    RuleType          = @type,
                    ThresholdValue    = @threshold,
                    ComparePeriodDays = @period,
                    ScopeSalesmanNo   = @scope,
                    ScopeCustomerNo   = @customerScope,
                    NotifyTarget      = @notify,
                    Severity          = @severity,
                    IsActive          = @active,
                    ModifiedOn        = GETDATE(),
                    ModifiedBy        = @user
                WHERE RuleID = @id
                """,
                new SqlParameter("@id", id),
                new SqlParameter("@code", string.IsNullOrWhiteSpace(input.RuleCode)
                    ? DBNull.Value : input.RuleCode.Trim()),
                new SqlParameter("@name", input.RuleName!.Trim()),
                new SqlParameter("@nameA", (object?)input.RuleNameA ?? DBNull.Value),
                new SqlParameter("@type", input.RuleType!),
                new SqlParameter("@threshold", input.ThresholdValue),
                new SqlParameter("@period", (object?)input.ComparePeriodDays ?? DBNull.Value),
                new SqlParameter("@scope", (object?)NormalizeScope(input.ScopeSalesmanNo) ?? DBNull.Value),
                new SqlParameter("@customerScope", (object?)NormalizeScope(input.ScopeCustomerNo) ?? DBNull.Value),
                new SqlParameter("@notify", input.NotifyTarget!),
                new SqlParameter("@severity", input.Severity),
                new SqlParameter("@active", input.IsActive),
                new SqlParameter("@user", "api"));

            return Results.Ok(await FindRuleAsync(db, id));
        }).WithName("UpdateAlertRule");

        // The grid's own Save button (an edit on an existing row, as opposed to
        // AddRow's POST) calls DataService.patch(), not .edit() - PUT above is
        // unused by the actual UI but kept for direct API callers.
        rules.MapPatch("/{id:int}", async (int id, AlertRulePatchInput input, AppDbContext db) =>
        {
            if (await FindRuleAsync(db, id) is null)
                return Results.NotFound();

            if (!string.IsNullOrWhiteSpace(input.RuleCode) &&
                await CodeExistsAsync(db, input.RuleCode.Trim(), id))
                return Results.Conflict(new { message = $"Rule code '{input.RuleCode}' already exists." });

            await db.Database.ExecuteSqlRawAsync(
                """
                UPDATE dbo.HH_AlertRule
                SET RuleCode          = ISNULL(@code, RuleCode),
                    RuleName          = ISNULL(@name, RuleName),
                    RuleType          = ISNULL(@type, RuleType),
                    ThresholdValue    = ISNULL(@threshold, ThresholdValue),
                    ComparePeriodDays = ISNULL(@period, ComparePeriodDays),
                    ScopeSalesmanNo   = @scope,
                    ScopeCustomerNo   = @customerScope,
                    NotifyTarget      = ISNULL(@notify, NotifyTarget),
                    Severity          = ISNULL(@severity, Severity),
                    IsActive          = ISNULL(@active, IsActive),
                    ModifiedOn        = GETDATE(),
                    ModifiedBy        = @user
                WHERE RuleID = @id
                """,
                new SqlParameter("@id", id),
                new SqlParameter("@code", string.IsNullOrWhiteSpace(input.RuleCode)
                    ? DBNull.Value : input.RuleCode.Trim()),
                new SqlParameter("@name", (object?)input.RuleName?.Trim() ?? DBNull.Value),
                new SqlParameter("@type", (object?)input.RuleType ?? DBNull.Value),
                new SqlParameter("@threshold", (object?)input.ThresholdValue ?? DBNull.Value),
                new SqlParameter("@period", (object?)input.ComparePeriodDays ?? DBNull.Value),
                // Unlike the other fields here, a null scope is a real, settable
                // value (unscope a rule back to "All"), not "leave unchanged" -
                // NormalizeScope folds both null and '' (the frontend's "All"
                // dropdown value) to the same NULL rather than preserving the
                // old value the way ISNULL does for everything else above.
                new SqlParameter("@scope", (object?)NormalizeScope(input.ScopeSalesmanNo) ?? DBNull.Value),
                new SqlParameter("@customerScope", (object?)NormalizeScope(input.ScopeCustomerNo) ?? DBNull.Value),
                new SqlParameter("@notify", (object?)input.NotifyTarget ?? DBNull.Value),
                new SqlParameter("@severity", (object?)input.Severity ?? DBNull.Value),
                new SqlParameter("@active", (object?)input.IsActive ?? DBNull.Value),
                new SqlParameter("@user", "api"));

            return Results.Ok(await FindRuleAsync(db, id));
        }).WithName("PatchAlertRule");

        rules.MapDelete("/{id:int}", async (int id, AppDbContext db) =>
        {
            if (await FindRuleAsync(db, id) is null)
                return Results.NotFound();

            // Alerts are derived data - they mean nothing once their rule is
            // gone, and the FK would block the delete otherwise. One statement
            // batch so we never strand a rule with orphaned alerts.
            await db.Database.ExecuteSqlRawAsync(
                """
                DELETE FROM dbo.HH_AlertLog  WHERE RuleID = @id;
                DELETE FROM dbo.HH_AlertRule WHERE RuleID = @id;
                """,
                new SqlParameter("@id", id));

            return Results.NoContent();
        }).WithName("DeleteAlertRule");

        /* ------------------------------------------------------ the engine */

        rules.MapPost("/evaluate", async (AppDbContext db) =>
        {
            var result = await db.Database.SqlQueryRaw<EvaluationResult>(
                "EXEC dbo.usp_EvaluateAlertRules @BUID = NULL, @RunBy = @user",
                new SqlParameter("@user", "api"))
                .ToListAsync();

            return Results.Ok(result.FirstOrDefault());
        }).WithName("EvaluateAlertRules");

        /* ---------------------------------------------------------- alerts */

        alerts.MapGet("/", async (AppDbContext db, string? status) =>
        {
            // "open" (default) hides resolved noise; "all" shows full history.
            // Passed as a parameter rather than spliced into the SQL text - it
            // keeps the query plan cached and leaves no interpolation for a
            // future edit to turn into an injection point.
            var includeResolved = string.Equals(status, "all", StringComparison.OrdinalIgnoreCase) ? 1 : 0;

            return await db.Database.SqlQueryRaw<AlertLogRow>("""
                SELECT
                    l.AlertID, l.RuleID, r.RuleCode, r.RuleName,
                    l.CustomerNo,
                    CustomerName = c.CustomerNameE,
                    c.SalesmanNo,
                    l.AlertDate,
                    LastOrderDate = (SELECT MAX(o.OrderDate) FROM dbo.HH_SalesOrder o WHERE o.CustomerNo = l.CustomerNo),
                    l.MetricValue, l.AlertMessage, l.AlertMessageA,
                    l.Severity,
                    SeverityText = CASE l.Severity WHEN 3 THEN 'High' WHEN 2 THEN 'Medium' ELSE 'Low' END,
                    l.Status,
                    StatusText   = CASE l.Status WHEN 1 THEN 'New' WHEN 2 THEN 'Acknowledged' ELSE 'Resolved' END
                FROM dbo.HH_AlertLog l
                JOIN dbo.HH_AlertRule r ON r.RuleID = l.RuleID
                LEFT JOIN dbo.HH_Customer c ON c.CustomerNo = l.CustomerNo
                WHERE @includeResolved = 1 OR l.Status IN (1, 2)
                ORDER BY l.Severity DESC, l.AlertDate DESC
                """,
                new SqlParameter("@includeResolved", includeResolved)).ToListAsync();
        }).WithName("GetAlerts");

        alerts.MapPatch("/{id:long}/status/{status:int}", async (long id, int status, AppDbContext db) =>
        {
            // Only forward transitions. Re-opening a resolved alert would clash
            // with UX_HH_AlertLog_Open if another alert is already open for the
            // same rule and customer - and the engine re-raises it anyway.
            if (status is not (2 or 3))
                return Results.BadRequest(new { message = "Status must be 2 (acknowledged) or 3 (resolved)." });

            var affected = await db.Database.ExecuteSqlRawAsync(
                """
                UPDATE dbo.HH_AlertLog
                SET Status     = @status,
                    ResolvedOn = CASE WHEN @status = 3 THEN GETDATE() ELSE ResolvedOn END,
                    ModifiedOn = GETDATE(),
                    ModifiedBy = @user
                WHERE AlertID = @id AND Status < @status
                """,
                new SqlParameter("@id", id),
                new SqlParameter("@status", status),
                new SqlParameter("@user", "api"));

            return affected == 0
                ? Results.BadRequest(new { message = "Alert not found, or it is already at or past that status." })
                : Results.NoContent();
        }).WithName("SetAlertStatus");
    }

    // The frontend's Scope dropdown sends '' for "no scope" (a select column
    // can't bind a real null) - treat that the same as null so every unscoped
    // rule ends up NULL in the database, not a mix of NULL and ''.
    private static string? NormalizeScope(string? scope) =>
        string.IsNullOrWhiteSpace(scope) ? null : scope.Trim();

    private static async Task<AlertRule?> FindRuleAsync(AppDbContext db, int id)
    {
        var rows = await db.Database.SqlQueryRaw<AlertRule>(
            $"SELECT {RuleColumns} FROM dbo.HH_AlertRule WHERE RuleID = @id",
            new SqlParameter("@id", id)).ToListAsync();
        return rows.FirstOrDefault();
    }

    private static async Task<bool> CodeExistsAsync(AppDbContext db, string code, int? excludeId)
    {
        var rows = await db.Database.SqlQueryRaw<int>(
            "SELECT COUNT(*) AS Value FROM dbo.HH_AlertRule WHERE RuleCode = @code AND (@id IS NULL OR RuleID <> @id)",
            new SqlParameter("@code", code),
            new SqlParameter("@id", (object?)excludeId ?? DBNull.Value)).ToListAsync();
        return rows[0] > 0;
    }
}
