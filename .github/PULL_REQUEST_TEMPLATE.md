<!-- Provide a short description of the change in this PR. -->

## PR Summary


## Checklist
- [ ] Service has README and purpose statement (if adding a new service).
- [ ] Required config properties are documented and validated.
- [ ] No secrets are committed.
- [ ] Container runs as non-root; HEALTHCHECK present (if adding a container image).
- [ ] Metrics and health endpoints enabled.
- [ ] Unit and integration tests included and passing.
- [ ] Dependency scan shows no critical CVEs.
- [ ] Image tagged with semantic version + git SHA (if publishing image).

## Security & Configuration
- Describe where secrets/config are stored and how they're validated.

## Testing
- How was this change tested? Include instructions to reproduce locally.

## Rollout/rollback plan
- Steps to roll out this change and how to rollback if issues occur.

---

For Copilot guardrails and best practices, see: `.github/copilot-instruction.md`
