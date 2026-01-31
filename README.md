# cockroach-sandbox
playground with exploring cockroachDB


## Copilot instructions
For repository Copilot guardrails and best practices, see: [.github/copilot-instruction.md](.github/copilot-instructions.md)


## CockroachDB local multi-node playground

This repository now includes a configurable docker-compose setup to run a 3-node CockroachDB cluster locally (for development and experimentation).

Files added (check repo root):
- `docker-compose.yml` — 3-node cluster plus an `init` one-shot service.
- `.env.sample` — copy to `.env` and edit values like image tag and ports.
- `init/init-cockroach.sh` — init script that runs `cockroach init` and creates a sample DB/user.

Developer quickstart (clean start)

Follow these steps to start a fresh local 3-node cluster for development. These commands are for macOS zsh and assume Docker Desktop is installed.

1. Copy `.env.sample` to `.env` and edit if needed (optional). The compose file uses sensible defaults if `.env` is missing.

```zsh
cp .env.sample .env
# Edit .env to adjust ports or image tag if desired
```

2. Start a clean cluster (removes named volumes first to avoid stale state):

```zsh
# Stop and remove any existing stack and its volumes (will delete node data)
docker-compose --env-file .env down -v
# Start the stack in detached mode
docker-compose --env-file .env up -d
```

3. The `init` one-shot service usually runs automatically. To run it manually (idempotent):

```zsh
docker-compose --env-file .env run --rm init
```

4. Verify the cluster has 3 nodes and is healthy:

```zsh
# check service status
docker-compose --env-file .env ps
# tail logs
docker-compose --env-file .env logs -f --tail=200 cockroach1 cockroach2 cockroach3
# check node membership from inside a node
docker-compose --env-file .env exec cockroach1 /cockroach/cockroach node status --insecure --host=localhost:26257
```

Environment variable defaults (used if not supplied in `.env`)

- COCKROACH_IMAGE: cockroachdb/cockroach
- COCKROACH_TAG: v25.4.3
- JOIN_HOSTS: cockroach1:26257,cockroach2:26257,cockroach3:26257 (default fallback)
- SQL_PORT_1/2/3: host ports for node SQL (examples in `.env.sample`)
- HTTP_PORT_1/2/3: host ports for admin UI
- RESTART_POLICY: default compose restart policy for nodes (local default is `unless-stopped`)

Troubleshooting tips (common issues & quick checks)

- If nodes do not join the cluster:
  - Check container logs for join errors:

```zsh
# show recent logs
docker-compose --env-file .env logs --tail=200 cockroach1 cockroach2 cockroach3
# check the init job logs
docker logs --tail=200 cockroach-init || true
```

  - Confirm the containers can reach each other on the SQL port from inside the network (example from the init container):

```zsh
# run a quick TCP probe from init (if init is running interactively)
docker exec -it cockroach-init bash -c '</dev/tcp/cockroach1/26257' && echo ok || echo fail
```

  - Ensure `--join` points to service names and ports that exist. By default `JOIN_HOSTS` falls back to `cockroach1:26257,cockroach2:26257,cockroach3:26257`.

- If `cockroach init` fails or indicates the cluster is already initialized:
  - You probably have existing node data in the named volumes. To reset and re-initialize, stop the stack and remove volumes:

```zsh
docker-compose --env-file .env down -v
# then start again
docker-compose --env-file .env up -d
```

- Healthchecks and `depends_on` do not guarantee full readiness. The `init` script uses a TCP probe and Cockroach `node status`/SQL probes; if you change these, ensure the probe sequence still allows `cockroach init` to run once a node is listening.

Security notes & TODOs

- This local playground runs the cluster in `--insecure` mode for convenience. Do NOT use `--insecure` in production. TODO: add secure-cert generation steps, example cert mounts, and switch to `--certs-dir` in `docker-compose.yml` and `init/init-cockroach.sh`.
- Do not commit `.env` containing secrets or cert paths.

