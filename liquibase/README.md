# Liquibase runner

This directory contains a minimal Maven wrapper project that runs Liquibase against the CockroachDB playground. It pins the Liquibase plugin and PostgreSQL JDBC driver in `pom.xml` so everyone executes the same versions.

## Quick start (from repo root)
1. Copy the sample env file (first run only):
```bash
cp liquibase/.env.sample liquibase/.env
```
2. Source the env so Maven sees the JDBC settings:
```bash
set -a && source liquibase/.env && set +a
```
- Set a per-developer `MOVR_USER_PASSWORD` value in `liquibase/.env` before running so the movr role is created with a secret that never lands in git.
3. Apply migrations against `movr`:
```bash
mvn -f liquibase/pom.xml liquibase:update
```

> The first changeSet halts if `current_database()` is not `movr`, so keep `LIQUIBASE_URL` pointed at `jdbc:postgresql://…/movr` for every run and create the database manually (via `cockroach sql`) before running Liquibase the first time.

## Files
- `pom.xml` — Maven wrapper that exposes Liquibase goals (update, updateSQL, etc.).
- `changelog-master.xml` and `changelogs/` — schema changes applied to the target database.

## Running migrations
If you prefer not to source `liquibase/.env`, pass properties inline:

```bash
mvn -f liquibase/pom.xml liquibase:update \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/movr?sslmode=disable" \
  -Dliquibase.username=root \
  -Dliquibase.password=changeme \
  -Dliquibase.parameters.movrUserPassword="$MOVR_USER_PASSWORD"
```

### Preview SQL without applying it
```bash
set -a && source liquibase/.env && set +a
mvn -f liquibase/pom.xml liquibase:updateSQL
```

## Release a stuck changelog lock
Before clearing the lock, confirm no other Liquibase process is actively applying migrations. Inspect `databasechangeloglock` via your SQL client (psql, `cockroach sql`, DBeaver, etc.) and only proceed if `locked=true` with a stale timestamp. Pass `-DforceReleaseLock=true` to acknowledge you are intentionally releasing the lock.

```bash
set -a && source liquibase/.env && set +a
mvn -f liquibase/pom.xml -Prelease-lock -DforceReleaseLock=true validate
```

The `release-lock` profile binds Liquibase's `releaseLocks` goal to the `validate` phase so the command above simply clears the lock state using the same env-driven JDBC settings. TODO: add a reminder for shared clusters to require an approval flag before running this profile in CI.

## Security notes
- **Never** commit passwords or production JDBC URLs. Supply `-Dliquibase.password=...` or configure Maven `settings.xml` with a server entry fed by your secret manager.
- The movr application role password is injected at runtime via `MOVR_USER_PASSWORD` (or `-Dliquibase.parameters.movrUserPassword=...`). Rotate it per environment and store real values in your secrets manager.
- Local runs default to `sslmode=disable`. TODO: document secure-mode instructions (cert mounts, `--certs-dir`, and TLS JDBC parameters) for shared or production-like clusters.

## Authoring schema changes with SQL
All DDL now lives in formatted `.sql` files under `liquibase/sql/` and each file is executed from an XML wrapper via `<sqlFile>`. To add a change:
- Create `sql/00x-some-change.sql` with the exact SQL you want applied (end statements with `;`).
- Reference it from a new changeSet XML file under `changelogs/` using the existing pattern so Liquibase tracks history and rollbacks consistently.
- Keep statements idempotent (use `IF NOT EXISTS` / `IF EXISTS`) because Cockroach migrations often run repeatedly in dev environments.

After editing SQL, rerun `mvn -f liquibase/pom.xml liquibase:updateSQL` to preview output before applying it.
