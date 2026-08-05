# Implementation Plan: Rollout Checklist Doctrine (Pre-Checklist Briefing)

**Branch**: `009-rollout-checklist-doctrine` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-rollout-checklist-doctrine/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/brief-checklist.md` (the content
the `before_checklist` hook injects) with pre-checklist doctrine from
vision.md §5.1, Decision D6: invoke the shared gate script (Feature 003) in
default mode against `spec.md`; on no marker (`hasFlags=false`, including
the diagnostic exit code), emit a one-line no-op and add no rollout content.
On marker present, instruct the agent to add a dedicated, additive
rollout-quality category to whatever checklist `/speckit.checklist` is
already generating, containing five items — flag naming defined,
environments/targeting specified, telemetry gates defined, rollback
conditions present, rollout phases ordered and complete — phrased as
requirements-quality checks (consistent with `/speckit.checklist`'s "unit
tests for English" convention: questions about whether the Delivery
Considerations marker / Delivery Strategy section are complete and
unambiguous, not implementation-verification statements) rather than as
status findings. The category is added regardless of whether `plan.md` yet
contains a `## Delivery Strategy` section (Feature 006) and regardless of
how many candidate flags the marker names (one shared category, not
duplicated per flag). Out of scope: any other checklist category (owned by
Spec Kit core), Delivery Strategy authoring doctrine (Feature 006), and any
provider/MCP interaction.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/brief-checklist.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-specify.md`, `brief-clarify.md`, `brief-plan.md`,
`brief-tasks.md`, `brief-analyze.md`, `brief-implement.md`, and
`connect.md`.

**Primary Dependencies**: None. Consumes (but does not modify) the existing
`## Delivery Considerations` / `Candidate flag(s):` marker contract
(`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`,
implemented by `scripts/bash/rollout-gate.sh` /
`scripts/powershell/rollout-gate.ps1`), the marker-writing/refinement
doctrine in `commands/brief-specify.md` (Feature 004) and
`commands/brief-clarify.md` (Feature 005), the `## Delivery Strategy`
section doctrine in `commands/brief-plan.md` (Feature 006), and the
existing `/speckit.checklist` checklist-generation conventions defined in
`.github/agents/speckit.checklist.agent.md` (category structure, `- [ ]
CHKxxx <item text>` ID format, "unit tests for requirements" item-phrasing
rules, additive/append-only file handling).

**Storage**: N/A — no data is persisted by this feature itself; the doctrine
it authors instructs the `/speckit.checklist` agent to add items to
whatever checklist file it is already writing (per that command's own
`checklists/[domain].md` file-handling rules), not something this feature's
deliverable does directly.

**Testing**: Manual/scripted verification per quickstart.md: walk through
the three user stories (marker present → rollout-quality category with all
five items appears; no marker → single-line no-op, no rollout content; plan
not yet written → items still appear, phrased as checks rather than
findings) using the doctrine text as the acting agent's instructions, and
confirm the resulting checklist file matches each story's acceptance
scenarios. Run `scripts/bash/rollout-gate.sh` against fixture feature
directories before and after to confirm `hasFlags`/`flags` parity and that
the briefing never mutates `spec.md`, mirroring the verification pattern
from Features 005-008. No automated test framework is introduced
(consistent with 001-008 precedent).

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs Spec Kit's `/speckit.checklist` command; no platform-specific
behavior is introduced.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text injected into agent
context per `/speckit.checklist` invocation; not performance-sensitive.

