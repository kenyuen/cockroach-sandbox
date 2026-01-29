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
