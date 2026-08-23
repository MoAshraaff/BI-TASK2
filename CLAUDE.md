# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Two independently-versioned projects in one folder, built on top of proprietary SalesBuzz/BI packages supplied out-of-band (not on public npm/NuGet):

- **`app/`** — Angular 20 frontend. Currently one real feature: a business-units dashboard (`app/src/app/business-units/`) that calls the API and renders a table.
- **`api/`** — ASP.NET Core 10 Web API. Wraps a SQL Server database (`MO_ASHRAF`) via EF Core, using the `BI-SDK` package's `SalesBuzzDbContextBase`.

There is no git repository here yet.

## Commands

### Frontend (`app/`)
```bash
npm --prefix app start        # dev server on http://localhost:4200
npm --prefix app run build    # production build -> app/dist/app
npm --prefix app test         # Karma/Jasmine unit tests
```
A `.claude/launch.json` config (`bi-app`) runs `npm run start --prefix app` on port 4200 for use with the Browser preview tools.

### Backend (`api/`)
The .NET 10 SDK is **not** on the default PATH on this machine — it was installed to `%LOCALAPPDATA%\Microsoft\dotnet` (separate from the pre-existing .NET 8 SDK under `C:\Program Files\dotnet`). Prepend it before running any `dotnet` command:
```bash
export PATH="/c/Users/$USER/AppData/Local/Microsoft/dotnet:$PATH"
cd api
dotnet build
dotnet run              # http://localhost:5228
```

### Database
- SQL Server (local default instance, Windows auth) hosts a dedicated database **`MO_ASHRAF`** — do not touch the other databases on this instance (`UNIVERSITY`, `NTI`, `Chinook`, `AdventureWorks*`, etc.), they belong to unrelated projects.
- Schema/seed data came from a SalesBuzz-provided `SDK_Minimal_Schema.sql` init script (32 tables + `Get_AuditCriteria` proc + seed rows: BU `C100`, users `demo`/`admin`, roles `user`/`admin`). Re-run that script (with `USE [MO_ASHRAF];`) against a fresh database if you need to reset it — it's idempotent (`IF NOT EXISTS` guards throughout).
- Connection string lives in `api/appsettings.json` under `ConnectionStrings:DefaultConnection`.

## Architecture

### Package provenance — read this before adding dependencies
The three npm packages (`bi-interfaces`, `bi-modules`, `@salesbuzz/public-sdk`) and the one NuGet package (`BI-SDK`) are **not** published to public registries. They're installed from local files:
- `app/package.json` depends on them via `file:../Packages/npm/*.tgz`, with matching entries under `"overrides"` — required because `@salesbuzz/public-sdk` declares a dependency on `bi-modules@^0.0.3` (a version that was never published; the `overrides` block forces resolution to the local `.tgz` instead of failing against the npm registry).
- `api/api.csproj` depends on `BI-SDK` (0.2.0) resolved from a NuGet source named `local-bi-sdk` pointing at `Packages/nuget/`. **This source is registered in the machine-level `%APPDATA%\NuGet\NuGet.Config`, not in the repo** — a fresh checkout on another machine needs `dotnet nuget add source "<repo>\Packages\nuget" -n local-bi-sdk` (use an absolute path; a relative path passed to `dotnet nuget add source` resolves against the NuGet config's own directory, not the cwd) before `dotnet restore` will succeed.
- `Packages/` holds the original files these were unpacked from; leave it in place.

### Frontend dependency footprint
`bi-modules` peer-depends on Angular Material/CDK, Kendo UI Angular (a large multi-package suite), `@ngx-translate/core`, `@angular/animations`, `moment`, and Bootstrap. Most of Kendo's own inter-package peer dependencies (`kendo-angular-utils`, `-navigation`, `-progressbar`, `-indicators`, `-menu`, `-excel-export`, `-pdf-export`, `-conversational-ui`, `kendo-drawing`) are **not** auto-installed by npm because they're declared as `peerDependencies`, not `dependencies` — they were added explicitly to `app/package.json` at the exact version (`20.1.2`) Kendo's own packages pin. Installs need `--legacy-peer-deps` due to unresolved cross-package Angular version ranges.

`app/angular.json`'s production `initial` bundle budget was raised to 4MB warn / 6MB error (default is 500kB/1MB) — any real screen built on `bi-modules` will exceed Angular's default budget.

### Backend: SalesBuzz SDK conventions
- `AppDbContext` (`api/AppDbContext.cs`) derives from `BI-SDK`'s `SalesBuzzDbContextBase`, which already maps the shared security/audit tables (permissions, sessions, licenses, audit logs, number sequences) and overrides `SaveChanges` to write audit logs via the `Get_AuditCriteria` stored procedure. Its constructor requires an `ICurrentBUContext`.
- **Don't add your own `DbSet<T>`/`OnModelCreating` mapping for a table the base context (or SDK-internal entities like `BUCTRL`) already owns** — EF's shared-table validation throws (`RelationalModelValidator`) if two unrelated entity types map to the same table without a linking FK. Query those tables with `db.Database.SqlQueryRaw<TDto>("...")` against a plain POCO instead (see `api/Models/BusinessUnit.cs` + the `/api/business-units` endpoint in `Program.cs` for the pattern).
- Program.cs wiring required for the SDK to resolve at startup: `AddMemoryCache()` (the permission engine's `IPermissions` needs `IMemoryCache`), `AddSalesBuzzCurrentBU()`, `AddSalesBuzzDb<AppDbContext>(configuration)`. Other SDK extensions available but not yet wired: `AddSalesBuzzJwt`, `AddSalesBuzzExceptionHandling`/`UseSalesBuzzExceptionHandling`, `UseSalesBuzzTokenValidation`, `AddSalesBuzzOData`.
- CORS is configured for `http://localhost:4200` only (the Angular dev server origin).

### Frontend structure
Angular 20 standalone-component style (no `NgModule`s). Routes live in `app/src/app/app.routes.ts`; `app/src/app/app.html` is just a `<router-outlet />`. `provideHttpClient()` is registered in `app.config.ts`. Feature components call the API directly with a hardcoded `http://localhost:5228` base URL (no environment-file abstraction yet).
