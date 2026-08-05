# Implementation Plan: Rollout Analyze Doctrine (Pre-Analyze Briefing)

**Branch**: `008-rollout-analyze-doctrine` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-rollout-analyze-doctrine/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/brief-analyze.md` (the content the
`before_analyze` hook injects) with pre-analyze doctrine from vision.md §5.1,
Decision D6: invoke the shared gate script (Feature 003) in default mode
against `spec.md`; on no marker (`hasFlags=false`, including the diagnostic
exit code), emit a one-line no-op with no further rollout-chain checks. On
marker present, instruct the agent to (1) treat the marker, the `plan.md`
`## Delivery Strategy` section (Feature 006), and any `tasks.md` rollout
tasks (Feature 007) as intentional, already-cross-referenced content —
never reporting any of them as orphaned requirements, unmapped tasks,
duplication, or ambiguity in analyze's standard detection passes — and (2)
independently verify the rollout chain's own consistency by checking
`plan.md` for the `## Delivery Strategy` heading and, if present, `tasks.md`
for at least one traceable rollout task (matched by presence, reusing the
six categories from Feature 007). Two distinct, HIGH-severity findings are
possible when the chain is broken: marker-present-no-Delivery-Strategy, and
Delivery-Strategy-present-no-rollout-tasks; when the full chain is present,
no gap or orphan finding is emitted for rollout content. This is the first
doctrine feature to reason about all three rollout artifacts (spec, plan,
tasks) in one pass, and it is strictly report-only — it MUST NOT instruct
editing any artifact to fix a detected gap. Out of scope: modifying
artifacts, and per-flag chain granularity (feature-level presence/absence
suffices).

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/brief-analyze.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-specify.md`, `brief-clarify.md`, `brief-plan.md`,
`brief-tasks.md`, `brief-checklist.md`, `brief-implement.md`, and
`connect.md`.

**Primary Dependencies**: None. Consumes (but does not modify) the existing
`## Delivery Considerations` / `Candidate flag(s):` marker contract
(`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`,
implemented by `scripts/bash/rollout-gate.sh` /
`scripts/powershell/rollout-gate.ps1`), the marker-writing/refinement
doctrine in `commands/brief-specify.md` (Feature 004) and
`commands/brief-clarify.md` (Feature 005), the `## Delivery Strategy`
section doctrine in `commands/brief-plan.md` (Feature 006), the six
rollout-task-category doctrine in `commands/brief-tasks.md` (Feature 007),
and the existing `/speckit.analyze` severity model and findings-table
format defined in `.github/agents/speckit.analyze.agent.md` (CRITICAL/HIGH/
MEDIUM/LOW; `ID | Category | Severity | Location(s) | Summary |
Recommendation`).

**Storage**: N/A — no data is persisted by this feature itself; the doctrine
it authors instructs the `/speckit.analyze` agent to add rollout-chain
findings to that command's own in-memory report as a downstream effect of
following the doctrine, not something this feature's deliverable does
directly.

**Testing**: Manual/scripted verification per quickstart.md: walk through
the four user stories (consistent chain → zero false-positive rollout
findings; no marker → single-line no-op, report unaffected; marker present
but no Delivery Strategy → one distinct HIGH finding; Delivery Strategy
present but no rollout tasks → one distinct, differently-worded HIGH
finding) using the doctrine text as the acting agent's instructions, and
confirm the resulting analyze report matches each story's acceptance
scenarios. Run `scripts/bash/rollout-gate.sh` against fixture feature
directories before and after to confirm `hasFlags`/`flags` parity,
mirroring the verification pattern from Features 005-007. No automated test
framework is introduced (consistent with 001-007 precedent).

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs Spec Kit's `/speckit.analyze` command; no platform-specific
behavior is introduced.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text injected into agent
context per `/speckit.analyze` invocation; not performance-sensitive.

