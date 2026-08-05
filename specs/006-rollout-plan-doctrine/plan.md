# Implementation Plan: Rollout Plan Doctrine (Pre-Plan Briefing)

**Branch**: `006-rollout-plan-doctrine` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-rollout-plan-doctrine/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/brief-plan.md` (the content the
`before_plan` hook injects) with the pre-plan doctrine from vision.md §4/§5.1/
§5.2/§9: invoke the shared gate script to detect the `## Delivery
Considerations` marker; on no marker, perform a minimal cheap sniff of the
current `/plan` invocation's own arguments for the same category of rollout
signals used at specify time, back-filling the marker into `spec.md` if found
and otherwise emitting a one-line no-op with no rollout content; on marker
present (pre-existing or just back-filled), instruct the agent to add a `##
Delivery Strategy` section to `plan.md` — feature flag name, `Provider:
LaunchDarkly`, phased rollout, targeting rules, telemetry gates, rollback
conditions — grounded in the spec's requirements and any rollout parameters
already clarified in the marker (Feature 005), proposing reasonable draft
values for any still-missing element rather than omitting it. Unlike
Features 004-005, this doctrine explicitly names the provider. It may
reference an optional `templates/rollout-section.md` (Feature 12) without
requiring it. This is a content-authoring feature only — no scripts, schema,
or other `brief-*.md` command changes; task breakdown (Feature 7) and
provider/MCP execution (`before_implement`) are explicitly out of scope.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/brief-plan.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-analyze.md`, `brief-checklist.md`, `brief-implement.md`,
`brief-clarify.md`, `brief-specify.md`, `brief-tasks.md`, and `connect.md`.

**Primary Dependencies**: None. Consumes (but does not modify) the existing
`## Delivery Considerations` / `Candidate flag(s):` marker convention defined
by `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` and
implemented by `scripts/bash/rollout-gate.sh` / `scripts/powershell/rollout-gate.ps1`,
the marker-writing doctrine delivered in `commands/brief-specify.md` by
Feature 004, and the marker-refinement doctrine delivered in
`commands/brief-clarify.md` by Feature 005. May reference (but does not
require) an optional `templates/rollout-section.md` file (Feature 12, not yet
built).

**Storage**: N/A — no data is persisted by this feature itself; the doctrine
it authors instructs the `/speckit.plan` agent to (a) back-fill the marker
already present in that feature's own `spec.md` when late rollout intent is
sniffed, and (b) add a `## Delivery Strategy` section to that feature's own
`plan.md` — both downstream effects of following the doctrine, not something
this feature's deliverable does directly.

**Testing**: Manual/scripted verification per quickstart.md: walk through the
three user stories (Delivery Strategy for an already-flagged feature,
non-rollout feature left untouched, late-introduced intent back-filling the
marker at plan time) using the doctrine text as the acting agent's
instructions, and confirm the resulting `plan.md` (and, for Story 3,
`spec.md`) content matches each story's acceptance scenarios. Where a marker
is expected (pre-existing or back-filled), run `scripts/bash/rollout-gate.sh`
against the fixture feature directory before and after the plan pass and
confirm `hasFlags=true` with the expected candidate flag name(s), mirroring
the SC-003 verification pattern from Feature 005. No automated test
framework is introduced (consistent with 001-005 precedent — this repository
has no code to unit-test for this feature).

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs Spec Kit's `/speckit.plan` command; no platform-specific behavior
is introduced.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text injected into agent
context per `/speckit.plan` invocation; not performance-sensitive.

