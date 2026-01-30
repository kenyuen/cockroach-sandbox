#!/usr/bin/env bash
# GENERATED — review before use
# One-shot init script for CockroachDB cluster. Designed for local dev with --insecure.
# Security: for production switch to certs and remove --insecure. See README.md.

set -euo pipefail

# Allow overriding via environment
INIT_HOST=${INIT_HOST:-cockroach1:26257}
RETRIES=30
SLEEP=2

COCKROACH_BIN=${COCKROACH_BIN:-/cockroach/cockroach}

# Extract host (before colon) to use for node-status checks
INIT_HOST_ONLY=${INIT_HOST%%:*}
INIT_PORT=${INIT_HOST##*:}

echo "Waiting for CockroachDB node at ${INIT_HOST} to accept connections..."
for i in $(seq 1 ${RETRIES}); do
  # First check: TCP port is open (fast). Use bash /dev/tcp so we don't depend on nc being present in the image.
  if bash -c "</dev/tcp/${INIT_HOST_ONLY}/${INIT_PORT}" >/dev/null 2>&1; then
    echo "TCP connection to ${INIT_HOST} accepted. Proceeding..."
    break
  fi

  # Prefer checking node status (works before SQL is enabled in some setups)
  if ${COCKROACH_BIN} node status --insecure --host=${INIT_HOST_ONLY}:${INIT_PORT} >/dev/null 2>&1; then
    echo "CockroachDB node status OK. Proceeding with init..."
    break
  fi

  # Fallback: try a simple SQL query (may fail until init in some modes)
  if ${COCKROACH_BIN} sql --insecure --host=${INIT_HOST} --execute "SELECT 1;" >/dev/null 2>&1; then
    echo "CockroachDB SQL responded. Proceeding with init..."
    break
  fi

  echo "Attempt ${i}/${RETRIES}: not ready yet, sleeping ${SLEEP}s..."
  sleep ${SLEEP}

  if [ ${i} -eq ${RETRIES} ]; then
    echo "Timed out waiting for CockroachDB at ${INIT_HOST}" >&2
    exit 1
  fi
done

# Run init (idempotent) — will fail if cluster already initialized; ignore error safely
set +e
${COCKROACH_BIN} init --insecure --host=${INIT_HOST}
RC=$?
set -e
if [ ${RC} -eq 0 ]; then
  echo "cockroach init succeeded"
else
  echo "cockroach init exit code ${RC} (may already be initialized). Continuing..."
fi

# Example: create a sample database/user for local development. Comment out if not desired.
${COCKROACH_BIN} sql --insecure --host=${INIT_HOST} --execute "CREATE DATABASE IF NOT EXISTS demo;" || true

# Try to create user with a password. In --insecure mode, setting a password is not supported
# so fallback to creating the user without a password when the first attempt fails.
set +e
${COCKROACH_BIN} sql --insecure --host=${INIT_HOST} --execute "CREATE USER IF NOT EXISTS demo WITH PASSWORD 'demo';"
RC=$?
set -e
if [ ${RC} -ne 0 ]; then
  echo "Creating user with password failed (likely insecure mode). Falling back to no-password user."
  ${COCKROACH_BIN} sql --insecure --host=${INIT_HOST} --execute "CREATE USER IF NOT EXISTS demo;" || true
fi

# Grant privileges (may fail in some setups; ignore errors)
${COCKROACH_BIN} sql --insecure --host=${INIT_HOST} --execute "GRANT ALL ON DATABASE demo TO demo;" || true

echo "Init script completed."

# exit successfully so docker-compose doesn't try to restart it
exit 0
