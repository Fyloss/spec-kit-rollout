# Implementation Plan: Rollout Configuration System

**Branch**: `002-config-system` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-config-system/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Fully populate `rollout-config.template.yml` (superseding the feature-001
placeholder) with the complete non-secret configuration schema — pluggable
`provider` selector, LaunchDarkly project key/environment placeholders, a
pinned MCP server reference, the token env-var name, and a nested
`hooks.enabled` toggle — with inline comments warning against committing
secrets. Document the four-layer resolution order (extension defaults →
project config → local override → `SPECKIT_ROLLOUT_*` env vars) and the exact
resolved paths, grounded in the installed `specify-cli` 0.12.2
`ConfigManager` source (not guessed from the vision doc alone), including a
real quirk of its env-var parser that shapes the schema's field-naming
choices. Update `extension.yml`'s `config.defaults`/`config_schema` to match
the migrated nested schema, and document the layering + adoption steps
(including the local-override `.gitignore` responsibility) in `README.md`.

## Technical Context

**Language/Version**: N/A — this feature is declarative configuration
(YAML template + manifest defaults) and documentation, not application code.

**Primary Dependencies**: Spec Kit's built-in `ConfigManager`
(`specify_cli.extensions.ConfigManager`), as implemented by the installed
`specify-cli` 0.12.2 — this feature does not introduce a config loader of its
own; it only supplies the files that loader reads.

**Storage**: N/A — static YAML files only (shipped template, project config,
gitignored local override); no database or runtime persistence.

**Testing**: Manual/scripted verification per quickstart.md: YAML-parse and
secret-free checks on the template, and a real resolution check using the
installed `ConfigManager` class directly (`get_config()`) to confirm
precedence across all four layers. No unit test framework is introduced.

**Target Platform**: Cross-platform — any environment running the `specify`
CLI with this extension installed (same as feature 001).

**Project Type**: Single project — extends the existing `rollout` extension
package (repository root) delivered in 001-extension-skeleton; no new
top-level project structure.

**Performance Goals**: N/A — one-shot file read/merge at doctrine invocation
time, not performance-sensitive.

**Constraints**: Must conform to the *actual* behavior of the installed
`ConfigManager`, verified from source
(`specify_cli/extensions/__init__.py:2657-2840`), not just the vision doc's
prose: (1) project config resolves at
`.specify/extensions/rollout/rollout-config.yml`; (2) local override resolves
at `.specify/extensions/rollout/local-config.yml`; (3) env vars are matched
by the prefix `SPECKIT_ROLLOUT_` and the remainder is split on **every**
underscore to build a nested dict — so any leaf key containing an underscore
(e.g. `project_key`, `token_env_var`) cannot be cleanly targeted by an env
var (it would be misinterpreted as further nesting); (4) env var values are
always raw strings (no boolean coercion), so a toggle field must be validated
by its consumer, not by `ConfigManager` itself; (5) `_get_extension_defaults`
reads `config.defaults` from the **installed copy** of `extension.yml` at
`.specify/extensions/rollout/extension.yml`, so that file's defaults must
stay in sync with the template's documented defaults.

**Scale/Scope**: One template file (~60-80 lines with comments), one schema
contract doc, a small `README.md` addition, and a small `extension.yml`
update — no new directories, no growth expected within this feature.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (placeholder
section names and bracketed guidance only) — no principles have been ratified
for this project yet, unchanged since 001-extension-skeleton. There are
therefore no constitutional gates to evaluate for this feature. This plan
proceeds without constitutional constraints. **Recommendation** (non-blocking,
carried forward from 001): ratify a project constitution before or alongside
features that introduce real doctrine and provider behavior, since credential
handling and auto-executing hooks are more governance-worthy than this
config-schema feature.

## Project Structure

### Documentation (this feature)

```text
specs/002-config-system/
├── plan.md                        # This file (/speckit.plan command output)
├── research.md                    # Phase 0 output (/speckit.plan command)
├── data-model.md                  # Phase 1 output (/speckit.plan command)
├── quickstart.md                  # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── rollout-config-schema.md   # Phase 1 output: the config file contract this feature must satisfy
├── checklists/
│   └── requirements.md            # Already produced by /speckit.specify
└── tasks.md                       # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This feature extends the existing `rollout` extension package (delivered at
the repository root in 001-extension-skeleton). No `src/`, `tests/`, or
app-style directories are introduced — the deliverable is a fully-populated
config template plus documentation, not executable application code.

```text
# Single project (Spec Kit extension package layout, extended from 001)
rollout-config.template.yml   # UPDATED: full non-secret schema (provider,
                               # launchdarkly.project_key/environments, mcp.*,
                               # hooks.enabled) with secret-warning comments

extension.yml                 # UPDATED: config.defaults / config_schema
                               # migrated to the nested hooks.enabled shape,
                               # kept in sync with the template's defaults

README.md                     # UPDATED: "Configuration" section documenting
                               # the four-layer resolution order, the
                               # resolved project/local config paths, and the
                               # adopting project's .gitignore responsibility
                               # for local-config.yml
```

No new runtime files are created by this feature. The *resolved* project
configuration (`.specify/extensions/rollout/rollout-config.yml`) and local
override (`.specify/extensions/rollout/local-config.yml`) are per-project
runtime artifacts produced by whoever installs and configures the extension
in their own project — they are not part of this repository's own tracked
source (this repo's `.gitignore` already excludes `.specify/extensions/` as
its own dev-install artifact; see research.md).

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-extension-skeleton. This feature only updates existing root files
(`rollout-config.template.yml`, `extension.yml`, `README.md`) — no new
directories are warranted for a documentation/config-schema feature.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution is ratified yet (see Constitution Check above), and this
feature introduces no architectural complexity (no services, no extra
projects, no non-standard patterns) — this section intentionally has no
entries.
