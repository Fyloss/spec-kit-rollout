# Data Model: Rollout Gate Mechanism

This feature has no runtime database or persisted domain objects. The
"entities" are the structural elements the gate scripts read (the marker,
the config layers) and produce (the gate result).

## Delivery Considerations Marker

The state signal written into a feature's `spec.md` by (a future feature's)
`before_specify` doctrine, and read by every gate invocation for that
feature.

| Field | Type | Required | Notes |
|---|---|---|---|
| Heading token | literal string | yes | Exactly `## Delivery Considerations`, matched at the start of a line; this is the sole detection signal (FR-001, FR-002) |
| Body prose | free text | yes | Human-readable rollout intent; not parsed by the gate beyond the optional candidate-flags line below |
| Candidate flags line | string | no | A line matching `Candidate flag(s): <name>[, <name>...]` (case-insensitive label); optional — its absence does not affect `hasFlags` (see Gate Result below) |

**Location**: `specs/<feature>/spec.md` by default; also considered in
`plan.md` and/or `tasks.md` when the gate is invoked with `--mode analyze`.

**Invariant**: Detection depends only on the literal heading line — never on
interpreting surrounding prose, punctuation, or which candidate flag names
(if any) are present (FR-002).

## Gate Result

The machine-readable output of one gate script invocation, scoped to exactly
one resolved feature directory and one invocation mode (default vs. analyze).

| Field | Type | Notes |
|---|---|---|
| `hasFlags` | `true`/`false` | `true` when the marker heading is found in an in-scope file AND `hooks.enabled` resolves to enabled; `false` otherwise (FR-009) |
| `flags` | comma-separated string (may be empty) | Candidate flag names parsed from the marker's optional `Candidate flag(s):` line; empty when absent or when `hasFlags=false` |
| `source` | one of `spec.md`, `plan.md`, `tasks.md`, `` (empty) | Which file the marker was found in; empty when `hasFlags=false` |
| `hooksEnabled` | `true`/`false` | The resolved `hooks.enabled` value, independent of marker presence — lets a caller distinguish "no marker" from "hooks disabled" even though both yield `hasFlags=false` |
| exit code | integer | The primary branch signal for calling commands (see contracts/rollout-gate-cli.md); distinct codes for rollout / no-rollout / unresolved-feature-directory |

**Per-feature scoping invariant**: A Gate Result for feature A is computed
only from feature A's own resolved directory; it MUST NOT be affected by any
other feature's `spec.md`/`plan.md`/`tasks.md` content (spec.md SC-006).

## Hooks-Enabled Toggle (consumed, not owned by this feature)

The single boolean setting from 002-config-system's schema that this feature
reads and folds into every Gate Result as an override.

| Property | Notes |
|---|---|
| Path | `hooks.enabled`, nested under a top-level `hooks:` key, per `../002-config-system/contracts/rollout-config-schema.md` |
| Resolution precedence (low → high) | extension defaults (`.specify/extensions/rollout/extension.yml`) → project config (`.specify/extensions/rollout/rollout-config.yml`) → local override (`.specify/extensions/rollout/local-config.yml`) → `SPECKIT_ROLLOUT_HOOKS_ENABLED` env var |
| Missing layer behavior | Contributes nothing; resolution falls through to the next lower-precedence layer, ending at the default `true` if no layer sets it |
| Invalid value behavior | An env var value other than a recognized true/false spelling falls through as if unset (research.md); this feature owns that fallback rule per 002-config-system's contract, which explicitly delegates it here |
| Effect on Gate Result | `hooks.enabled=false` forces `hasFlags=false` for every feature, regardless of marker content (FR-007, spec.md SC-003) |

## Feature Directory Resolution (consumed, not owned by this feature)

The mechanism the gate scripts use to find "the current feature," reusing
Spec Kit's own convention rather than defining a new one.

| Step | Precedence | Source |
|---|---|---|
| 1 | highest | `SPECIFY_FEATURE_DIRECTORY` environment variable |
| 2 | fallback | `.specify/feature.json`'s `feature_directory` key, found by walking upward from the working directory for a `.specify/` directory |
| 3 | failure | Neither resolves → Gate Result is fail-safe `hasFlags=false` with the diagnostic exit code (FR-004, FR-010, spec.md edge case) |
