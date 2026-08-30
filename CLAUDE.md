# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Two independently-versioned projects in one folder, built on top of proprietary SalesBuzz/BI packages supplied out-of-band (not on public npm/NuGet):

- **`app/`** — Angular 20 frontend. Currently one real feature: a business-units dashboard (`app/src/app/business-units/`) that calls the API and renders a table.
- **`api/`** — ASP.NET Core 10 Web API. Wraps a SQL Server database (`MO_ASHRAF`) via EF Core, using the `BI-SDK` package's `SalesBuzzDbContextBase`.

There is no git repository here yet.

## Commands

### Docker (whole stack) — see `DOCKER.md`
```bash
docker compose up             # db + API + frontend; app on :4200, API on :5228, SQL on :1434
```
`api/` and `app/` are bind-mounted and both dev servers run in watch mode, so **source edits are picked up live — no rebuild**. Only dependency changes (`package.json`, `api.csproj`) need `docker compose up --build`.

Two things that are easy to get wrong here:
- **SQL Server publishes to host 1434, not 1433.** This machine runs a native SQL Server on 1433 with unrelated databases; publishing to 1433 leaves two listeners on one port and makes `localhost:1433` ambiguous. The container DB is a separate copy of `MO_ASHRAF` — the native instance is untouched, and the host-native workflow below still works unchanged.
- **File watching must poll** (`DOTNET_USE_POLLING_FILE_WATCHER=true`, `ng serve --poll`). Docker Desktop on Windows does not deliver inotify events across bind mounts, so event-based watching silently never fires.

The Windows-Auth connection string in `appsettings.json` cannot work in a Linux container; compose overrides it with SQL auth via `ConnectionStrings__DefaultConnection` rather than editing the file, so both workflows coexist.

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
- Two further scripts live in `db/` and are applied on top, in order. Both are idempotent, and both **must be run with `sqlcmd -I`** (or an equivalent `SET QUOTED_IDENTIFIER ON`) — they create a persisted computed column and a filtered index, and SQL Server refuses both when sqlcmd's default `QUOTED_IDENTIFIER OFF` is in effect:
  ```bash
  sqlcmd -S localhost -E -d MO_ASHRAF -f 65001 -I -i db/02_Demo_Data.sql
  sqlcmd -S localhost -E -d MO_ASHRAF -f 65001 -I -i db/03_Alert_Rules.sql
  ```
  - `db/02_Demo_Data.sql` — the SUPSEAL Nutrition demo dataset (3 salesmen, 6 supplement SKUs, 12 gym/supplement-shop customers, ~68 orders). It also creates `HH_SalesOrder`/`HH_SalesOrderDetail`, which the SDK's minimal schema does not ship. **Order dates are relative to `GETDATE()`, never hard-coded**, and the customer behaviour is deliberately shaped so the alert rules have something true to find (three customers silent 38/48/65 days, two with a >60% revenue drop, the rest healthy). Re-running re-anchors those dates to today; leaving it un-run for weeks lets the windows drift.
  - `db/03_Alert_Rules.sql` — `HH_AlertRule`, `HH_AlertLog`, and `usp_EvaluateAlertRules`. See the alert-rules section below.
- Column naming trap: **`LineNo` is a reserved T-SQL keyword** (`SET LINENO`). `HH_SalesOrderDetail` uses `LineNumber`.

## Architecture

### Package provenance — read this before adding dependencies
The three npm packages (`bi-interfaces`, `bi-modules`, `@salesbuzz/public-sdk`) and the one NuGet package (`BI-SDK`) are **not** published to public registries. They're installed from local files:
- `app/package.json` depends on them via `file:../Packages/npm/*.tgz`, with matching entries under `"overrides"` — required because `@salesbuzz/public-sdk` declares a dependency on `bi-modules@^0.0.3` (a version that was never published; the `overrides` block forces resolution to the local `.tgz` instead of failing against the npm registry).
- `api/api.csproj` depends on `BI-SDK` (0.2.0) resolved from a NuGet source named `local-bi-sdk` pointing at `Packages/nuget/`. This is registered in the repo's own `nuget.config` with a path relative to that file, so `dotnet restore` works in a fresh clone and inside a container with no setup step. (It is *also* still registered machine-wide in `%APPDATA%\NuGet\NuGet.Config` from before the repo-local config existed; that entry is now redundant.)
- `Packages/` holds the original files these were unpacked from; leave it in place.

