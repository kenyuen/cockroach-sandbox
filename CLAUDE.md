# CLAUDE.md

This file provides guidance for Claude Code working in this repository.

## Project Overview

A local development sandbox for exploring and testing [CockroachDB](https://www.cockroachlabs.com/) — a distributed SQL database. The repo provides Docker Compose configurations for single-node, multi-node, and multi-region cluster topologies, along with Kubernetes manifests and a Liquibase schema migration workflow.

**Not for production use** — clusters run in `--insecure` mode (no TLS).

---

## Environment Setup

Copy the environment template before running anything:

```bash
cp .env.sample .env
# Optionally edit .env to change ports, image tag, etc.
```

For Liquibase:
```bash
cp liquibase/.env.sample liquibase/.env
# Edit liquibase/.env with JDBC credentials if needed
```

---

## Common Commands

### Start / Stop Cluster

```bash
# 3-node cluster (default)
docker-compose --env-file .env up -d
docker-compose --env-file .env down

# Clean restart (removes volumes / all data)
docker-compose --env-file .env down -v
docker-compose --env-file .env up -d

# Single-node
docker-compose -f docker-compose.single-node.yml --env-file .env up -d

# Scaled cluster with HAProxy
docker-compose -f docker-compose.scale.yml --env-file .env up -d --scale cockroach=3
```

### Initialize Cluster

After starting the nodes, run the one-shot init job:

```bash
docker-compose --env-file .env run --rm init
```

This runs `init/init-cockroach.sh`, which:
- Waits for nodes to be ready
- Runs `cockroach init`
- Creates databases (`movr`, `app`) and user `demo`

### Check Cluster Health

```bash
docker-compose --env-file .env ps
docker-compose --env-file .env logs -f --tail=200 cockroach1 cockroach2 cockroach3
docker-compose --env-file .env exec cockroach1 \
  /cockroach/cockroach node status --insecure --host=localhost:26257
```

### Connect via SQL Shell

```bash
docker-compose --env-file .env exec cockroach1 \
  /cockroach/cockroach sql --insecure --database=defaultdb
```

### Seed Sample Data

```bash
# Generate and apply 50 customer rows
python3 seed/seed_customers.py -n 50 | \
  docker-compose --env-file .env exec -T cockroach1 \
    /cockroach/cockroach sql --insecure --database=app

# Generate SQL to a file instead
python3 seed/seed_customers.py -n 100 --region us-east > seed.sql
```

### Apply Liquibase Schema Migrations

First run (as `root`):
```bash
mvn org.liquibase:liquibase-maven-plugin:4.23.1:update \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=root
```

Subsequent runs (as `demo`):
```bash
mvn org.liquibase:liquibase-maven-plugin:4.23.1:update \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=demo
```

Preview pending SQL without applying:
```bash
mvn org.liquibase:liquibase-maven-plugin:4.23.1:updateSQL \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=root
```

Release a stuck Liquibase lock:
```bash
mvn -Prelease-lock -DforceReleaseLock=true validate \
  -Dliquibase.changeLogFile=liquibase/changelog-master.xml \
  -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" \
  -Dliquibase.username=root
```

---

## Service Endpoints

| Service         | URL / Address                        |
|-----------------|--------------------------------------|
| Admin UI node 1 | http://localhost:8080                |
| Admin UI node 2 | http://localhost:8081                |
| Admin UI node 3 | http://localhost:8082                |
| SQL node 1      | localhost:26257                      |
| SQL node 2      | localhost:26258                      |
| SQL node 3      | localhost:26259                      |
| HAProxy SQL     | localhost:26257 (scaled/6-node only) |
| HAProxy UI      | http://localhost:8080 (scaled only)  |

---

## Directory Structure

```
.
├── .env.sample                  # Environment variable defaults
├── docker-compose.yml           # 6-node east/west multi-region cluster
├── docker-compose.single-node.yml
├── docker-compose.scale.yml     # Dynamically scalable cluster + HAProxy
│
├── init/
│   └── init-cockroach.sh        # Cluster bootstrap (idempotent)
│
├── seed/
│   ├── seed_customers.py        # Generates random customer SQL INSERTs
│   └── README.md
│
├── proxy/
│   ├── haproxy.cfg              # HAProxy config for 6-node cluster
│   └── haproxy.scale.cfg        # HAProxy config for scaled cluster
│
├── liquibase/
│   ├── changelog-master.xml     # Master Liquibase changelog
│   ├── changelogs/              # Per-feature changelogs
│   ├── sql/                     # Raw SQL migration files (001–005)
│   ├── pom.xml                  # Maven config (Liquibase v4.23.1)
│   └── .env.sample              # JDBC connection template
│
└── k8s/
    ├── cockroach-statefulsets.yaml
    ├── cockroach-services.yaml
    ├── cockroach-init-job.yaml
    └── cockroach-scripts-configmap.yaml
```

---

## Key Configuration Variables (`.env`)

| Variable          | Default                                          | Description                     |
|-------------------|--------------------------------------------------|---------------------------------|
| `COCKROACH_IMAGE` | `cockroachdb/cockroach`                          | Docker image name               |
| `COCKROACH_TAG`   | `v25.4.3`                                        | CockroachDB version             |
| `CLUSTER_NAME`    | `local-cockroach`                                | Logical cluster name            |
| `JOIN_HOSTS`      | `cockroach1:26257,cockroach2:26257,...`           | Bootstrap join addresses        |
| `SQL_PORT_1/2/3`  | `26257 / 26258 / 26259`                          | Host-mapped SQL ports           |
| `HTTP_PORT_1/2/3` | `8080 / 8081 / 8082`                             | Host-mapped Admin UI ports      |
| `PERSIST_DATA`    | `true`                                           | Keep volumes across restarts    |
| `RESTART_POLICY`  | `unless-stopped`                                 | Container restart policy        |

---

## Troubleshooting

**Nodes won't join cluster:**
- Check `JOIN_HOSTS` in `.env` matches the actual service names.
- Run `docker-compose logs cockroach1` to see startup errors.
- Ensure the init job ran after all nodes were healthy.

**Init job fails:**
- The job retries up to 30 times with 2s sleep — wait for all nodes.
- If "already initialized" appears, that's safe to ignore (idempotent).

**Port conflicts:**
- Change `SQL_PORT_*` and `HTTP_PORT_*` in `.env`.

**Liquibase lock stuck:**
- Use the `release-lock` Maven profile (see commands above).

**Data persistence:**
- Set `PERSIST_DATA=false` in `.env` or run `docker-compose down -v` to wipe volumes.

---

## Security Notes

- All clusters run with `--insecure` (no TLS, no authentication).
- Never commit `.env` files — they are in `.gitignore`.
- For TLS-secured clusters, replace `--insecure` with `--certs-dir` and mount certificates.
