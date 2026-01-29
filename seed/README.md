# Customer seeder (Python-based)

Seed scripts for local CockroachDB cluster

Usage (generate SQL to stdout):

```bash
python3 seed/seed_customers.py -n 50 > seed.sql
```

Apply to local cluster (requires docker-compose cluster running):

```bash
# generate and pipe directly into cockroach sql
python3 seed/seed_customers.py -n 50 | docker-compose --env-file .env exec -T cockroach1 /cockroach/cockroach sql --insecure --database=app
```

Notes:
- The seed script emits simple INSERT statements for the `customers.customer` table.
- In secure mode (with certs) you'd need to modify the invocation to use --certs-dir and the appropriate host flag.
- This seed is intentionally simple and deterministic-ish; adapt as needed for more realistic data.