**Constraints**: MUST reproduce the `## Delivery Considerations` heading and
`Candidate flag(s):` label exactly as consumed by
`scripts/bash/rollout-gate.sh`'s `extract_flags_line` matching (verified in
repo memory: case-insensitive match on the literal substring
`candidate flag(s):`, heading must be `^## Delivery Considerations` with no
trailing text) whenever the doctrine back-fills a marker, so the gate script
recognizes it on subsequent runs (SC-003). MUST NOT include task-breakdown
content or rollout-task-generation instructions (FR-009; that belongs to
Feature 7's `before_tasks` briefing). MUST NOT include instructions for
interacting with any feature-flag provider or its MCP server (FR-009; that
belongs to the `before_implement` briefing) — naming the provider in the
`Delivery Strategy` section's `Provider: LaunchDarkly` field is in scope, but
instructing the agent to call provider tools is not. MUST NOT require
`templates/rollout-section.md` to exist (FR-008). MUST NOT modify
`extension.yml`, the gate scripts, `rollout-config.template.yml`, or any
other `brief-*.md` command (spec.md Assumptions).

**Scale/Scope**: One file rewritten (`commands/brief-plan.md`, replacing its
placeholder body with the full doctrine), similar order of magnitude to
Feature 004's ~100-180 line rewrite of `commands/brief-specify.md` and
Feature 005's rewrite of `commands/brief-clarify.md`. No other files are
touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles. This plan was re-checked against each (superseding the
initial "unratified template" note carried forward from 001-005, which is no
longer accurate as of this feature):

- **I. Additive-Only Extension**: PASS — this feature only rewrites
  `commands/brief-plan.md`'s body (a `brief-*` command file), touches no core
  Spec Kit template.
- **II. Self-Gating, Near-Zero Noise**: PASS — FR-001/FR-003 require invoking
  the shared gate script first and emitting a one-line no-op with zero
  rollout content when no marker/signal is found (Story 2).
- **III. Strict Content Lineage**: PASS, with an explicit dependency on the
  v1.1.0 carve-out added alongside this feature. FR-004/Story 3 back-fills
  the `## Delivery Considerations` marker into `spec.md` at `/plan` time,
  derived from `/plan` arguments. Read literally, the principle's original
  text forbade "re-deriving... spec content from plan"; this back-fill is
  exactly that pattern. Resolved by ratifying a Principle III carve-out
  (v1.1.0) distinguishing gate-*state* marker back-fill (permitted, matches
  vision.md §5.2's "content lineage" design) from authored *content*
  derivation (still forbidden). This feature's back-fill complies with the
  carve-out's two conditions: (a) the back-filled marker verbatim-matches
  `contracts/rollout-gate-cli.md`'s heading/label convention (FR-004,
  data-model.md), and (b) no other `spec.md` content (requirements, user
  stories, success criteria) is authored or rewritten by this doctrine — only
  the marker heading and flag/intent line are written.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — this feature
  names `Provider: LaunchDarkly` as a label in `plan.md`'s Delivery Strategy
  (explicitly permitted from plan phase onward per vision.md §5.1) but
  contains no MCP tool-binding or provider-execution instructions (FR-009);
  that remains scoped to `before_implement`.
- **V. Credential Security Is Non-Negotiable**: PASS — this feature is
  content-authoring only; it introduces no credential handling, tokens, or
  config reads/writes.
- **VI. Guardrailed Provider Execution**: N/A — this principle governs
  `before_implement` provider actions; this feature is scoped to `before_plan`
  doctrine authoring and performs no provider execution.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/006-rollout-plan-doctrine/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

No `contracts/` directory is produced by this feature. This feature does not
define a new machine-readable interface — it authors prompt content that
targets the marker contract Feature 003 already published
(`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`). Duplicating
that contract here would risk drift; data-model.md instead documents the
prompt-content entities this feature adds (the Delivery Strategy section and
the `/plan` arguments sniff) and links to the 003 contract for the marker's
exact shape.

### Source Code (repository root)

This feature makes a single content change to the existing `rollout`
extension package (repository root, established in 001-extension-skeleton).
No `src/`, `tests/`, or app-style directories are introduced or needed —
there is no code to place in them.

```text
# Single project (Spec Kit extension package layout, extended from 001-005)
commands/
└── brief-plan.md         # MODIFIED: placeholder body replaced with full pre-plan doctrine
```

No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`,
`commands/brief-specify.md`, `commands/brief-clarify.md`, or any other
`commands/brief-*.md` file are made by this feature (spec.md Assumptions).
The `before_plan` hook wiring in `extension.yml` already targets
`commands/brief-plan.md`; only that file's body changes.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-005. This feature adds no new directories or files beyond rewriting the
body of the one command file named in the feature input.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution is ratified yet (see Constitution Check above), and this
feature introduces no architectural complexity (a single Markdown content
rewrite, no services, no scripts, no new projects, no non-standard
patterns) — this section intentionally has no entries.
