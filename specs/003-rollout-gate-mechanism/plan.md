# Implementation Plan: Rollout Gate Mechanism

**Branch**: `003-rollout-gate-mechanism` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-rollout-gate-mechanism/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Deliver the two cross-platform gate scripts (`scripts/bash/rollout-gate.sh`,
`scripts/powershell/rollout-gate.ps1`) that implement the self-gating state
mechanism shared by all seven rollout hooks: detect the `## Delivery
Considerations` marker (a stable heading token) in the current feature's
`spec.md` (or additionally `plan.md`/`tasks.md` in `--mode analyze`), fold in
the resolved `hooks.enabled` toggle from the 002-config-system contract as an
override, and emit a small, dependency-free machine-readable result
(`hasFlags`, candidate flag names, source) plus a distinct exit code per
outcome so briefing commands can branch without parsing text. No provider
code, no YAML library, no Python dependency — matching the extension's
existing "no wrapper, plain text match" posture — and no phase-doctrine
content (deferred to the seven per-phase features that will each wire their
`brief-*.md` command to this contract).

## Technical Context

**Language/Version**: POSIX-compatible shell (`sh`/`bash`, no bashisms beyond
what `.specify/scripts/bash/*.sh` already relies on) for
`scripts/bash/rollout-gate.sh`; Windows PowerShell 5.1+ / PowerShell 7+ for
`scripts/powershell/rollout-gate.ps1`.

**Primary Dependencies**: None new. No `yq`/`jq`/Python/YAML-library
dependency is introduced — marker detection and the single `hooks.enabled`
field are both extracted with plain text matching (`grep`/`awk`-class
operations in bash, `Select-String`-class operations in PowerShell), the same
"deterministic text match" posture the marker convention itself already
requires (spec.md edge cases). `jq`/`python3` are used only opportunistically,
exactly as `.specify/scripts/bash/common.sh` already does for `feature.json`,
with a `grep`/`sed` last-resort fallback — no new hard dependency.

**Storage**: N/A — reads existing text files (`spec.md`, optionally
`plan.md`/`tasks.md`, and the three config layers from 002-config-system);
writes nothing.

**Testing**: Manual/scripted verification per quickstart.md: both scripts run
against a small set of fixture feature directories (marker present/absent,
hooks enabled/disabled, analyze vs. default mode) with results compared for
parity. No test framework is introduced (consistent with 001/002 precedent).

**Target Platform**: Cross-platform — Linux/macOS (`sh`) and Windows
(PowerShell) — same target as the rest of the extension.

**Project Type**: Single project — extends the existing `rollout` extension
package (repository root), adding a `scripts/` directory. No new top-level
project structure.

**Performance Goals**: N/A — one-shot text search per hook invocation over a
handful of small markdown/YAML files; not performance-sensitive.

**Constraints**: Must resolve the current feature's own directory using the
same convention Spec Kit's own scripts use (`SPECIFY_FEATURE_DIRECTORY` env
var, else `.specify/feature.json`'s `feature_directory` key — see research.md)
without sourcing or depending on core's `.specify/scripts/bash/common.sh`
internals, since an extension has no stated compatibility contract with
core's internal function names/layout. Must honor the exact `hooks.enabled`
resolution precedence documented by 002-config-system's
[rollout-config-schema.md](../002-config-system/contracts/rollout-config-schema.md)
contract (extension defaults → project config → local override → env var,
highest wins) using only single-field text extraction, per that contract's
explicit note that "the parsing implementation belongs to the feature that
ships the gate script." Must fail safe (`hasFlags=false`, diagnostic exit
code) when the feature directory cannot be resolved, per spec.md's edge
cases. Must produce identical `hasFlags` and candidate-flag results from both
script implementations for the same inputs (FR-013).

**Scale/Scope**: Two new script files (~100-200 lines each including
comments), one new CLI contract doc, one data-model doc, one quickstart
doc — no new runtime services, no changes to `commands/*.md` (wiring the
seven briefing commands to this contract is left to the per-phase doctrine
features named in vision.md 5.1, which is where the deferred doctrine content
they inject also lives).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (placeholder
section names and bracketed guidance only) — no principles have been ratified
for this project yet, unchanged since 001-extension-skeleton and
002-config-system. There are therefore no constitutional gates to evaluate
for this feature. This plan proceeds without constitutional constraints.
**Recommendation** (non-blocking, carried forward from 001/002): ratify a
project constitution before or alongside features that introduce real
doctrine and provider behavior (starting with the per-phase `brief-*.md`
features that will consume this gate contract), since credential handling
and auto-executing hooks are more governance-worthy than this gate-mechanism
feature.

## Project Structure

### Documentation (this feature)

```text
specs/003-rollout-gate-mechanism/
├── plan.md                        # This file (/speckit.plan command output)
├── research.md                    # Phase 0 output (/speckit.plan command)
├── data-model.md                  # Phase 1 output (/speckit.plan command)
├── quickstart.md                  # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── rollout-gate-cli.md        # Phase 1 output: the gate scripts' CLI contract
├── checklists/
│   └── requirements.md            # Already produced by /speckit.specify
└── tasks.md                       # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This feature extends the existing `rollout` extension package (delivered at
the repository root in 001-extension-skeleton, config-schema-extended in
002-config-system) with a new `scripts/` directory. No `src/`, `tests/`, or
app-style directories are introduced — the deliverable is a pair of small,
dependency-free CLI scripts plus documentation, matching the project's
existing package-at-repo-root layout.

```text
# Single project (Spec Kit extension package layout, extended from 001/002)
scripts/
├── bash/
│   └── rollout-gate.sh           # NEW: POSIX-shell gate script
└── powershell/
    └── rollout-gate.ps1          # NEW: PowerShell gate script
```

No changes to `commands/*.md`, `extension.yml`, or `rollout-config.template.yml`
are made by this feature. The seven `brief-*.md` placeholder commands remain
placeholders — wiring each one to invoke this contract (and injecting its own
phase-appropriate doctrine) is explicitly deferred to the per-phase features
named in vision.md 5.1, so this feature's contract can be authored and
validated once, independent of any specific hook's doctrine content.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-extension-skeleton and 002-config-system. This feature adds exactly one
new directory (`scripts/`) with the two scripts named explicitly in the
feature input — no other structural changes are warranted.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution is ratified yet (see Constitution Check above), and this
feature introduces no architectural complexity (two small standalone
scripts, no services, no extra projects, no non-standard patterns) — this
section intentionally has no entries.
