# Feature Specification: Rollout Extension Skeleton

**Feature Branch**: `[001-extension-skeleton]`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first for the full picture; this feature builds the extension skeleton it describes. Build the foundation of the Spec Kit extension \"rollout\" (id: rollout), a LaunchDarkly-focused progressive-delivery extension. Create a valid Spec Kit extension package (extension.yml, README.md, LICENSE, CHANGELOG.md, .extensionignore), declare provides.commands for eight command files, declare hooks on seven lifecycle events, declare provides.config, create placeholder command files, and ensure the package installs and validates cleanly via the specify CLI."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Install the extension into a Spec Kit project (Priority: P1)

A maintainer of the `rollout` extension adds it to a Spec Kit-enabled project in
development mode, so it can be iterated on locally before publishing.

**Why this priority**: If the package cannot be installed and pass validation, no
other capability (commands, hooks, config) can be exercised or tested. This is
the foundational, blocking capability.

**Independent Test**: Run the extension installation command against this
package and confirm it completes with no validation errors.

**Acceptance Scenarios**:

1. **Given** a Spec Kit project with no extensions installed, **When** the
   maintainer installs the `rollout` package in development mode, **Then** the
   installation completes with zero validation errors.
2. **Given** the package's manifest, **When** the installer validates it,
   **Then** every file referenced by the manifest (commands, config templates)
   is found on disk.

---

### User Story 2 - Confirm the extension is fully and correctly registered (Priority: P2)

A maintainer lists installed extensions to confirm `rollout` is registered with
all of its commands and hooks, and is enabled.

**Why this priority**: Registration visibility is how a maintainer (or CI)
confirms the package declares the complete surface described in the vision
before any doctrine content is added in later features.

**Independent Test**: After installation, list installed extensions and
inspect the entry for `rollout` independent of any other extension behavior.

**Acceptance Scenarios**:

1. **Given** `rollout` is installed, **When** the maintainer lists installed
   extensions, **Then** `rollout` appears with a status of enabled.
2. **Given** the listing shows extension detail, **When** the maintainer
   inspects the `rollout` entry, **Then** it shows exactly 8 registered
   commands and exactly 7 registered hooks.
3. **Given** the listing shows command names, **When** the maintainer inspects
   each command name, **Then** every name matches the pattern
   `speckit.rollout.<name>` using only lowercase letters, digits, and hyphens.

---

### User Story 3 - Cleanly remove the extension (Priority: P3)

A maintainer removes the `rollout` extension from a project, leaving the
project in the same state it was in before installation.

**Why this priority**: A clean uninstall path is required for safe iteration
and for teams that decide to opt out (per the vision's "team toggle" via
uninstall), but it only matters once install and registration already work.

**Independent Test**: With `rollout` installed, run the removal command and
confirm no `rollout`-related commands, hooks, or config remain registered.

**Acceptance Scenarios**:

1. **Given** `rollout` is installed, **When** the maintainer removes it,
   **Then** the removal completes without errors.
2. **Given** removal has completed, **When** the maintainer lists installed
   extensions, **Then** `rollout` no longer appears and none of its commands
   or hooks remain registered.

---

### Edge Cases

- What happens when the manifest references a command file that does not
  exist on disk? Installation MUST fail validation rather than install a
  broken extension.
- What happens when a command name does not match the required
  `speckit.rollout.<name>` pattern (e.g., wrong prefix, uppercase letters)?
  Installation MUST fail validation.
- What happens when the declared Spec Kit compatibility range does not include
  the installed Spec Kit version? Installation MUST fail with a clear
  compatibility error rather than installing silently.
- What happens to development-only files (tests, source docs, CI config) when
  the package is installed? They MUST be excluded from the installed copy via
  `.extensionignore` so the installed footprint contains only runtime-relevant
  files.
- What happens if the same lifecycle event is declared as a hook more than
  once? Only one hook per lifecycle event is declared in this package, so this
  case does not arise from this feature's own manifest.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The package MUST include a manifest file (`extension.yml`)
  declaring schema version "1.0".
- **FR-002**: The manifest MUST declare package identity metadata: a unique id
  of `rollout`, a human-readable name, a semantic version of `1.0.0`, a short
  description, an author, a repository location, a license identifier, and a
  homepage.
- **FR-003**: The manifest MUST declare a compatibility requirement naming the
  range of Spec Kit versions the package supports.
- **FR-004**: The manifest MUST declare exactly 8 provided commands, one for
  each of: `brief-specify`, `brief-clarify`, `brief-plan`, `brief-tasks`,
  `brief-analyze`, `brief-checklist`, `brief-implement`, and `connect`, each
  named following the pattern `speckit.rollout.<name>`.
- **FR-005**: Each provided command MUST reference an existing command file
  under `commands/` and include a human-readable description of the command's
  purpose.
- **FR-006**: The package MUST provide a placeholder content file for each of
  the 8 declared commands so the package is installable and its command
  references resolve, with the understanding that real phase doctrine is
  authored in a later feature.
