# Research: Rollout Extension Skeleton

The feature input was fully prescriptive (exact manifest fields, exact command
list, exact hook list) and the spec.md `Assumptions` section resolved every
remaining open value. The one substantive risk was that the vision document
(section 12) describes an aspirational layout that could differ from what the
*installed* Spec Kit tooling actually validates. Rather than guess, the actual
extension manifest validator was read directly from the installed `specify-cli`
0.12.2 package (see repo-memory note
`spec-kit-extension-schema.md` for the saved reference). Findings below.

## Decision: Manifest top-level shape

- **Decision**: Use top-level keys `schema_version`, `extension`, `requires`,
  `provides`, and a **top-level** `hooks` key (hooks are siblings of
  `provides`, not nested inside it).
- **Rationale**: Verified directly in
  `specify_cli/extensions/__init__.py::ExtensionManifest._validate()` —
  `REQUIRED_FIELDS = ["schema_version", "extension", "requires", "provides"]`
  and hook data is read from `self.data.get("hooks", {})`, a sibling of
  `provides`.
- **Alternatives considered**: Nesting hooks under `provides.hooks` (matches a
  naive reading of "extensions can provide commands, config, templates, and
  hooks" in the vision doc) — rejected because the installed validator would
  never see it (silently inert, `has_hooks` would always be `False`), which
  would fail acceptance criteria ("7 hooks... enabled").

## Decision: Command naming and file validation

- **Decision**: All 8 commands declared as
  `{name: "speckit.rollout.<slug>", file: "commands/<slug>.md", description: "..."}`.
- **Rationale**: `EXTENSION_COMMAND_NAME_PATTERN = re.compile(r"^speckit\.([a-z0-9-]+)\.([a-z0-9-]+)$")`
  and a separate namespace check requires the middle segment to equal
  `extension.id` ("rollout"), matching the requested
  `^speckit\.rollout\.[a-z0-9-]+$` pattern exactly. `file` paths are checked
  by `relative_extension_path_violation()` (no traversal, must stay inside the
  package), so plain relative `commands/<slug>.md` paths are required and
  sufficient.
- **Alternatives considered**: A flatter `speckit.<slug>` alias form — rejected;
  it's only kept for legacy community-extension compatibility and is
  auto-corrected with a validation *warning*, which would not cleanly satisfy
  "installs without validation errors."

## Decision: Hook entries are non-optional and reference commands by name

- **Decision**: Each of the 7 `before_*` events is declared as a single mapping
  `{command: "speckit.rollout.brief-<phase>", optional: false}`.
- **Rationale**: Hook entries default `optional` to `True` when the field is
  omitted (`entry.get("optional", True)` in `HookExecutor.register_hooks`), so
  `optional: false` must be explicit to get non-optional (auto-executing)
  behavior, per the vision (section 5.1) and the input's explicit requirement.
- **Alternatives considered**: Declaring hooks as single-entry lists
  (`[{command: ..., optional: false}]`) — functionally equivalent (the loader
  normalizes both shapes via `coerce_hook_entries`), but a bare mapping is
  simpler and matches the common case (one command per event, no priority
  ordering needed among competing hooks).

## Decision: `requires.speckit_version` range

- **Decision**: `">=0.12.0"`.
- **Rationale**: `requires.speckit_version` is parsed as a PEP 440
  `SpecifierSet` and checked with `specifier.contains(current_version)`
  (`packaging.specifiers`). The project's own `.specify/init-options.json`
  records the currently adopted Spec Kit line as `0.12.2`. A floor at `0.12.0`
  matches the adopted line; no upper bound is set, so the package remains
  installable against `1.x` and later releases.
- **Alternatives considered**: An exact pin (`==0.12.2`) — rejected as overly
  brittle for a "compatible range" requirement; a capped upper bound
  (e.g. `<2.0.0`) — rejected since it would block future major releases
  unnecessarily.

## Decision: `provides.config` + functional `config.defaults`

- **Decision**: Declare both (a) a descriptive `provides.config` list entry
  (`id: rollout-config`, `file: rollout-config.yml`,
  `template: rollout-config.template.yml`, `required: false`) as explicitly
  requested, and (b) a top-level `config.defaults` / `config.config_schema`
  block with placeholder values.
- **Rationale**: The installed validator only reads `provides.commands`; any
  other `provides.*` key (including `config`) is present-but-inert —
  including it cannot cause a validation error, and documents the package's
  config surface as requested. Separately, `ConfigManager._get_extension_defaults()`
  reads defaults from a **top-level** `config.defaults` map today — that's the
  only mechanism that is actually functional in the installed CLI, so it is
  included too so the config declaration is more than decorative.
- **Alternatives considered**: Only the `provides.config` entry (matching the
  literal request text most narrowly) — rejected because it would leave the
  config declaration entirely inert in the currently installed tooling, which
  under-delivers relative to the spec's intent that "provides.config"
  actually describes an eventually-resolvable configuration file.

## Decision: `.extensionignore` patterns

- **Decision**: Exclude `.git/`, `.specify/`, `specs/`, `tests/`, `docs/`, and
  `.github/` (gitignore-pattern syntax, one per line).
- **Rationale**: `_load_extensionignore()` uses `pathspec.GitIgnoreSpec`
  (standard `.gitignore` semantics) and always excludes the ignore file itself
  automatically — no need to list it. `tests/`, `docs/` (this repo's
  `docs/foundation/vision.md` source), and `.github/` (CI workflows, prompt
  files) are the development-only surfaces this repository actually has today.
  **Corrected during implementation (T020)**: an initial attempt that omitted
  `.specify/` failed with a real, reproduced error — `specify extension add .
  --dev` uses this repository root as the package source, and
  `.specify/extensions/` is exactly where the installer writes the installed
  copy, so without excluding `.specify/` the copy step recursively copied its
  own destination into itself (`shutil.copytree` self-nesting, observed as a
  `File name too long` failure after hundreds of nested `rollout/` segments).
  `specs/` (this repo's own feature specs) is excluded for the same
  reason of hygiene, though it isn't itself self-referential.
- **Alternatives considered (rejected, then falsified)**: The original plan-phase
  decision was to leave `.specify/` and `specs/` un-excluded, reasoning they
  "aren't part of the installed extension copy". That reasoning was wrong in
  practice for `.specify/` specifically, because this package's source root
  *is* the repository root that also hosts `.specify/extensions/` — the two
  are not actually separate as assumed. Verified by running the real install
  command, not just by re-reading the validator source.

## Decision: No test framework / contract tests for this feature

- **Decision**: Validation is via the real `specify` CLI commands (`extension
  add --dev`, `list`, `remove`) plus a lightweight regex/file-existence check,
  not a unit-test suite.
- **Rationale**: The feature produces no executable code — correctness is
  entirely "does this file structure satisfy the installed validator," which
  the CLI itself already checks authoritatively. Duplicating that logic in a
  bespoke test suite would be redundant per the input's own acceptance
  criteria (all phrased as CLI-observable outcomes).
- **Alternatives considered**: A Python test suite invoking
  `ExtensionManifest` directly — rejected as unnecessary indirection; the
  black-box CLI flows are both the real acceptance bar and simpler to run.
