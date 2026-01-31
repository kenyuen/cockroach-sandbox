Liquibase runner

This directory contains a minimal Maven wrapper project and a small script to run Liquibase against
the local CockroachDB playground.

Files
- `pom.xml` - small Maven POM that pins the Liquibase Maven plugin and the PostgreSQL JDBC driver.
- `run-liquibase.sh` - convenience script that invokes the Liquibase Maven plugin (see examples).

Quick examples (run from repository root)

# First bootstrap run (create `app` DB and `demo` user as root)
```bash
./liquibase/run-liquibase.sh update -Dliquibase.url="jdbc:postgresql://localhost:26257/defaultdb?sslmode=disable" -Dliquibase.username=root
```

# Subsequent runs as demo (no password in local setup)
```bash
./liquibase/run-liquibase.sh update -Dliquibase.url="jdbc:postgresql://localhost:26257/defaultdb?sslmode=disable" -Dliquibase.username=demo
```

# Preview SQL without applying changes
```bash
./liquibase/run-liquibase.sh updateSQL -Dliquibase.url="jdbc:postgresql://localhost:26257/defaultdb?sslmode=disable" -Dliquibase.username=demo
```

Security notes
- DO NOT put production credentials in these scripts or the POM. Use -D properties, Maven settings.xml servers entries, or your CI secret store to supply credentials.
- TODO: add secure-mode example that mounts certs and demonstrates secure JDBC connection options.
