# Cockroach locally with MAC install
This README provides instructions for setting up a local Docker using brew

# install on macOS.
```on macOS.
brew install cockroachdb/tap/cockroach
```

## Start a local single node CockroachDB cluster
To start a single-node CockroachDB cluster locally, run:
```bash
cockroach start-single-node --insecure --listen-addr=localhost:26257 --http-addr=localhost:8080 --store=./cockroach-data
```
Access the Admin UI at: http://localhost:8080

Stop the node and cleanup data directory when done, note this is destructive:
```bash
rm -rf cockroach-data*    
```
## Start a multi-node CockroachDB cluster
To run multiple nodes locally without Docker, you can start additional nodes on different ports and join them together. For example:
```bash
cockroach start --insecure --listen-addr=localhost:26257 \
  --join=localhost:26257,localhost:26258,localhost:26259 \
  --http-addr=localhost:8080 --store=cockroach-data-1 --background
cockroach start --insecure --listen-addr=localhost:26258 \
  --join=localhost:26257,localhost:26258,localhost:26259 \
  --http-addr=localhost:8081 --store=cockroach-data-2 --background
cockroach start --insecure --listen-addr=localhost:26259 \
  --join=localhost:26257,localhost:26258,localhost:26259 \
  --http-addr=localhost:8082 --store=cockroach-data-3 --background
cockroach start --insecure --listen-addr=localhost:26260 \
  --join=localhost:26257,localhost:26258,localhost:26259,localhost:26260,localhost:26261 \
  --http-addr=localhost:8083 --store=cockroach-data-4 --background
cockroach start --insecure --listen-addr=localhost:26261 \
  --join=localhost:26257,localhost:26258,localhost:26259,localhost:26260,localhost:26261 \
  --http-addr=localhost:8084 --store=cockroach-data-5 --background
```

Then to initialize the cluster, run:
```bash
cockroach init --insecure --host=localhost:26257
```
Access the Admin UIs at:
- Node 1: http://localhost:8080

Then to stop all nodes, use:
```bash
# Drain the nodes first
cockroach node drain --host=localhost:26257 --insecure
cockroach node drain --host=localhost:26258 --insecure
cockroach node drain --host=localhost:26259 --insecure
cockroach node drain --host=localhost:26260 --insecure  
cockroach node drain --host=localhost:26261 --insecure

# Find the process
ps aux | grep cockroach

# Stop it gracefully
kill <PID>

# confirm shutdown
cockroach node status --insecure --host=localhost:26257
```

Then cleanup data directories if needed:
```bash
rm -rf cockroach-data*
```