### Frontend dependency footprint
`bi-modules` peer-depends on Angular Material/CDK, Kendo UI Angular (a large multi-package suite), `@ngx-translate/core`, `@angular/animations`, `moment`, and Bootstrap. Most of Kendo's own inter-package peer dependencies (`kendo-angular-utils`, `-navigation`, `-progressbar`, `-indicators`, `-menu`, `-excel-export`, `-pdf-export`, `-conversational-ui`, `kendo-drawing`) are **not** auto-installed by npm because they're declared as `peerDependencies`, not `dependencies` — they were added explicitly to `app/package.json` at the exact version (`20.1.2`) Kendo's own packages pin. Installs need `--legacy-peer-deps` due to unresolved cross-package Angular version ranges.

`app/angular.json`'s production `initial` bundle budget was raised to 7MB warn / 9MB error (default is 500kB/1MB) — any real screen built on `bi-modules` will exceed Angular's default budget. Alerts & Alert Rules (`app/src/app/alerts/`) uses the SDK's actual `BI-Grid` (`BIGridComponent` from `bi-modules`) rather than plain HTML tables — see `app/src/app/core/api-grid-data-source.ts` for the `IDataSource` adapter that feeds it from the API, and `app/src/app/core/http-api-client.ts` for the `PublicApiClient` (`@salesbuzz/public-sdk`) implementation backing it. `app/src/app/app.config.ts` registers the extra providers `BIGridComponent` needs that `BIModulesModule` doesn't itself supply correctly:
- `provideAnimations()` and `TranslateModule.forRoot()` (`TranslateService` is injected but never provided).
- `MessageService` from `@progress/kendo-angular-l10n`, provided directly at root — `BIModulesModule`'s own providers array registers a *different* class that also happens to be named `MessageService` (a bundling/naming collision inside `bi-modules`'s compiled output), so its internal registration doesn't satisfy what `BIGridComponent`/`BIModulesService` actually ask for.
- `'CreateDialog'` as a **factory-returning-a-factory**: `{ provide: 'CreateDialog', useFactory: () => () => new CreateDialog() }`. `BIGridComponent` injects this string token and calls it as `this._dialog()` — it wants a function, not a `CreateDialog` instance directly.

**`bi-modules` reads `localStorage.getItem('lang')` for `LOCALE_ID`** — its module providers register `{ provide: LOCALE_ID, useFactory: () => localStorage.getItem('lang') }`. If that key is unset, `LOCALE_ID` resolves to `null` and Kendo's `CldrIntlService` constructor crashes (`Cannot read properties of null (reading 'replace')`) the moment any `bi-modules` component (e.g. `BI-Grid`) is instantiated. `app/src/main.ts` seeds `localStorage.setItem('lang', 'en-US')` before `bootstrapApplication` to work around this — don't remove it without replacing it with an equivalent language-selection step.

**Every `IColumns` entry passed to `BI-Grid` must set `controlType`** (from `ControlTypes`, e.g. `ControlTypes.Text`/`ControlTypes.Number`) — `BIGridComponent`'s own template renders each column via `*ngSwitchCase` on `res.controlType` (`'text'`, `'numeric'`/`'number'`, `'date'`, etc.). A column with no `controlType` matches no case and never renders as an actual `<kendo-grid-column>`; if that leaves zero real leaf columns, Kendo throws `Error: Invalid column 0.` from `GridComponent.editCell` the moment data arrives (`BIGridComponent.GetGridData()` auto-selects the first cell once `data.total > 0`).

**`@angular/localize` is a required runtime dependency, not just a build-time i18n tool** — `bi-modules`/Material internals use `$localize` tagged templates, which throw `ReferenceError: $localize is not defined` unless the polyfill is loaded. `app/src/main.ts` imports `'@angular/localize/init'` as its first line for this reason; `@angular/localize` is an explicit dependency in `app/package.json`.

