using api.Models;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SalesBuzz.Shared.Data;

namespace api.Endpoints;

// CRUD for HH_AlertRule rows scoped to RuleType = 'NO_ORDER_DAYS' (the "inactive
// customer" rule type SalesBuzz's own dbo.usp_EvaluateAlertRules engine already
// evaluates). SALES_DROP_PCT rows in the same table are never touched here.
//
// HH_AlertRule is a shared SDK-provided table, not something this project owns
// via an EF DbSet - so, matching the pattern already used for HH_SA_BU/HH_Customer
// (see BusinessUnit.cs/Customer.cs), it's accessed with raw SQL through
// AppDbContext.Database rather than a mapped entity/migration.
public static class InactiveCustomerAlertRuleEndpoints
{
    private const string RuleType = "NO_ORDER_DAYS";
    private const string DefaultNotifyTarget = "MANAGER";

    private const string SelectSql = """
        SELECT ar.RuleID AS Id, ar.RuleCode, ar.RuleName, ar.RuleNameA,
               CAST(ar.ThresholdValue AS int) AS InactiveDays,
               ar.Severity, ar.IsActive, ar.LastRunOn, ar.CreatedOn, ar.Createdby AS CreatedBy, ar.ModifiedOn, ar.ModifiedBy,
               ar.ScopeCustomerNo, sc.CustomerNameE AS ScopeCustomerName
        FROM dbo.HH_AlertRule ar
        LEFT JOIN dbo.HH_Customer sc ON sc.CustomerNo = ar.ScopeCustomerNo
        WHERE ar.RuleType = @RuleType
        """;

    public static void MapInactiveCustomerAlertRuleEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/inactive-customer-alert-rules");

