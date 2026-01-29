# Copilot Instruction — Spring Boot & Docker Core Principles

Purpose
- Provide concise guardrails and disciplined best practices for generating Spring Boot projects and Docker containers via Copilot or other code generation aids.
- Prioritize security, reproducibility, observability, testability, and minimal runtime surface.

Scope
- Focused on new microservices and small-to-medium Spring Boot projects and their container images.
- Covers project layout, dependency management, configuration, Docker image creation, runtime JVM tuning, observability, testing, CI, and code-generation guardrails.

Core Principles
- Least privilege: default to minimal permissions and non-root runtime users.
- Fail-fast & explicit: validate configuration at startup and fail with clear errors on missing required values.
- Small attack surface: limit dependencies, restrict reflection/dynamic code, and avoid embedding secrets.
- Reproducible artifacts: pin versions and use lockfiles; prefer build caches and layered artifacts for incremental build speed.
- Observable by design: structured logs, metrics, and health endpoints are required.
- Test-first: unit + integration (real infra via Testcontainers) + contract tests for public APIs.

Tiny contract (for generated services)
- Inputs: environment variables, config files (application-*.yml), and inbound requests (JSON/HTTP).
- Outputs: structured logs, HTTP responses, Prometheus metrics, health endpoints, and database migrations executed via Flyway/Liquibase.
- Error modes: fail-fast on missing secrets; graceful degrade for dependent services with timeouts/retries and circuit breakers.
- Success criteria: passes CI tests, registered metrics, health=UP on startup, and image scanned with no critical CVEs.

Project structure (recommended)
- src/main/java
- src/main/resources
- src/test/java
- build files: pom.xml or build.gradle(.kts)
- docs: README.md, CHANGELOG.md, copilot-instruction.md
- infra: Dockerfile, docker-compose.yml (dev only), k8s manifests (if applicable)

Dependencies & build
- Use the Spring Boot starter BOM or platform to manage versions.
- Keep third-party libraries minimal and justified; prefer well-maintained projects.
- Lock dependency versions (gradle.lockfile or Maven dependencyManagement) and enable reproducible builds where possible.

Configuration & secrets
- Externalize all environment-specific configuration.
- Never hardcode secrets. Reference a secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager) or use encrypted values in CI.
- Validate required config properties at startup and log missing/invalid values clearly.

Security
- Run containers as a non-root user and set appropriate file permissions.
- Scan dependencies in CI and block merges on critical findings.
- Prefer TLS (HTTPS) for external endpoints and mTLS for internal service-to-service communication where possible.
- Sanitize inputs and validate DTOs; avoid dangerous deserialization patterns.

Docker best practices
- Use multi-stage builds: build with a full JDK image, produce a slim runtime image (JRE/distroless/alpine variants where appropriate).
- Create small, immutable images. Prefer Spring Boot layered jars or exploded jars for faster deploys.
- Set explicit USER and WORKDIR; configure HEALTHCHECK and ENTRYPOINT for graceful shutdown.
- Do not bake secrets into images. Pass secrets at runtime via environment, volume-mounted files, or secret stores.
- Tag images with semantic version + git SHA (e.g., v1.2.3+githash).

Runtime and JVM
- Tune heap relative to container limits. Use container-aware JVM flags for the JVM version in use.
- Expose and document recommended JAVA_OPTS. Prefer conservative defaults and make them overrideable by env vars.
- Consider native images or jlink only after profiling demonstrates need.

Observability & reliability
- Export metrics with Micrometer (Prometheus format) and enable /actuator/metrics, /actuator/health, and /actuator/prometheus when applicable.
- Use structured JSON logs and include correlation/request IDs in every log line.
- Implement timeouts, retries with backoff, and circuit breakers for remote calls.

Testing & quality
- Unit tests for business logic; integration tests with Testcontainers for DB and external dependencies.
- Enforce tests in CI and gate merges on failing tests.
- Add static analysis (SpotBugs, Checkstyle/Pmd, Sonar) in CI.

CI/CD
- Automate: build, test, static analysis, dependency scan, image build, and image signing.
- Use immutable image tags (sha) and promote images across environments with gates and approvals.
- Rebuild images on base-image security updates.

Local dev
- Provide a `docker-compose.yml` for local development with optional seeded data. Keep production and local compose files separate.
- For any 'docker-compose.yml' do not include version attribute as it is deprecated.
- Include a developer guide in README for local run and debug instructions.

Image governance
- Periodically scan base images and dependencies. Rebuild on critical CVE patches.
- Enforce image retention and immutability policies in the registry.

Operational guidelines
- Provide runbooks for start/stop/rollback, troubleshooting, and expected resource profiles.
- Document healthchecks, metrics to monitor, and alert thresholds.

Code generation guardrails for Copilot
- Suggest minimal, idiomatic code. Prefer explicit types and validated configuration classes.
- Always add TODOs where human review is required (security choices, secrets, scaling decisions).
- Avoid creating production credentials, privileged accounts, or uploading secrets in examples.
- When generating Dockerfiles or manifests, include a comment explaining the security rationale for each directive.
- Mark generated code clearly (e.g., `// GENERATED — review before use`).

Reviewer checklist (PRs that add services or containers)
- [ ] Service has README and purpose statement.
- [ ] Required config properties are documented and validated.
- [ ] No secrets are committed.
- [ ] Container runs as non-root; HEALTHCHECK present.
- [ ] Metrics and health endpoints enabled.
- [ ] Unit and integration tests included and passing.
- [ ] Dependency scan shows no critical CVEs.
- [ ] Image tagged with semantic version + git SHA.

Enforcement suggestions (CI rules)
- Fail PRs on: failing tests, critical CVEs, images built as root, missing healthcheck, or missing health/metrics endpoints.

When to deviate
- Document the reason and obtain explicit approval for architectural deviations (e.g., native image, custom JVM flags, or non-standard base images).

Quick start (what Copilot should generate by default)
- Minimal Spring Boot app with typed `@ConfigurationProperties`, actuator enabled, Micrometer + Prometheus exposition, basic health endpoint, Dockerfile using multi-stage build, and a developer `docker-compose.yml`.

Next steps for repo owners
- Place `copilot-instruction.md` at the repo root (done).
- Wire dependency and CVE scanning into CI and add PR templates that include the reviewer checklist.

Acknowledgements
- These are guardrails, not absolute rules. Apply judgement and document exceptions.


Last updated: 2026-01-28
