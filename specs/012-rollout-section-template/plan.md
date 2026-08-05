# Implementation Plan: Rollout Section Template

**Branch**: `012-rollout-section-template` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-rollout-section-template/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Create `templates/rollout-section.md` — a new, repo-root, OPTIONAL structural
reference file (no extension-package precedent exists for a bare, passive
Markdown reference; every prior feature 004-011 rewrote an executable-context
`commands/*.md` doctrine file instead). The file defines, in the exact field
order shown in vision.md §9, a reusable skeleton for the `## Delivery
Strategy` block: feature flag name, provider, phased rollout (multiple
ordered stages), targeting, telemetry gates, and rollback conditions. Its own
content must explicitly state it is optional — a structural reference for a
human/agent to consult, never a schema the plan phase parses or depends on.
`commands/brief-plan.md` (Feature 006, already implemented) already contains
an "Optional template reference" paragraph that *may* consult this file for
formatting examples but never requires its presence; this feature's job is
only to make that optional reference resolvable by creating the file it
describes, without touching Feature 006's doctrine at all (Constitution
Principle I — additive only, and this feature's own FR-004 already commits
006 to independence, so no code/doctrine change is needed there). No
executable logic, no gate-script dependency, no `extension.yml` change (the
file is a plain content asset, not a declared `provides.commands` entry or
hook).

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is a single static
Markdown reference file, `templates/rollout-section.md`, read by a human or
by an agent executing `commands/brief-plan.md`'s doctrine; it is never parsed
programmatically by any script in this repository.

**Primary Dependencies**: None new. The file's content structure is fully
derived from `docs/foundation/vision.md` §9's worked example (`Feature flag`,
`Provider`, `Rollout:` with ordered `Phase N:` lines, `Targeting`,
`Telemetry gates`, `Rollback`) and is referenced (read-only, optionally) by
the already-implemented `commands/brief-plan.md` (Feature 006). No other
file consumes it.

**Storage**: N/A — one static file, no data persistence, no config-schema
touchpoint (Feature 002's `rollout-config.template.yml` is untouched).

**Testing**: Manual verification per quickstart.md: (1) confirm the file
exists at `templates/rollout-section.md` and contains all six required
elements in vision.md §9's exact order, each clearly labeled and explained;
(2) confirm the file's own text states it is optional/non-required; (3)
confirm deleting/renaming the file does not change any existing
`commands/brief-plan.md` doctrine behavior (Feature 006's own quickstart
scenarios continue to pass unmodified, since 006 already implements the
"works with or without the template" requirement independent of this
feature); (4) confirm no other prior feature's quickstart or acceptance
check result changes with the file present vs. absent (SC-003). No unit
tests, no code, no CI — consistent with the content-only verification
pattern used for Features 004-009.

**Target Platform**: N/A — plain Markdown consumed by whatever AI coding
agent or human reader opens it; no platform-specific behavior.

**Project Type**: Single project — content-only addition to the existing
`rollout` extension package (repository root). Adds one new top-level
directory (`templates/`) that does not exist yet in this repo; no new source
tree, no build step.

**Performance Goals**: N/A — a passive reference file with no runtime cost.

**Constraints**: MUST NOT be required by `commands/brief-plan.md` or any
other doctrine (FR-004/FR-005) — its absence must produce byte-for-byte
identical plan-phase behavior to its presence, for both rollout and
non-rollout features (spec.md User Story 2). MUST contain no executable
logic and no gate-script dependency (FR-007). MUST NOT introduce or imply a
standalone `rollout.md` artifact (FR-006 — V1 scope keeps Delivery Strategy
inside `plan.md` only, per vision.md §9's explicit "No mandatory `rollout.md`
in V1" statement). MUST state its own optional status within its own content
(FR-003). MUST NOT change `extension.yml` commands/hooks (FR-007). MUST NOT
change the pass/fail outcome of any other feature's existing quickstart or
acceptance validation, verified by re-running the affected checks with the
file absent (FR-008/SC-003).

**Scale/Scope**: One new file created (`templates/rollout-section.md`), one
new top-level directory (`templates/`). No existing file is modified —
notably, `commands/brief-plan.md` is read but NOT edited by this feature
(its existing "Optional template reference" paragraph from Feature 006
already anticipates this file's existence and needs no change).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles plus Scope Constraints. This plan is checked against each:

- **I. Additive-Only Extension**: PASS — this feature adds a new, standalone
  content file at `templates/rollout-section.md`; it edits zero Spec Kit core
  templates and zero existing `commands/*.md` doctrine files (not even
  `commands/brief-plan.md`, whose existing optional-reference paragraph
  already anticipates this file). No hook, no command registration change.
- **II. Self-Gating, Near-Zero Noise**: N/A by design — this feature has no
  `before_*` hook and performs no marker-based gating itself; it is a passive
  reference asset, not a briefing command. The self-gating behavior that
  matters (whether `brief-plan.md` uses this file or not) is entirely
  Feature 006's existing, already-implemented responsibility and is
  unaffected by this feature.
- **III. Strict Content Lineage**: PASS/N/A — this feature reads no artifact
  content (spec.md/plan.md/tasks.md) and writes no marker or heading text; it
  only mirrors the *field labels* already fixed by vision.md §9 and Feature
  006's implemented doctrine (`Feature flag`, `Provider`, `Rollout:` phases,
  `Targeting`, `Telemetry gates`, `Rollback`). No lineage direction is
  established or altered by a static reference file.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS with one
  documented exception mirroring Feature 006's own precedent — the template,
  like `commands/brief-plan.md`, names `Provider: LaunchDarkly` in its
  worked/example line (vision.md §9's example itself names LaunchDarkly),
  consistent with 006 being "the first briefing expected to name LaunchDarkly
  explicitly" (repo memory note). This is not a capability wrapper or a
  per-provider control-flow branch — it is a single labeled example value in
  a static reference file, matching the same acceptable precedent Feature
  006 already established. No MCP interaction occurs in this feature at all.
- **V. Credential Security Is Non-Negotiable**: PASS — the template contains
  no token, no env-var value, no credential-shaped placeholder; the six
  required elements (flag, provider, phases, targeting, telemetry gates,
  rollback) contain no secret-shaped field at all.
- **VI. Guardrailed Provider Execution (NON-NEGOTIABLE)**: N/A — this feature
  performs no provider execution and touches no `before_implement` behavior;
  it is a passive plan-phase reference file only.
- **Scope Constraints**: PASS — no new provider is introduced (still
  LaunchDarkly-only, matching vision.md §9's example); `speckit.rollout.connect`
  is untouched.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/012-rollout-section-template/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

Deliberately **no `contracts/` directory**, matching Features 004-010's
precedent (as opposed to 011, which added one for a genuinely new adapter
interface). This feature authors a single passive reference file with no
external interface, API, or schema of its own to document — its "contract"
with the rest of the extension is simply "an optional file at this path, in
this field order," which is already fully specified by spec.md's FR-001/
FR-002 and vision.md §9's worked example; a separate contracts doc would
duplicate that with no new information (documented further in research.md).

### Source Code (repository root)

No `src/`/`tests/` project tree — this is a content-only extension package.
This feature's only deliverable is one new file in a new top-level directory:

```text
templates/
└── rollout-section.md    # New file created by this feature (dir did not exist before)
```

**Structure Decision**: Single project, content-only, matching Features
004-011's precedent of a single-file (here, single-new-file) deliverable.
`commands/brief-plan.md` is read for cross-reference but not modified.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
