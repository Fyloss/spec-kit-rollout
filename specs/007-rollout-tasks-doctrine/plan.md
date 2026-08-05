# Implementation Plan: Rollout Tasks Doctrine (Pre-Tasks Briefing)

**Branch**: `007-rollout-tasks-doctrine` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-rollout-tasks-doctrine/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/brief-tasks.md` (the content the
`before_tasks` hook injects) with the pre-tasks doctrine from vision.md §4/§5.2:
invoke the shared gate script (Feature 003) in default mode; on no marker,
emit a one-line no-op with no rollout content; on marker present, perform a
second, feature-specific check — inspect `plan.md` for a `## Delivery
Strategy` section (Feature 006) — before generating anything. If that
section is absent, emit a distinct one-line status message reporting the
gap and add zero rollout tasks (never fall back to `spec.md`). If present,
instruct the agent to emit six ordered rollout tasks into `tasks.md`, one
per Delivery Strategy element (create flag, configure environments,
configure targeting, integrate SDK, add telemetry validation, define
rollback conditions), each grounded strictly in the values already written
in that section — repeating the six-task pattern per flag when the section
names more than one. This is the doctrine feature that most directly
enforces Principle III (Strict Content Lineage): `spec.md` is consulted only
through the gate script's marker-presence state, never mined for rollout
task content. Out of scope: provider execution (Feature 10,
`before_implement`), any change to `extension.yml`, the gate scripts, or any
other `brief-*.md` command.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/brief-tasks.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-specify.md`, `brief-clarify.md`, `brief-plan.md`,
`brief-analyze.md`, `brief-checklist.md`, `brief-implement.md`, and
`connect.md`.

**Primary Dependencies**: None. Consumes (but does not modify) the existing
`## Delivery Considerations` / `Candidate flag(s):` marker contract
(`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`,
implemented by `scripts/bash/rollout-gate.sh` /
`scripts/powershell/rollout-gate.ps1`), the marker-writing doctrine in
`commands/brief-specify.md` (Feature 004), the marker-refinement doctrine in
`commands/brief-clarify.md` (Feature 005), and — the direct upstream content
source for this feature — the `## Delivery Strategy` section doctrine in
`commands/brief-plan.md` (Feature 006).

**Storage**: N/A — no data is persisted by this feature itself; the doctrine
it authors instructs the `/speckit.tasks` agent to append six ordered
rollout tasks (per flag) into that feature's own `tasks.md` as a downstream
effect of following the doctrine, not something this feature's deliverable
does directly.

**Testing**: Manual/scripted verification per quickstart.md: walk through
the three user stories (full Delivery Strategy present → six tasks per
flag; no marker → untouched; marker present but no Delivery Strategy →
status message, zero rollout tasks) using the doctrine text as the acting
agent's instructions, and confirm the resulting `tasks.md` content matches
each story's acceptance scenarios, with every rollout task traceable to a
specific Delivery Strategy value rather than spec.md language. Run
`scripts/bash/rollout-gate.sh` against fixture feature directories before
and after to confirm `hasFlags`/`flags` parity, mirroring the verification
pattern from Features 005-006. No automated test framework is introduced
(consistent with 001-006 precedent).

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs Spec Kit's `/speckit.tasks` command; no platform-specific
behavior is introduced.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text injected into agent
context per `/speckit.tasks` invocation; not performance-sensitive.

