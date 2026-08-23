using api;
using api.Endpoints;
using api.Models;
using Microsoft.EntityFrameworkCore;
using SalesBuzz.Shared.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddMemoryCache();
builder.Services.AddSalesBuzzCurrentBU();
builder.Services.AddSalesBuzzDb<AppDbContext>(builder.Configuration);

const string AngularClient = "AngularClient";
builder.Services.AddCors(options =>
{
    options.AddPolicy(AngularClient, policy =>
        policy.WithOrigins("http://localhost:4200").AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors(AngularClient);
app.UseHttpsRedirection();

app.MapGet("/api/business-units", async (AppDbContext db) =>
    await db.Database
        .SqlQueryRaw<BusinessUnit>(
            "SELECT BUID, Description, DescriptionA, ParentBU, Level, ShortCode FROM HH_SA_BU ORDER BY BUID")
        .ToListAsync())
    .WithName("GetBusinessUnits");

app.MapGet("/api/customers", async (AppDbContext db) =>
    await db.Database
        .SqlQueryRaw<Customer>(
            "SELECT CustomerNo, CustomerNameE, CustomerNameA, SalesmanNo, BUID, Mobile, Address, InActive FROM HH_Customer ORDER BY CustomerNo")
        .ToListAsync())
    .WithName("GetCustomers");

app.MapInactiveCustomerAlertRuleEndpoints();
app.MapInactiveCustomerAlertEndpoints();

app.Run();