        group.MapGet("/", GetAll).WithName("GetInactiveCustomerAlertRules");
        group.MapGet("/{id:int}", GetById).WithName("GetInactiveCustomerAlertRuleById");
        group.MapPost("/", Create).WithName("CreateInactiveCustomerAlertRule");
        group.MapPut("/{id:int}", Update).WithName("UpdateInactiveCustomerAlertRule");
        group.MapDelete("/{id:int}", Delete).WithName("DeleteInactiveCustomerAlertRule");
    }

    private static async Task<Ok<List<InactiveCustomerAlertRuleDto>>> GetAll(AppDbContext db, CancellationToken ct)
    {
        var rows = await db.Database
            .SqlQueryRaw<InactiveCustomerAlertRuleRow>(
                SelectSql + " ORDER BY ar.RuleID",
                new SqlParameter("@RuleType", RuleType))
            .ToListAsync(ct);

        return TypedResults.Ok(rows.Select(InactiveCustomerAlertRuleDto.FromRow).ToList());
    }

    private static async Task<Results<Ok<InactiveCustomerAlertRuleDto>, NotFound>> GetById(int id, AppDbContext db, CancellationToken ct)
    {
        var row = await FindRowAsync(db, id, ct);
        return row is null ? TypedResults.NotFound() : TypedResults.Ok(InactiveCustomerAlertRuleDto.FromRow(row));
    }

    private static async Task<Results<Created<InactiveCustomerAlertRuleDto>, ValidationProblem, Conflict<object>>> Create(
        InactiveCustomerAlertRuleRequest request, AppDbContext db, ICurrentBUContext current, CancellationToken ct)
    {
        if (!TryValidate(request, out var errors))
            return TypedResults.ValidationProblem(errors);

        var buid = await ResolveCurrentBUIDAsync(db, current, ct);
        var ruleCode = GenerateRuleCode(request.RuleName);
        var createdBy = string.IsNullOrWhiteSpace(current.GetUserName()) ? "api-user" : current.GetUserName();

        const string insertSql = """
            INSERT INTO dbo.HH_AlertRule
                (RuleCode, RuleName, RuleNameA, RuleType, ThresholdValue, NotifyTarget, Severity, IsActive, BUID, CreatedOn, Createdby, ScopeCustomerNo)
            OUTPUT INSERTED.RuleID AS Value
            VALUES
                (@RuleCode, @RuleName, @RuleNameA, @RuleType, @ThresholdValue, @NotifyTarget, @Severity, @IsActive, @BUID, GETDATE(), @CreatedBy, @ScopeCustomerNo)
            """;

        try
        {
            // ToListAsync (not SingleAsync) - SingleAsync composes an outer TOP(2)
            // query for the round-trip check, and SQL Server can't compose over
            // an INSERT...OUTPUT statement.
            var insertedIds = await db.Database
                .SqlQueryRaw<int>(insertSql,
                    new SqlParameter("@RuleCode", ruleCode),
                    new SqlParameter("@RuleName", request.RuleName),
                    new SqlParameter("@RuleNameA", (object?)request.RuleNameA ?? DBNull.Value),
                    new SqlParameter("@RuleType", RuleType),
                    new SqlParameter("@ThresholdValue", (decimal)request.InactiveDays),
                    new SqlParameter("@NotifyTarget", DefaultNotifyTarget),
                    new SqlParameter("@Severity", (byte)request.Priority),
                    new SqlParameter("@IsActive", (byte)(request.IsActive ? 1 : 0)),
                    new SqlParameter("@BUID", buid),
                    new SqlParameter("@CreatedBy", createdBy),
                    new SqlParameter("@ScopeCustomerNo", (object?)NormalizeScope(request.ScopeCustomerNo) ?? DBNull.Value))
                .ToListAsync(ct);
            var newId = insertedIds.Single();

            var row = await FindRowAsync(db, newId, ct);
            var dto = InactiveCustomerAlertRuleDto.FromRow(row!);
            return TypedResults.Created($"/api/inactive-customer-alert-rules/{dto.Id}", dto);
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            return TypedResults.Conflict((object)new { message = "A rule with this code already exists. Please try again." });
        }
    }

    private static async Task<Results<Ok<InactiveCustomerAlertRuleDto>, ValidationProblem, NotFound>> Update(
        int id, InactiveCustomerAlertRuleRequest request, AppDbContext db, ICurrentBUContext current, CancellationToken ct)
    {
        if (!TryValidate(request, out var errors))
            return TypedResults.ValidationProblem(errors);

        var modifiedBy = string.IsNullOrWhiteSpace(current.GetUserName()) ? "api-user" : current.GetUserName();

        const string updateSql = """
            UPDATE dbo.HH_AlertRule
            SET RuleName = @RuleName,
                RuleNameA = @RuleNameA,
                ThresholdValue = @ThresholdValue,
                Severity = @Severity,
                IsActive = @IsActive,
                ModifiedOn = GETDATE(),
                ModifiedBy = @ModifiedBy,
                ScopeCustomerNo = @ScopeCustomerNo
            WHERE RuleID = @Id AND RuleType = @RuleType
            """;

        var affected = await db.Database.ExecuteSqlRawAsync(updateSql,
            [
                new SqlParameter("@RuleName", request.RuleName),
                new SqlParameter("@RuleNameA", (object?)request.RuleNameA ?? DBNull.Value),
                new SqlParameter("@ThresholdValue", (decimal)request.InactiveDays),
                new SqlParameter("@Severity", (byte)request.Priority),
                new SqlParameter("@IsActive", (byte)(request.IsActive ? 1 : 0)),
                new SqlParameter("@ModifiedBy", modifiedBy),
                new SqlParameter("@Id", id),
                new SqlParameter("@RuleType", RuleType),
                new SqlParameter("@ScopeCustomerNo", (object?)NormalizeScope(request.ScopeCustomerNo) ?? DBNull.Value)
            ], ct);

        if (affected == 0)
            return TypedResults.NotFound();

        var row = await FindRowAsync(db, id, ct);
        return TypedResults.Ok(InactiveCustomerAlertRuleDto.FromRow(row!));
    }

    private static async Task<Results<NoContent, NotFound, Conflict<object>>> Delete(int id, AppDbContext db, CancellationToken ct)
    {
        try
        {
            var affected = await db.Database.ExecuteSqlRawAsync(
                "DELETE FROM dbo.HH_AlertRule WHERE RuleID = @Id AND RuleType = @RuleType",
                [new SqlParameter("@Id", id), new SqlParameter("@RuleType", RuleType)], ct);

            return affected == 0 ? TypedResults.NotFound() : TypedResults.NoContent();
        }
        catch (SqlException ex) when (ex.Number == 547)
        {
            return TypedResults.Conflict((object)new { message = "This rule has alert history and cannot be deleted. Deactivate it instead." });
        }
    }

    private static Task<InactiveCustomerAlertRuleRow?> FindRowAsync(AppDbContext db, int id, CancellationToken ct) =>
        db.Database
            .SqlQueryRaw<InactiveCustomerAlertRuleRow>(
                SelectSql + " AND ar.RuleID = @Id",
                new SqlParameter("@RuleType", RuleType), new SqlParameter("@Id", id))
            .SingleOrDefaultAsync(ct);

    private static async Task<string> ResolveCurrentBUIDAsync(AppDbContext db, ICurrentBUContext current, CancellationToken ct)
    {
        var buid = current.GetUserBUID();
        if (!string.IsNullOrWhiteSpace(buid)) return buid;

        // No authenticated principal is wired up yet (see CLAUDE.md), so fall
        // back to the only/first business unit rather than failing the write.
        var fallback = await db.Database
            .SqlQueryRaw<string>("SELECT TOP 1 BUID AS Value FROM dbo.HH_SA_BU ORDER BY BUID")
            .SingleOrDefaultAsync(ct);

        return fallback ?? throw new InvalidOperationException("No business unit is configured for HH_SA_BU.");
    }

    // RuleCode is nvarchar(40) - sys.columns reports nvarchar length in bytes
    // (2/char), so its actual capacity is 20 characters. Leave room for "-XXXX".
    private static string GenerateRuleCode(string ruleName)
    {
        var slug = new string(ruleName.ToUpperInvariant().Select(c => char.IsLetterOrDigit(c) ? c : '-').ToArray());
        while (slug.Contains("--")) slug = slug.Replace("--", "-");
        slug = slug.Trim('-');
        if (slug.Length == 0) slug = "RULE";
        if (slug.Length > 14) slug = slug[..14].TrimEnd('-');

        var suffix = Guid.NewGuid().ToString("N")[..4].ToUpperInvariant();
        return $"{slug}-{suffix}";
    }

    // Empty string from the "All Customers" option should mean unscoped, same as null.
    private static string? NormalizeScope(string? scopeCustomerNo) =>
        string.IsNullOrWhiteSpace(scopeCustomerNo) ? null : scopeCustomerNo.Trim();

    private static bool TryValidate(InactiveCustomerAlertRuleRequest request, out IDictionary<string, string[]> errors)
    {
        var e = new Dictionary<string, string[]>();

        // RuleName/RuleNameA are nvarchar(200) - i.e. 100 characters (sys.columns
        // reports nvarchar length in bytes, 2 per character).
        if (string.IsNullOrWhiteSpace(request.RuleName))
            e["ruleName"] = ["Rule name is required."];
        else if (request.RuleName.Length > 100)
            e["ruleName"] = ["Rule name must be 100 characters or fewer."];

        if (!string.IsNullOrEmpty(request.RuleNameA) && request.RuleNameA.Length > 100)
            e["ruleNameA"] = ["Arabic rule name must be 100 characters or fewer."];

        if (request.InactiveDays <= 0)
            e["inactiveDays"] = ["Inactive days must be greater than 0."];

        if (!Enum.IsDefined(request.Priority))
            e["priority"] = ["Priority must be Low, Medium, or High."];

        // ScopeCustomerNo is nvarchar(30) - i.e. 30 characters.
        if (NormalizeScope(request.ScopeCustomerNo) is { Length: > 30 })
            e["scopeCustomerNo"] = ["Customer number must be 30 characters or fewer."];

        errors = e;
        return e.Count == 0;
    }
}
