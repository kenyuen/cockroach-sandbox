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

Quick start

1. Copy `.env.sample` to `.env` and edit if needed:

```bash
cp .env.sample .env
# edit .env as desired
```

2. Start the cluster:

```bash
docker-compose --env-file .env up -d
```

3. Run the init job (if it didn't run automatically):

```bash
docker-compose --env-file .env run --rm init
```

4. Check status and logs:

```bash
docker-compose --env-file .env ps
docker-compose --env-file .env logs -f cockroach1
# Admin UI: http://localhost:8080 (or ports from your .env)
```

Upgrade notes

- To change CockroachDB versions, update `COCKROACH_TAG` in `.env`, pull the new image, and perform rolling restarts of nodes one at a time. See `docker-compose --env-file .env pull` and then recreate each node with `docker-compose --env-file .env up -d --no-deps --force-recreate cockroach<N>`.

Security & TODOs

- This local setup runs `--insecure` by default for convenience — do NOT use `--insecure` in production.
- TODO: add TLS/certs generation steps, a `certs/` mount, and change to `--certs-dir` usage.
- Do not commit `.env` with secrets or private certs; use a secret manager in production.

## Liquibase (apply DB changelogs)

This repo includes Liquibase changelogs under `liquibase/changelog-master.xml`. Below are convenient commands you can copy/paste from the repo root to run Liquibase against the local CockroachDB cluster.

Notes before you run
- Run commands from the repository root so relative paths to `liquibase/` resolve.
- The examples assume a development, `--insecure` Cockroach cluster and the `root` user. Do NOT use `--insecure` in production.
- TODO: if your Cockroach cluster is running in secure mode, mount the certs and update the JDBC URL/SSL params; do not disable SSL.

Recommended — Dockerized Liquibase (no local install, macOS)

```zsh
# pinned image for reproducibility; change version as needed
# FIRST RUN (bootstrap): run as privileged user (root) so the changelog can create the `app` database and `demo` user
docker run --rm -v "$(pwd)":/work -w /work liquibase/liquibase:4.23.1 \
  liquibase \
  --changeLogFile=/liquibase/changelog-master.xml \
  --url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  --username=root \
  update
```

After the first (bootstrap) run completes, the `demo` user will be created and schema ownership transferred. For regular local runs you can use the `demo` user (no password in this local setup):

```zsh
# subsequent runs (local dev) as demo (no password)
docker run --rm -v "$(pwd)":/work -w /work liquibase/liquibase:4.23.1 \
  liquibase \
  --changeLogFile=/liquibase/changelog-master.xml \
  --url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  --username=demo \
  update
```

- On macOS use `host.docker.internal` so the Liquibase container can reach services bound to the host's localhost. If you run Liquibase inside the compose network instead, use the Cockroach service name (for example `cockroach1:26257`) and `--network` when running the Docker command.
- To preview SQL without applying changes, replace `update` with `updateSQL`.

Alternative — local Liquibase CLI (if installed locally)

```zsh
# run as demo user (no password) for local dev
docker run --rm -v "$(pwd)":/work -w /work liquibase/liquibase:4.23.1 liquibase --changeLogFile=/work/liquibase/changelog-master.xml --url="jdbc:postgresql://localhost:26257/defaultdb?sslmode=disable" --username=demo update
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