- **FR-007**: The manifest MUST declare exactly 7 lifecycle hooks, one for
  each of: `before_specify`, `before_clarify`, `before_plan`, `before_tasks`,
  `before_analyze`, `before_checklist`, and `before_implement`.
- **FR-008**: Each declared hook MUST run its corresponding briefing command
  (e.g., `before_specify` runs the `brief-specify` command) and MUST be marked
  non-optional (`optional: false`) so it always executes automatically at its
  lifecycle event.
- **FR-009**: The manifest MUST declare a provided configuration file entry for
  a `rollout-config.yml`, including a reference to a configuration template
  file (`rollout-config.template.yml`) and marking the configuration as not
  required (`required: false`).
- **FR-010**: The package MUST include a configuration template file
  (`rollout-config.template.yml`) with placeholder default values and a
  placeholder configuration schema, so the config declaration resolves without
  requiring real provider values.
- **FR-011**: The package MUST include a `README.md` describing the extension
  at a level appropriate for a package root file.
- **FR-012**: The package MUST include a `LICENSE` file using the MIT license
  text.
- **FR-013**: The package MUST include a `CHANGELOG.md` recording at least the
  initial `1.0.0` release.
- **FR-014**: The package MUST include a `.extensionignore` file that excludes
  development-only files (test files, source documentation, and CI
  configuration) from the installed copy of the extension.
- **FR-015**: The package MUST be installable via the Spec Kit extension
  installer in development mode with zero validation errors.
- **FR-016**: Installed-extension listings MUST show the `rollout` extension
  as enabled, with exactly 8 commands and exactly 7 hooks registered.
- **FR-017**: The package MUST be cleanly removable via the Spec Kit extension
  remover, after which none of its commands, hooks, or config remain
  registered.
- **FR-018**: Every command name declared by the manifest MUST match the
  pattern `^speckit\.rollout\.[a-z0-9-]+$`.
- **FR-019**: Every file path referenced anywhere in the manifest (commands,
  config template) MUST correspond to a file that actually exists in the
  package.

*Explicitly out of scope for this feature (per the input): authoring real
phase doctrine content, gate/detection scripts, real configuration values, and
MCP server wiring. These are placeholders only, to be filled in by later
features.*

### Key Entities

- **Extension manifest (`extension.yml`)**: The package's declaration of
  identity, Spec Kit compatibility, provided commands, provided hooks, and
  provided configuration. The single source of truth for what the package
  registers.
- **Command**: A named capability (`speckit.rollout.<name>`) backed by a
  markdown file under `commands/`; in this feature each command file is a
  placeholder rather than real doctrine.
- **Hook**: A binding between a Spec Kit lifecycle event (e.g.
  `before_specify`) and one of the package's commands, executed automatically
  and non-optionally.
- **Configuration declaration**: The manifest's reference to a
  `rollout-config.yml` file plus its template, defaults, and schema
  placeholders, describing what a team could eventually configure without
  supplying real values in this feature.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A maintainer can install the `rollout` package in development
  mode and it passes validation with zero errors on the first attempt.
- **SC-002**: Listing installed extensions shows `rollout` as enabled with
  exactly 8 commands and exactly 7 hooks, matching the vision's documented
  surface, 100% of the time.
- **SC-003**: 100% of the package's declared command names conform to the
  required naming pattern.
- **SC-004**: 100% of file paths referenced by the manifest resolve to a file
  that exists in the package.
- **SC-005**: A maintainer can remove the package and confirm none of its
  commands, hooks, or configuration remain registered, with zero leftover
  artifacts.

## Assumptions

- The Spec Kit compatibility range is expressed as an open-ended lower bound
  (`>=0.12.x`, matching the currently adopted Spec Kit release line), with no
  upper bound, since the input specifies only that the range must be
  "compatible" without naming exact bounds.
- The manifest's optional `extension.category` and `extension.effect` fields
  (used in plan.md/data-model.md) are permitted, unvalidated convention
  fields, not requirements introduced by this spec.
- "Placeholder" command files satisfy installation and validation but contain
  only a short description of the command's future purpose and an explicit
  note that doctrine content is out of scope for this feature — no gating
  logic, provider calls, or phase-specific instructions are included yet.
- The configuration schema and defaults referenced by `provides.config` are
  themselves placeholders (minimal, non-functional structures) sufficient to
  satisfy manifest validation, not a finalized configuration contract.
- `README.md`, `LICENSE`, and `CHANGELOG.md` content is introductory/boilerplate
  appropriate to a `1.0.0` initial release; expanded user-facing documentation
  is not required until later features add real behavior.
- Development-only files excluded by `.extensionignore` include, at minimum,
  any `tests/` directory, source documentation outside the package root
  (e.g. a `docs/` folder), and CI workflow configuration — none of which are
  needed by an end user's installed copy. It also excludes `.git/`,
  `.specify/`, and `specs/`: since this repository's root doubles as both the
  extension package source *and* a Spec Kit project (with its own installed
  extensions and feature specs), those directories must be excluded to avoid
  copying version-control/Spec-Kit-internal state — and, critically, to avoid
  the installer recursively copying its own destination folder
  (`.specify/extensions/rollout/`) into itself.
