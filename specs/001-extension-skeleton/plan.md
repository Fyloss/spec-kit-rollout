# Implementation Plan: Rollout Extension Skeleton

**Branch**: `001-extension-skeleton` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-extension-skeleton/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Build a valid, installable Spec Kit extension package for `rollout` (id:
`rollout`): a manifest (`extension.yml`) declaring package metadata, 8
`provides.commands` entries (7 phase briefings + `connect`), 7 non-optional
`before_*` lifecycle hooks, and a config declaration for
`rollout-config.yml`/`rollout-config.template.yml`; plus root packaging files
(`README.md`, `LICENSE`, `CHANGELOG.md`, `.extensionignore`) and 8 placeholder
command markdown files. No doctrine, gate scripts, real config values, or MCP
wiring — those are later features. The manifest shape below is grounded in the
installed `specify-cli` 0.12.2 extension-manifest validator (see
Technical Context and research.md), not guessed from the vision doc alone.

## Technical Context

**Language/Version**: N/A — this feature is a declarative content package
(YAML manifest + Markdown command files), not compiled/interpreted
application code.

**Primary Dependencies**: Spec Kit `extension.yml` schema version "1.0", as
enforced by the installed `specify-cli` 0.12.2 extension manager
(`specify_cli.extensions.ExtensionManifest`).

**Storage**: N/A — static files only, no database or runtime persistence.

**Testing**: Manual/scripted CLI verification of the three acceptance flows
(`specify extension add --dev`, `specify extension list`, `specify extension
remove`) plus a naming/reference lint pass (regex + file-existence check)
described in quickstart.md. No unit test framework is introduced for this
feature.

**Target Platform**: Cross-platform — any environment running the `specify`
CLI (Linux/macOS/Windows) with a Spec Kit-initialized project.

**Project Type**: Single project — a Spec Kit extension package (content/config
distribution unit, not a service or application).

**Performance Goals**: N/A — package installation/validation is a one-shot,
non-performance-sensitive file operation.

**Constraints**: Must conform exactly to the schema enforced by the installed
extension manager: `extension.id = rollout`; all 8 command names match
`^speckit\.rollout\.[a-z0-9-]+$`; `hooks` is a top-level manifest key (not
nested under `provides`) with each of the 7 entries carrying `optional: false`;
`requires.speckit_version` is a valid PEP 440 specifier compatible with the
installed `0.12.2`; `.extensionignore` uses gitignore-pattern syntax; every
file referenced by the manifest must exist in the package.

**Scale/Scope**: Fixed, small package: 1 manifest, 8 placeholder command files,
1 config template, 4 root packaging files (README/LICENSE/CHANGELOG/.extensionignore)
— no growth expected within this feature.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (placeholder
section names and bracketed guidance only) — no principles have been ratified
for this project yet. There are therefore no constitutional gates to evaluate
for this feature. This plan proceeds without constitutional constraints.
**Recommendation** (non-blocking): ratify a project constitution before or
alongside later `rollout` features that introduce real doctrine and provider
behavior, since those carry more governance-worthy tradeoffs (e.g., guardrails
around auto-executing hooks, credential handling) than this packaging-only
feature.

## Project Structure

### Documentation (this feature)

```text
specs/001-extension-skeleton/
├── plan.md                       # This file (/speckit.plan command output)
├── research.md                   # Phase 0 output (/speckit.plan command)
├── data-model.md                 # Phase 1 output (/speckit.plan command)
├── quickstart.md                 # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── extension-manifest.md     # Phase 1 output: the manifest contract this package must satisfy
├── checklists/
│   └── requirements.md           # Already produced by /speckit.specify
└── tasks.md                      # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This feature is the extension package itself, delivered at the repository
root (this repo *is* the `rollout` package source). No `src/`, `tests/`, or
app-style directories are introduced — the deliverable is content/config, not
executable application code.

```text
# Option: Single project (Spec Kit extension package layout)
extension.yml                     # manifest: metadata, requires, provides.commands,
                                   # provides.config, hooks (7x before_*), config.defaults
README.md
LICENSE                           # MIT
CHANGELOG.md                      # records initial 1.0.0 release
.extensionignore                  # excludes .git/, .specify/, specs/, tests/, docs/, .github/ from installed copy

commands/
├── brief-specify.md              # placeholder: speckit.rollout.brief-specify
├── brief-clarify.md              # placeholder: speckit.rollout.brief-clarify
├── brief-plan.md                 # placeholder: speckit.rollout.brief-plan
├── brief-tasks.md                # placeholder: speckit.rollout.brief-tasks
├── brief-analyze.md              # placeholder: speckit.rollout.brief-analyze
├── brief-checklist.md            # placeholder: speckit.rollout.brief-checklist
├── brief-implement.md            # placeholder: speckit.rollout.brief-implement
└── connect.md                    # placeholder: speckit.rollout.connect

rollout-config.template.yml       # placeholder config template (non-secret pointers only)
```

Directories from the vision's full layout that belong to *later* features
(`scripts/bash|powershell` gate scripts, `templates/rollout-section.md`) are
intentionally **not** created here — out of scope per the input.

**Structure Decision**: Single-project, package-at-repo-root layout (above).
Chosen because a Spec Kit extension is installed by pointing at a directory
containing `extension.yml` at its root (confirmed by the installed
`specify-cli` extension manager, which resolves command/config file paths
relative to the manifest's own directory) — nesting the package under a
subfolder would only add indirection with no benefit, since this repository's
sole purpose is to *be* the `rollout` package.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution is ratified yet (see Constitution Check above), and this
feature introduces no architectural complexity (no services, no extra
projects, no non-standard patterns) — this section intentionally has no
entries.