**Constraints**: MUST invoke the gate script's default mode (spec.md-only
check) rather than analyze mode (FR-001) — this feature only needs
flag/no-flag state, not the multi-file search analyze mode performs. MUST
treat `hasFlags=false` (including the diagnostic exit code) identically:
one-line no-op, no rollout content (FR-002). MUST perform the `## Delivery
Strategy` presence check in `plan.md` as a second, separate step only after
`hasFlags=true` (FR-003) — never skip straight to task generation. MUST NOT
regenerate or fall back to `spec.md`'s requirements text as a rollout-task
content source under any circumstance, including when the Delivery Strategy
section is missing or only partially populated (FR-004, FR-006, FR-007,
FR-009) — this is the strict content-lineage guardrail (constitution
Principle III) unique to this feature among 004-006. MUST order the six
tasks to reflect a logical delivery sequence: flag creation before
environment/targeting configuration; SDK integration before telemetry
validation; rollback conditions defined alongside or after telemetry
validation (FR-008). MUST repeat the six-task pattern once per named flag
when the Delivery Strategy section names more than one, rather than merging
them into one ambiguous task set (FR-010). MUST NOT include any instruction
to invoke a provider MCP tool or execute a live provider action (FR-011;
reserved for Feature 10's `before_implement` briefing). MUST NOT modify
`extension.yml`, the gate scripts, `rollout-config.template.yml`, or any
other `brief-*.md` command (spec.md Assumptions).

**Scale/Scope**: One file rewritten (`commands/brief-tasks.md`, replacing
its placeholder body with the full doctrine), similar order of magnitude to
Features 004-006's single-file rewrites (~100-200 lines). No other files
are touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles. This plan is checked against each:

- **I. Additive-Only Extension**: PASS — this feature only rewrites
  `commands/brief-tasks.md`'s body (a `brief-*` command file already wired to
  the `before_tasks` hook in `extension.yml`), touches no core Spec Kit
  template.
- **II. Self-Gating, Near-Zero Noise**: PASS — FR-001/FR-002 require invoking
  the shared gate script first and emitting a one-line no-op with zero
  rollout content when no marker is found (Story 2), matching the pattern
  established in 003-006.
- **III. Strict Content Lineage**: PASS — this is the feature that most
  directly implements the principle's core rule ("tasks.md's rollout tasks
  are derived from plan.md's Delivery Strategy"). FR-003/FR-004/FR-006/FR-007
  require a second gate (Delivery Strategy presence in `plan.md`) before any
  generation, forbid falling back to `spec.md` content when that section is
  absent (Story 3), and forbid mining `spec.md`'s requirements text for task
  details even when the section is present and only partially populated
  (FR-009, Edge Cases). No marker back-fill occurs in this feature (unlike
  Feature 006's plan-time back-fill), so the v1.1.0 carve-out does not apply
  here and is not needed — this feature has no state-vs-content ambiguity to
  resolve.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — FR-011
  explicitly forbids any provider MCP tool-invocation instruction; task
  content may name the flag/provider values already recorded in the Delivery
  Strategy section (inherited from Feature 006) but does not instruct
  provider execution, which remains scoped to `before_implement`.
- **V. Credential Security Is Non-Negotiable**: PASS — this feature is
  content-authoring only; it introduces no credential handling, tokens, or
  config reads/writes.
- **VI. Guardrailed Provider Execution**: N/A — this principle governs
  `before_implement` provider actions; this feature is scoped to
  `before_tasks` doctrine authoring and performs no provider execution.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/007-rollout-tasks-doctrine/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

No `contracts/` directory is produced by this feature, for the same reason
as Features 004-006: this feature authors prompt content rather than a new
machine-readable interface. It targets two existing contracts —
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the gate
script's stdout shape, and Feature 006's `## Delivery Strategy` section
shape (documented in `specs/006-rollout-plan-doctrine/data-model.md` and
vision.md §9) as the sole upstream content source. data-model.md documents
the rollout-task-set entity this feature adds and links to both.

### Source Code (repository root)

This feature makes a single content change to the existing `rollout`
extension package (repository root, established in 001-extension-skeleton).
No `src/`, `tests/`, or app-style directories are introduced or needed —
there is no code to place in them.

```text
# Single project (Spec Kit extension package layout, extended from 001-006)
commands/
└── brief-tasks.md         # MODIFIED: placeholder body replaced with full pre-tasks doctrine
```

No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`,
`commands/brief-specify.md`, `commands/brief-clarify.md`,
`commands/brief-plan.md`, or any other `commands/brief-*.md` file are made by
this feature (spec.md Assumptions). The `before_tasks` hook wiring in
`extension.yml` already targets `commands/brief-tasks.md`; only that file's
body changes.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-006. This feature adds no new directories or files beyond rewriting the
body of the one command file named in the feature input.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations to justify — this feature introduces no architectural
complexity (a single Markdown content rewrite, no services, no scripts, no
new projects, no non-standard patterns) — this section intentionally has no
entries.
