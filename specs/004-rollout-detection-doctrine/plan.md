# Implementation Plan: Rollout Detection Doctrine (Pre-Specify Briefing)

**Branch**: `004-rollout-detection-doctrine` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-rollout-detection-doctrine/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/brief-specify.md` (the content the
`before_specify` hook injects) with the full progressive-delivery detection
doctrine from vision.md §4/§5.1/§5.2: five detection heuristic categories
(high-risk/irreversible change, major UX change, progressive migration,
explicit cohort/audience language, performance/infra sensitivity), advisory
framing (propose + explain on match, ask exactly one clarifying question on
ambiguity, respect a decline), and exact-convention instructions for writing
the `## Delivery Considerations` marker (heading + `Candidate flag(s):` label)
so it is byte-for-byte compatible with the Feature 003 gate-script contract.
No provider name is ever written at this phase. This is a content-authoring
feature only — no scripts, schema, or other `brief-*.md` command changes.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/brief-specify.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-analyze.md`, `brief-checklist.md`, `brief-clarify.md`,
`brief-implement.md`, `brief-plan.md`, `brief-tasks.md`, and `connect.md`.

**Primary Dependencies**: None. Consumes (but does not modify) the existing
`## Delivery Considerations` / `Candidate flag(s):` marker convention defined
by `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` and
implemented by `scripts/bash/rollout-gate.sh` / `scripts/powershell/rollout-gate.ps1`.

**Storage**: N/A — no data is persisted by this feature itself; the doctrine
it authors instructs the `/speckit.specify` agent to write the marker into
that feature's own `spec.md` (a downstream effect, not something this
feature's deliverable does directly).

**Testing**: Manual/scripted verification per quickstart.md: walk through the
four user stories (clear rollout candidate, trivial feature, ambiguous
signal, explicit decline) using the doctrine text as the acting agent's
instructions, and confirm resulting spec.md content (or absence of it)
matches each story's acceptance scenarios. Where a marker is expected, run
`scripts/bash/rollout-gate.sh` against the fixture feature directory and
confirm `hasFlags=true` with the correct flag name(s), per SC-003. No
automated test framework is introduced (consistent with 001/002/003
precedent — this repository has no code to unit-test for this feature).

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs Spec Kit's `/speckit.specify` command; no platform-specific
behavior is introduced.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text injected into agent
context per `/speckit.specify` invocation; not performance-sensitive.

**Constraints**: MUST reproduce the `## Delivery Considerations` heading and
`Candidate flag(s):` label exactly as consumed by
`scripts/bash/rollout-gate.sh`'s `extract_flags_line` matching (verified in
repo memory: case-insensitive match on the literal substring
`candidate flag(s):`, heading must be `^## Delivery Considerations` with no
trailing text) so SC-003 (gate script parity) holds. MUST NOT name any
feature-flag provider (FR-004/FR-009). MUST NOT include plan/tasks-phase
doctrine content (`Delivery Strategy`, rollout task lists) or provider/MCP
interaction instructions (FR-009) — those remain scoped to the `before_plan`,
`before_tasks`, and `before_implement` features named in vision.md §5.1.
MUST NOT modify `extension.yml`, the gate scripts, `rollout-config.template.yml`,
or any other `brief-*.md` command (spec.md Assumptions).

**Scale/Scope**: One file rewritten (`commands/brief-specify.md`, replacing
its ~10-line placeholder body with the full doctrine, likely 100-180 lines).
No other files are touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (placeholder
section names and bracketed guidance only) — no principles have been
ratified for this project yet, unchanged since 001-extension-skeleton,
002-config-system, and 003-rollout-gate-mechanism. There are therefore no
constitutional gates to evaluate for this feature. This plan proceeds
without constitutional constraints. **Recommendation** (non-blocking,
carried forward from 001/002/003): ratify a project constitution before or
alongside the `before_plan`/`before_implement` features, since those
introduce real provider/credential interaction — more governance-worthy than
this content-only doctrine feature.

## Project Structure

### Documentation (this feature)

```text
specs/004-rollout-detection-doctrine/
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
prompt-content entities this feature adds and links to the 003 contract for
the marker's exact shape.

### Source Code (repository root)

This feature makes a single content change to the existing `rollout`
extension package (repository root, established in 001-extension-skeleton).
No `src/`, `tests/`, or app-style directories are introduced or needed —
there is no code to place in them.

```text
# Single project (Spec Kit extension package layout, extended from 001/002/003)
commands/
└── brief-specify.md      # MODIFIED: placeholder body replaced with full detection doctrine
```

No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`, or
any other `commands/brief-*.md` file are made by this feature (spec.md
Assumptions). The `before_specify` hook wiring in `extension.yml` already
targets `commands/brief-specify.md`; only that file's body changes.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001/002/003. This feature adds no new directories or files beyond rewriting
the body of the one command file named in the feature input.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution is ratified yet (see Constitution Check above), and this
feature introduces no architectural complexity (a single Markdown content
rewrite, no services, no scripts, no new projects, no non-standard
patterns) — this section intentionally has no entries.