### Backend: SalesBuzz SDK conventions
- `AppDbContext` (`api/AppDbContext.cs`) derives from `BI-SDK`'s `SalesBuzzDbContextBase`, which already maps the shared security/audit tables (permissions, sessions, licenses, audit logs, number sequences) and overrides `SaveChanges` to write audit logs via the `Get_AuditCriteria` stored procedure. Its constructor requires an `ICurrentBUContext`.
- **Don't add your own `DbSet<T>`/`OnModelCreating` mapping for a table the base context (or SDK-internal entities like `BUCTRL`) already owns** — EF's shared-table validation throws (`RelationalModelValidator`) if two unrelated entity types map to the same table without a linking FK. Query those tables with `db.Database.SqlQueryRaw<TDto>("...")` against a plain POCO instead (see `api/Models/BusinessUnit.cs` + the `/api/business-units` endpoint in `Program.cs` for the pattern).
- Program.cs wiring required for the SDK to resolve at startup: `AddMemoryCache()` (the permission engine's `IPermissions` needs `IMemoryCache`), `AddSalesBuzzCurrentBU()`, `AddSalesBuzzDb<AppDbContext>(configuration)`. Other SDK extensions available but not yet wired: `AddSalesBuzzJwt`, `AddSalesBuzzExceptionHandling`/`UseSalesBuzzExceptionHandling`, `UseSalesBuzzTokenValidation`, `AddSalesBuzzOData`.
- CORS is configured for `http://localhost:4200` only (the Angular dev server origin).

### Frontend structure
Angular 20 standalone-component style (no `NgModule`s). Routes live in `app/src/app/app.routes.ts`; `app/src/app/app.html` renders `<Bi-Sidebar>` (real SDK navigation) beside a `<router-outlet />`. `provideHttpClient()` is registered in `app.config.ts`. The API origin, the `col()` helper for building `IColumns`, and `selectCol()` for dropdown-editable columns live in `app/src/app/core/api.ts` — there is no environment-file abstraction yet, so that constant is the one place the origin is written down.

One screen: `/alerts` (Alerts list + Alert Rules, the latter with full `<BI-Nav>` + `<BI-Grid>` CRUD). The old Customers & Business Units page (`/customers`, read-only `<BI-Grid>`s over `/api/customers` and `/api/business-units`) was removed from the frontend; those two API endpoints are still live (`/api/business-units` still backs the `<BI-Nav>` "Info" button's BU lookup via `HttpNavInfo`) but have no other UI caller now. The old `/alert-rules` route still redirects into `/alerts`.

**Every `<BI-Grid>` needs `(OnLoadData)="grid.Mygrid?.closeCell()"`** (with a `#grid` template ref) — see the note further down; unchanged from earlier.

### Using `<BI-Nav>` + `<BI-SideBar>` — undocumented, reverse-engineered from the compiled bundle

Getting past `<BI-Grid>` alone to the *actual* SalesBuzz screen chrome (the toolbar with Add/Save/Delete/Cancel/Attachments/Info, and the icon sidebar) surfaced several gotchas with no source docs anywhere - all found by reading `bi-modules`' compiled `.mjs` directly:

- **`BiNavComponent`'s toolbar buttons hardcode `imageUrl="assets/icons/xyz.svg"` paths relative to *the consuming app*, not the package.** They are not bundled by Angular's build - they're plain `<img>` tags expecting the file to exist in the app's own static assets. Fix: the entire `bi-modules/assets/icons/` folder (131 files) is copied wholesale into `app/public/assets/icons/` (see below) rather than cherry-picking - the exact set BiNavComponent/BISideBarComponent/BIModalComponent reference includes filenames with spaces and parens (`"save_black_24dp (2).svg"`), so copying everything is far less error-prone than trying to enumerate every reference across the bundle.
- **`Bi-Sidebar`'s logo image is hardcoded to `assets/images/buzz-logo-menu.png`**, which the package does not ship (it's the real product's own branding, reasonably not included in a component library). `app/public/assets/images/buzz-logo-menu.png` here is a 1×1 transparent placeholder rather than a 404 - replace with a real logo if one matters.
- **`Bi-Sidebar`'s `IMenuItem.icon` renders as `<img [src]="item.icon">`**, not an icon font/class - point it at a real image path (e.g. `assets/icons/Dashboard.svg`, one of the copied files).
- **`BiNavComponent` requires a `NavInfo` provider** (from `bi-interfaces`) - it's declared as an abstract class with no implementation, injected by token, exactly like `PublicApiClient`. Its one method, `getBUDesc(buid): Observable<string>` (not a Promise - the caller does `.subscribe()` directly), backs the "Info" toolbar button's business-unit lookup. `app/src/app/core/nav-info.ts` (`HttpNavInfo`) implements it against `/api/business-units`; registered in `app.config.ts` as `{ provide: NavInfo, useClass: HttpNavInfo }`.
- **`<BI-Nav [BIGrid]="grid">` drives the grid directly**: its Add/Save/Delete/Cancel buttons call `this.BIGrid.AddRow()/Save()/DeleteRow()/Cancel()` - methods `BIGridComponent` already implements (`IGridBase`). This means BI-Nav *replaces* any custom add/edit form entirely - the real editing UX is Kendo's own inline cell editing on the grid, triggered by the toolbar. Delete confirmation is SweetAlert2, shown automatically when `[deleteConfirmMsg]="true"`.
- **`navButtons: INavBtn` visibility defaults are asymmetric** - Add/Save/Delete/Cancel/Info/Attach/ColView default to *visible* (must be explicitly hidden: `{ attach: { visibility: false, disable: false } }`), while Print/HistoryData/WorkFlow default to *hidden* (must be explicitly shown). Attach is switched off here since there's no attachment-storage table for these entities.
- **Dropdown-editable columns** (`ControlTypes.Select`) need `dropDownTemplate: { value: 'value', text: 'text', list: [...] }` where `value`/`text` are the *field names* to read off each `list` item (confirmed from the compiled template: `[textField]="res.dropDownTemplate.text"`), not literal values - hence `list` items are shaped exactly `{ value, text }` to match. See `selectCol()` in `core/api.ts`.
- **`ControlTypes.CheckBox` (`'checkbox'`) matches no case in `BIGridComponent`'s own template** - it only switches on the literal string `'boolean'`, and no `ControlTypes` enum member has that value. A boolean column needs `'boolean' as ControlTypes` cast past the interface rather than `ControlTypes.CheckBox`, or it silently renders no column (same failure mode as an entirely missing `controlType`).
- **`.claude/launch.json`'s `bi-app` config gets overwritten if a different checkout of this repo is used** - it happened mid-project here (a separate, git-tracked copy of this same idea exists at the *original* OneDrive path this project started at, with its own unrelated `.claude/launch.json` pointing `--prefix` at itself). Since `preview_start({name})` always resolves `.claude/launch.json` from the session's original working directory regardless of where the project has actually been moved to, check that file's `runtimeArgs` --prefix path first if the Browser preview ever starts serving unfamiliar routes/components - it may be launching an entirely different project on the same port.

**Every `<BI-Grid>` needs `(OnLoadData)="grid.Mygrid?.closeCell()"`** (with a `#grid` template ref). `BIGridComponent` calls `Mygrid.editCell(0, 0, …)` the moment data arrives, which leaves the first cell of the first row rendered as a *disabled Kendo textbox* rather than plain text — the value is present but invisible to `innerText`, and it looks broken next to the other cells. `OnLoadData` is emitted immediately after that call, so closing the cell there is the cheapest correct fix.

## Smart Customer Alert Rules

A rules engine, not a CRUD screen: a manager defines rules, and the engine evaluates them against order history to raise, refresh and close alerts.

- **The engine is `usp_EvaluateAlertRules`, not C#.** Every rule is a set-based aggregate over `HH_SalesOrder`; evaluating row-by-row in the API would mean pulling the whole order history over the wire. It also matches the SDK's own convention (`Get_AuditCriteria` is a proc).
- **Idempotency is enforced by the database.** `UX_HH_AlertLog_Open` is a filtered unique index permitting one *open* (status 1 or 2) alert per `(RuleID, CustomerNo)`. Running the engine a hundred times cannot duplicate an alert, regardless of what the caller does.
- **Alerts auto-resolve.** Each run rebuilds the full match set in `#Match`; open alerts absent from it are closed. So a "lost" customer who places an order clears their own alert on the next run — no manual cleanup.
- **`SALES_DROP_PCT` deliberately skips customers with zero recent sales.** They read as a 100% drop, but they are churn, which `NO_ORDER_DAYS` already reports. Double-alerting the same customer under two rules is how alerting systems train their users to ignore them.
- **Adding a rule type** = one more `INSERT` block into `#Match` plus an entry in the `CK_HH_AlertRule_Type` check constraint. A "low stock" rule would additionally need an inventory table, which this schema does not have.
- API lives in `api/Endpoints/AlertEndpoints.cs` (parameterised raw SQL, for the same reason the other endpoints use it). `POST /api/alert-rules/evaluate` runs the engine; `GET /api/alerts/summary` backs the dashboard cards.
- `app/src/app/core/api-grid-data-source.ts` now implements real CRUD (`add`/`edit`/`patch`/`delete` → POST/PUT/PATCH/DELETE). Display-only screens pass `readOnly: true` so a stray grid action cannot mutate them; `mapRow` adds display-friendly fields without pushing presentation into the API.