**Constraints**: MUST invoke the gate script's default mode (spec.md-only
check) before deciding whether to add rollout content (FR-001), matching
the gating pattern established in Features 004-008. MUST treat
`hasFlags=false` (including the diagnostic exit code) identically:
single-line no-op, no rollout-quality category or item added (FR-002). MUST
add a distinct rollout-quality category additive to whatever category/
categories the user's checklist request already produces (FR-003, FR-009),
containing at minimum the five named items (FR-004), each phrased as a
verifiable checklist item consistent with the existing `- [ ] CHKxxx
<item text>` format rather than a status report or finding (FR-005), worded
to be checked against the feature's actual rollout content rather than as
generic boilerplate (FR-006). MUST add the category regardless of whether
`plan.md` yet contains a `## Delivery Strategy` section — item presence
MUST NOT depend on the target artifact already being complete (FR-007).
MUST add a single shared category (not duplicated per flag) when the marker
names more than one candidate flag (FR-008). MUST remain scoped to the
rollout-quality category only — MUST NOT include other checklist
categories, Delivery Strategy authoring doctrine, or provider/MCP
instructions (FR-010). MUST replace the current placeholder body of
`commands/brief-checklist.md` in full (FR-011).

**Scale/Scope**: One file rewritten (`commands/brief-checklist.md`,
replacing its placeholder body with the full doctrine), similar order of
magnitude to Features 004-008's single-file rewrites (~120-200 lines). No
other files are touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles. This plan is checked against each:

- **I. Additive-Only Extension**: PASS — this feature only rewrites
  `commands/brief-checklist.md`'s body (a `brief-*` command file already
  wired to the `before_checklist` hook in `extension.yml`), touches no core
  Spec Kit template. The rollout-quality category itself is additive to
  whatever checklist content `/speckit.checklist` core logic already
  produces (FR-003, FR-009).
- **II. Self-Gating, Near-Zero Noise**: PASS — FR-001/FR-002 require
  invoking the shared gate script first and emitting a one-line no-op with
  zero rollout content added when no marker is found (Story 2), matching
  the pattern established in 003-008.
- **III. Strict Content Lineage**: PASS — this feature reads the marker only
  as a gate-state signal (via the shared gate script) and never authors or
  mutates `spec.md`/`plan.md` content; the rollout-quality items it adds
  live only in the checklist file it augments. No marker back-fill occurs in
  this feature, so the v1.1.0 carve-out does not apply here.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — this feature
  introduces no provider MCP tool-invocation instruction of any kind; it
  only adds requirements-quality checklist items about rollout content
  already defined by other features.
- **V. Credential Security Is Non-Negotiable**: PASS — this feature is
  content-authoring only; it introduces no credential handling, tokens, or
  config reads/writes.
- **VI. Guardrailed Provider Execution**: N/A — this principle governs
  `before_implement` provider actions; this feature is scoped to
  `before_checklist` doctrine authoring and performs no provider execution.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/009-rollout-checklist-doctrine/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

No `contracts/` directory is produced by this feature, for the same reason
as Features 004-008: this feature authors prompt content rather than a new
machine-readable interface. It targets two existing contracts/shapes —
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the
gate script's stdout shape, and Feature 006's `## Delivery Strategy`
section shape — plus the existing `/speckit.checklist` category/ID format
documented in `.github/agents/speckit.checklist.agent.md`. data-model.md
documents the rollout-quality category entity this feature adds and links
to both.

### Source Code (repository root)

This feature makes a single content change to the existing `rollout`
extension package (repository root, established in 001-extension-skeleton).
No `src/`, `tests/`, or app-style directories are introduced or needed —
there is no code to place in them.

```text
# Single project (Spec Kit extension package layout, extended from 001-008)
commands/
└── brief-checklist.md     # MODIFIED: placeholder body replaced with full pre-checklist doctrine
```

No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`,
`commands/brief-specify.md`, `commands/brief-clarify.md`,
`commands/brief-plan.md`, `commands/brief-tasks.md`,
`commands/brief-analyze.md`, or any other `commands/brief-*.md` file are
made by this feature (spec.md Assumptions). The `before_checklist` hook
wiring in `extension.yml` already targets `commands/brief-checklist.md`;
only that file's body changes.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-008. This feature adds no new directories or files beyond rewriting the
body of the one command file named in the feature input.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations to justify — this feature introduces no architectural
complexity (a single Markdown content rewrite, no services, no scripts, no
new dependencies).