## Liquibase (apply DB changelogs)

This repo includes Liquibase changelogs under `liquibase/changelog-master.xml`. Below are convenient commands you can copy/paste from the repo root to run Liquibase against the local CockroachDB cluster.

Notes before you run
- Run commands from the repository root so relative paths to `liquibase/` resolve.
- The examples assume a development, `--insecure` Cockroach cluster and the `root` user. Do NOT use `--insecure` in production.
- TODO: if your Cockroach cluster is running in secure mode, mount the certs and update the JDBC URL/SSL params; do not disable SSL.

Recommended — Maven-based Liquibase (run with mvn)

If you prefer to run Liquibase directly with Maven (no Docker image), you can invoke the Liquibase Maven plugin directly from the command line. These examples use a pinned plugin version for reproducibility.

Notes:
- Run from the repository root so the relative path to `liquibase/changelog-master.xml` resolves.
- On macOS, when connecting from a local process to services started by Docker Desktop that bind to localhost, use `host.docker.internal` as the host in the JDBC URL. If you run Maven inside the compose network (for example via an additional service), use the Cockroach service name (for example `cockroach1:26257`).
- These commands assume `sslmode=disable` for the local, insecure playground. For secure mode, supply the appropriate SSL/JDBC options and mount certs; do not disable SSL in production. TODO: add a secure example that mounts certs and demonstrates the secure JDBC URL.

# FIRST RUN (bootstrap): create the `app` database and the `demo` user
# (run as `root` so changelogs that bootstrap DB/users can run)
```zsh
mvn org.liquibase:liquibase-maven-plugin:4.23.1:update \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=root
```

# Subsequent runs (local dev) as `demo` (no password in this local setup)
```zsh
mvn org.liquibase:liquibase-maven-plugin:4.23.1:update \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=demo
```

# Preview SQL without applying changes
```zsh
mvn org.liquibase:liquibase-maven-plugin:4.23.1:updateSQL \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=demo
```

Optional: add the plugin to your `pom.xml` for convenience (repeatable config). Example snippet to add under `<build><plugins>`:

```xml
<!-- Add to pom.xml if you run Liquibase from this project frequently -->
<plugin>
  <groupId>org.liquibase</groupId>
  <artifactId>liquibase-maven-plugin</artifactId>
  <version>4.23.1</version>
  <configuration>
    <changeLogFile>liquibase/changelog-master.xml</changeLogFile>
    <!-- Don't hardcode credentials in pom.xml for repositories; prefer -D properties or Maven settings -->
  </configuration>
</plugin>
```

Verification (confirm changelogs applied)

```zsh
# check DATABASECHANGELOG entries (uses docker-compose service name 'cockroach1')
docker-compose --env-file .env exec cockroach1 /cockroach/cockroach sql --insecure --user=demo --database=app -e \
"SELECT id, author, filename, dateexecuted FROM DATABASECHANGELOG ORDER BY dateexecuted DESC;"

# verify sample data/schema (adjust schema/table name as needed)
docker-compose --env-file .env exec cockroach1 /cockroach/cockroach sql --insecure --user=demo --database=app -e \
"SELECT * FROM customers.customer LIMIT 5;"
```

Common pitfalls & tips
- Host resolution inside Docker: on macOS prefer `host.docker.internal`; if you run Liquibase in the same Docker network use the Cockroach service name.
- Permissions: Liquibase will create `DATABASECHANGELOG` tables in the target DB; ensure the configured user has rights to create schemas/tables.
- Locks: if a prior run was interrupted, check `DATABASECHANGELOGLOCK` before forcing changes.
- CI: pin the Liquibase image version (example above uses `4.23.1`) and run against ephemeral test DBs.

TODOs
- Add instructions for secure mode (mounting certs and secure JDBC URL) and include an example for running Liquibase from inside the compose network with mounted certs.

<!-- ...end of README... -->