**Constraints**: MUST invoke the gate script's default mode (spec.md-only
check) rather than any other mode (FR-001), matching the two-stage gating
pattern established in Feature 007. MUST treat `hasFlags=false` (including
the diagnostic exit code) identically: one-line no-op, no rollout-chain
checks, no alteration of any other part of the standard analyze report
(FR-002). MUST instruct treating the marker, the Delivery Strategy section
(when present), and rollout tasks (when present) as intentional and
already-cross-referenced — MUST NOT let them be reported as orphaned
requirements, unmapped tasks, duplication, or ambiguity findings (FR-003).
MUST check `plan.md` for the `## Delivery Strategy` heading using the same
heading-detection convention as Features 006-007 (FR-004). MUST emit a
distinct, non-suppressible finding when that heading is absent (FR-005) or,
when present, when `tasks.md` has no traceable rollout task (FR-007) — the
two findings MUST be worded distinguishably from each other and MUST carry
HIGH severity per the existing analyze severity model and Constitution
Principle III (FR-009). MUST report the chain as fully consistent with zero
gap/orphan findings when all three links are present (FR-008). MUST be
strictly report-only — MUST NOT instruct editing `spec.md`, `plan.md`, or
`tasks.md` to fix any detected gap (FR-010). MUST NOT introduce any new
required artifact or section beyond the three already established by prior
features (FR-011). MUST NOT modify `extension.yml`, the gate scripts,
`rollout-config.template.yml`, or any other `brief-*.md` command (spec.md
Assumptions).

**Scale/Scope**: One file rewritten (`commands/brief-analyze.md`, replacing
its placeholder body with the full doctrine), similar order of magnitude to
Features 004-007's single-file rewrites (~150-250 lines, slightly larger
than 004-007 since it reasons about three artifacts instead of one or two).
No other files are touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles. This plan is checked against each:

- **I. Additive-Only Extension**: PASS — this feature only rewrites
  `commands/brief-analyze.md`'s body (a `brief-*` command file already wired
  to the `before_analyze` hook in `extension.yml`), touches no core Spec Kit
  template.
- **II. Self-Gating, Near-Zero Noise**: PASS — FR-001/FR-002 require
  invoking the shared gate script first and emitting a one-line no-op with
  zero rollout-chain checks when no marker is found (Story 2), matching the
  pattern established in 003-007.
- **III. Strict Content Lineage**: PASS — this feature validates, but never
  re-derives, the existing one-direction chain (spec marker → plan Delivery
  Strategy → tasks rollout tasks). FR-004/FR-006 require independently
  checking `plan.md` and `tasks.md` directly rather than trusting the gate
  script's spec.md-only signal for the full chain; FR-005/FR-007 require
  reporting — never silently repairing or re-deriving — a broken link; the
  two findings are explicitly required to carry HIGH severity because a
  broken rollout chain is named as a Principle III concern (FR-009). No
  marker back-fill occurs in this feature (unlike Feature 006's plan-time
  back-fill), so the v1.1.0 carve-out does not apply here.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — this feature
  introduces no provider MCP tool-invocation instruction of any kind; it
  only inspects existing artifact text for heading/task presence.
- **V. Credential Security Is Non-Negotiable**: PASS — this feature is
  content-authoring only; it introduces no credential handling, tokens, or
  config reads/writes.
- **VI. Guardrailed Provider Execution**: N/A — this principle governs
  `before_implement` provider actions; this feature is scoped to
  `before_analyze` doctrine authoring and performs no provider execution.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/008-rollout-analyze-doctrine/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

No `contracts/` directory is produced by this feature, for the same reason
as Features 004-007: this feature authors prompt content rather than a new
machine-readable interface. It targets three existing contracts/shapes —
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the
gate script's stdout shape, Feature 006's `## Delivery Strategy` section
shape, and Feature 007's six rollout-task categories — plus the existing
`/speckit.analyze` severity/findings-table format documented in
`.github/agents/speckit.analyze.agent.md`. data-model.md documents the
rollout-chain and rollout-chain-finding entities this feature adds and
links to all of these.

### Source Code (repository root)

This feature makes a single content change to the existing `rollout`
extension package (repository root, established in 001-extension-skeleton).
No `src/`, `tests/`, or app-style directories are introduced or needed —
there is no code to place in them.

```text
# Single project (Spec Kit extension package layout, extended from 001-007)
commands/
└── brief-analyze.md       # MODIFIED: placeholder body replaced with full pre-analyze doctrine
```

No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`,
`commands/brief-specify.md`, `commands/brief-clarify.md`,
`commands/brief-plan.md`, `commands/brief-tasks.md`, or any other
`commands/brief-*.md` file are made by this feature (spec.md Assumptions).
The `before_analyze` hook wiring in `extension.yml` already targets
`commands/brief-analyze.md`; only that file's body changes.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-007. This feature adds no new directories or files beyond rewriting the
body of the one command file named in the feature input.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations to justify — this feature introduces no architectural
complexity (a single Markdown content rewrite, no services, no scripts, no
new dependencies).
