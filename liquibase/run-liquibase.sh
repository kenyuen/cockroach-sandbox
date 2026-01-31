#!/usr/bin/env bash
# GENERATED — review before use
# Small convenience wrapper to run Liquibase via the liquibase Maven plugin from the repo root.
# Usage examples (from repo root):
#   ./liquibase/run-liquibase.sh update -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" -Dliquibase.username=root
#   ./liquibase/run-liquibase.sh update -Dliquibase.url="jdbc:postgresql://host.docker.internal:26257/defaultdb?sslmode=disable" -Dliquibase.username=demo
#   ./liquibase/run-liquibase.sh updateSQL -Dliquibase.url=... -Dliquibase.username=demo

set -euo pipefail

# Ensure we're executed from the repository root (so paths like liquibase/changelog-master.xml resolve)
REPO_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT_DIR"

GOAL="${1:-update}"
shift || true

# Build the full mvn command. Users should pass -Dliquibase.url, -Dliquibase.username and optionally -Dliquibase.password
# Use the plugin prefix (liquibase:goal) which will pick up the plugin declared in liquibase/pom.xml
MAVEN_CMD=(mvn -f "$REPO_ROOT_DIR/liquibase/pom.xml" "liquibase:$GOAL")

# Append any extra args provided by the caller
for a in "$@"; do
  MAVEN_CMD+=("$a")
done

# Echo and run the command
echo "Running: ${MAVEN_CMD[*]}"
"${MAVEN_CMD[@]}"
