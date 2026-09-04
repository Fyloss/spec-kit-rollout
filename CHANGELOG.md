# Changelog

All notable changes to the `rollout` extension are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-03

### Added

- Initial extension skeleton: `extension.yml` manifest declaring package
  metadata, lifecycle hooks, and a `rollout-config.yml` config declaration.
- Packaging files: `README.md`, `LICENSE` (MIT), `.extensionignore`.
- Modular, per-provider rollout configuration system:
  `rollout-config.template.yml` holds a `provider` selector plus one
  top-level block per configured provider (e.g. `launchdarkly.project_key`,
  `environments`, `server_type`), layered across extension defaults,
  `rollout-config.yml`, and gitignored `local-config.yml`. The config
  schema never stores an MCP server registration or a credential value.
- Rollout gate mechanism: the shared, greppable `## Delivery Considerations`
  marker convention plus cross-platform gate scripts
  ([scripts/bash/rollout-gate.sh](scripts/bash/rollout-gate.sh),
  [scripts/powershell/rollout-gate.ps1](scripts/powershell/rollout-gate.ps1))
  that every briefing command uses to self-gate on rollout intent.
- Detection doctrine ([commands/brief-specify.md](commands/brief-specify.md)):
  heuristics that flag rollout-candidate features and record intent via the
  Delivery Considerations marker.
- Clarify doctrine ([commands/brief-clarify.md](commands/brief-clarify.md)):
  elicits missing rollout parameters (phases, audience/segments,
  percentages, telemetry gates, rollback conditions) and refines the marker.
- Plan doctrine ([commands/brief-plan.md](commands/brief-plan.md)): writes a
  `## Delivery Strategy` section to `plan.md`, derived from the spec's
  requirements and clarified parameters.
- Tasks doctrine ([commands/brief-tasks.md](commands/brief-tasks.md)): emits
  ordered rollout tasks (flag creation, environment/targeting configuration,
  SDK integration, telemetry validation, rollback conditions) derived from
  the plan's Delivery Strategy.
- Analyze doctrine ([commands/brief-analyze.md](commands/brief-analyze.md)):
  verifies the rollout chain (spec marker ↔ plan strategy ↔ tasks) is
  consistent and reports only genuine gaps, never false orphans.
- Checklist doctrine ([commands/brief-checklist.md](commands/brief-checklist.md)):
  adds rollout-quality checklist items (flag naming, targeting, telemetry
  gates, rollback conditions, phase completeness) for flagged features.
- Implement doctrine ([commands/brief-implement.md](commands/brief-implement.md)):
  discovers the developer's own already-registered provider MCP server,
  introspects it at runtime, and executes rollout tasks through it, with a
  graceful plan-only degradation path when no MCP server is available.
- Config wizard command ([commands/config.md](commands/config.md)): a
  re-runnable, interactive `speckit.rollout.config` setup wizard that
  detects the developer's registered MCP server, determines hosted vs.
  local automatically, and writes the modular provider config block.
  Rollout never writes to or modifies any client's MCP configuration.
- Provider switch command ([commands/provider.md](commands/provider.md)):
  `speckit.rollout.provider <name>` switches the active provider, reusing a
  saved config block or triggering that provider's config wizard preset.
- Optional rollout section template
  ([templates/rollout-section.md](templates/rollout-section.md)) for a
  consistent Delivery Strategy structure in `plan.md`.

### Removed

- The one-time `speckit.rollout.connect` command and the pinned MCP server
  concept (`mcp.command`/`args`/`version`/`repository`/`token_env_var`)
  it registered — superseded by the config wizard's live MCP discovery.

### Changed

- Corrected the initial release version from the previously mislabeled
  `1.0.0` to `0.1.0`, reflecting that this is the project's first release.
