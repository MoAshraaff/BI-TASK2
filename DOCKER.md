# Running the whole project in Docker

Everything - database, API and frontend - runs in containers. Nothing needs to
be installed on the host except Docker Desktop.

```bash
docker compose up
```

Then open **http://localhost:4200**.

| Service | URL / port | Notes |
|---|---|---|
| Angular app | http://localhost:4200 | |
| API | http://localhost:5228 | |
| SQL Server | `localhost,1434` (user `sa`) | **1434**, not 1433 - see below |

First run takes several minutes: it pulls the SQL Server image, restores NuGet
packages and runs `npm install`. Later runs start in seconds because the images
and the `node_modules` volume are cached.

## Live code editing

`api/` and `app/` are bind-mounted into their containers, and both dev servers
run in watch mode. **Edit a file on your machine and the running container
picks it up - no rebuild, no restart.** That applies to any new file too.

File watching uses polling (`DOTNET_USE_POLLING_FILE_WATCHER`, `ng serve
--poll`) because Docker Desktop on Windows does not deliver filesystem events
across a bind mount. Polling costs a little CPU; it is the only thing that
works reliably here.

You only need `docker compose build` again when **dependencies** change -
`package.json` or `api.csproj`. Source changes never need it.

## Which port for SQL Server, and why not 1433

This machine already runs a native SQL Server on 1433 holding unrelated
databases (`UNIVERSITY`, `NTI`, `Chinook`, …). If the container also published
1433, two listeners would share the port and `localhost:1433` would be
ambiguous - an easy way to run a script against the wrong instance. The
container publishes **1434** instead, so the two are never confused.

The containerised database is a completely separate copy of `MO_ASHRAF`. The
native instance is untouched, and the host-native workflow in `CLAUDE.md`
still works exactly as before.

## Database initialisation

The `db-init` service creates `MO_ASHRAF` and applies, in order:

1. `db/01_Schema.sql` - the SalesBuzz SDK schema (32 tables + `Get_AuditCriteria`)
2. `db/02_Demo_Data.sql` - SUPSEAL Nutrition demo dataset
3. `db/03_Alert_Rules.sql` - alert rule tables + `usp_EvaluateAlertRules`

It runs on **every** `docker compose up`, not just the first - every script is
idempotent. That is deliberate: `02_Demo_Data.sql` anchors its order dates to
`GETDATE()`, so re-running it slides the demo story ("silent 48 days") forward
to stay true relative to today.

Data lives in the `mssql_data` volume and survives `docker compose down`.

```bash
docker compose down -v      # also deletes the volume: next `up` rebuilds the DB from scratch
```

## Connecting to the containerised database

```bash
docker compose exec db /opt/mssql-tools18/bin/sqlcmd \
  -C -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -d MO_ASHRAF -Q "SELECT COUNT(*) FROM HH_Customer"
```

On **Git Bash**, prefix that with `MSYS_NO_PATHCONV=1` - Git Bash otherwise
rewrites `/opt/...` into a Windows path and the exec fails.

## Authentication difference from the host setup

`api/appsettings.json` uses `Trusted_Connection=True` (Windows Authentication),
which does not exist in a Linux container. Compose overrides the connection
string with SQL authentication via the `ConnectionStrings__DefaultConnection`
environment variable. `appsettings.json` is not modified, so running the API
natively on Windows still uses Windows Auth as before.

The `sa` password lives in `.env`. It is a local development credential only -
do not reuse it anywhere real, and do not commit `.env` to a public repo.

## Package resolution inside the containers

The SalesBuzz packages are not on any public registry:

- **npm** - `app/package.json` references `file:../Packages/npm/*.tgz`, so the
  image copies `Packages/npm` to the matching relative location before
  `npm install`.
- **NuGet** - `nuget.config` at the repo root registers `./Packages/nuget` as a
  source using a path relative to itself. Previously this source only existed
  machine-wide in `%APPDATA%\NuGet\NuGet.Config`, which a container cannot see.
  With the repo-local config, `dotnet restore` works in a container, in a fresh
  clone, and on the host - no manual `dotnet nuget add source` step.

## Common tasks

```bash
docker compose logs -f api        # follow API logs
docker compose logs -f app        # follow Angular build output
docker compose restart api        # restart just the API
docker compose up --build         # rebuild after changing package.json / api.csproj
docker compose down               # stop everything, keep the data
```
