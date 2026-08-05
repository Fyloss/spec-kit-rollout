# Data Model: Rollout Configuration System

This feature has no runtime database or in-memory domain objects. The
"entities" are the structural elements of the layered configuration itself,
as declared in `rollout-config.template.yml` / `extension.yml` and resolved
at runtime by the installed Spec Kit `ConfigManager`.

## Configuration Template

The version-controlled, shipped file (`rollout-config.template.yml`) at the
repository root — the starting point every adopting project copies to create
its own Project Configuration File.

| Field | Type | Required | Notes |
|---|---|---|---|
| `provider` | string | yes | Default `"launchdarkly"`; pluggable key (FR-002) |
| `launchdarkly.project_key` | string | yes (placeholder) | Empty-string placeholder; non-secret identifier |
| `launchdarkly.environments` | string[] | yes (placeholder) | Empty-list placeholder; non-secret identifiers |
| `mcp.command` | string | yes | Pinned launcher command for the official LaunchDarkly MCP server |
| `mcp.args` | string[] | yes | Pinned launcher arguments |
| `mcp.version` | string | yes | Version constraint for the pinned server |
| `mcp.repository` | string (URL) | yes | Source repository URL for the pinned server (FR-003) |
| `mcp.token_env_var` | string | yes | Name only (e.g. `LAUNCHDARKLY_API_TOKEN`) — never a token value (FR-004) |
| `hooks.enabled` | boolean | yes | Default `true`; team-level kill switch (FR-005) |

**Invariant**: no field in this file may ever hold a real credential/token
value (FR-001, FR-013) — enforced only by inline comments and human review
(FR-006), not automated secret-scanning (Out of Scope).

## Resolved Configuration

The single, in-memory view produced by `ConfigManager.get_config()` after
merging all four layers in precedence order. Not a file — this is what gate
scripts and briefing commands (future features) actually consult.

| Property | Notes |
|---|---|
| Merge order (low → high precedence) | (1) `extension.yml` `config.defaults`, (2) Project Configuration File, (3) Local Override File, (4) `SPECKIT_ROLLOUT_*` env vars |
| Merge strategy | Recursive dict merge (`_merge_configs`); a higher layer's dict value merges key-by-key into a lower layer's dict value at the same path; any non-dict value fully overrides |
| Missing layer behavior | A missing file (project or local config) contributes an empty dict — never an error (FR-012) |
| Env-var value typing | Always a raw string, regardless of the target field's YAML type (see research.md) — the `hooks.enabled` toggle's consumer must explicitly parse/validate this, not assume a Python bool |

## Project Configuration File

The committed, per-project configuration derived from the template, resolved
at the fixed path `.specify/extensions/rollout/rollout-config.yml` (FR-008).
Same field shape as the Configuration Template, but with real (still
non-secret) values filled in.

| Property | Notes |
|---|---|
| Resolved path | `.specify/extensions/rollout/rollout-config.yml` |
| Version control | Committed by the team (not gitignored) |
| Produced by | Copying `rollout-config.template.yml` and editing values (User Story 1) |

## Local Override File

An optional, gitignored, per-developer file overriding individual fields of
the Project Configuration File without changing what the team shares (User
Story 3).

| Property | Notes |
|---|---|
| Resolved path | `.specify/extensions/rollout/local-config.yml` (literal filename — **not** parameterized by extension id) |
| Version control | MUST be excluded (FR-009); Spec Kit does not auto-manage this — the adopting project's own `.gitignore` must exclude it (documented, not enforced by code; see research.md) |
| Shape | Any subset of the full schema; only fields present override the corresponding Project Configuration File fields |

## Provider Descriptor

The pluggable identification of which delivery provider the configuration
targets (LaunchDarkly in V1), plus that provider's own pointer fields.

| Field | Type | Notes |
|---|---|---|
| `provider` | string | Recognized value in V1: `"launchdarkly"`; any other string is a recognized-but-unimplemented value, not a parse error (per spec.md edge case) |
| `launchdarkly.project_key` | string | Non-secret identifier |
| `launchdarkly.environments` | string[] | Non-secret identifiers |

**Extension point**: a future provider adds a sibling block (e.g.
`unleash: {...}`) alongside `launchdarkly:`, without touching `provider`'s
type, `mcp:`, or `hooks:` (FR-002).

## MCP Server Reference

The canonical, pinned description of how to launch the official provider MCP
server, and which environment variable it reads for its token.

| Field | Type | Notes |
|---|---|---|
| `mcp.command` | string | Launcher command |
| `mcp.args` | string[] | Launcher arguments |
| `mcp.version` | string | Version constraint |
| `mcp.repository` | string (URL) | Source repository, for supply-chain verification (vision.md 6.2) |
| `mcp.token_env_var` | string | Env-var **name** only; the doctrine that reads this (future feature) must never read or echo the named variable's value |

## Hooks Toggle

The single boolean setting controlling whether any rollout hook produces
doctrine output for a given team/project (FR-005, FR-011).

| Property | Notes |
|---|---|
| Path | `hooks.enabled` |
| Type | boolean, default `true` |
| Resolved via env var | `SPECKIT_ROLLOUT_HOOKS_ENABLED` — cleanly maps to `hooks.enabled` because both segments are single words (see research.md's env-var splitting decision) |
| Invalid-value behavior | Non-boolean resolved values (including any string other than a clean `true`/`false` distinguishable by the consumer) MUST fall back to the safe default (`true`/enabled) — the responsibility of the future gate-script consumer, not `ConfigManager` |
| Independence | Resolved value MUST be unambiguous and independent of any other field (FR-011) — no other field's value affects the toggle's resolution |
