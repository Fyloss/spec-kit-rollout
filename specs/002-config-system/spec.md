# Feature Specification: Rollout Configuration System

**Feature Branch**: `[002-config-system]`

**Created**: 2026-07-07

**Status**: Draft

> **Superseded acceptance criteria (Feature 013, `013-rollout-config-wizard`)**:
> this spec's flat, single-provider `mcp.*` pinned-reference schema (launch
> command, args, version, repository, token env-var name) was permanently
> removed and replaced by a modular per-provider schema with no MCP
> registration fields at all — that selection now lives in
> `local-config.yml`, populated by `speckit.rollout.config`/
> `speckit.rollout.provider` instead of the removed `speckit.rollout.connect`.
> Every acceptance scenario, functional requirement, and key entity below
> that assumed the `mcp.*` block is annotated inline as superseded; the
> historical text itself is left unchanged as a record of what this feature
> originally delivered.

**Input**: User description: "Read docs/foundation/vision.md first (sections 6.2, 7, 8, 5.3). Specify the configuration system for the rollout extension. Provide rollout-config.template.yml containing NON-SECRET pointers only (provider, LaunchDarkly project key/environments, a canonical pinned MCP server reference, token_env_var name, hooks.enabled toggle). Document the config layering (extension defaults -> rollout-config.yml -> rollout-config.local.yml (gitignored) -> SPECKIT_ROLLOUT_* env vars). Template must warn against committing secrets and clarify the agent must never read/echo the token. Config must be readable by gate scripts and briefing commands at the resolved location .specify/extensions/rollout/rollout-config.yml."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Adopt the extension with a working, secret-free config (Priority: P1)

A platform engineer installs the `rollout` extension into a project and copies
the shipped configuration template to the project's live configuration file,
without needing to write any schema from scratch or consult external docs to
know which fields are safe to commit.

**Why this priority**: Nothing else in the extension (hooks, doctrine, MCP
connection) can function without a valid, resolvable configuration file. This
is the foundational capability every later feature depends on.

**Independent Test**: Copy the shipped template to the project configuration
location, without editing any values, and confirm the result is a complete,
valid configuration containing no secret material and no unresolved
placeholders that would break parsing.

**Acceptance Scenarios**:

1. **Given** a project with the `rollout` extension installed and no existing
   configuration file, **When** the engineer copies the shipped template to
   the resolved project configuration location, **Then** the result is a
   valid configuration file containing only non-secret pointer values
   (provider identifier, LaunchDarkly project key and environment name
   placeholders, the pinned MCP server reference, and the token environment
   variable name).

   > **Superseded by Feature 013**: the template no longer contains a
   > pinned MCP server reference or token environment variable name at
   > all — those fields were removed, not merely relocated.
2. **Given** the copied configuration file, **When** any tool or doctrine
   reads it, **Then** no field contains an actual credential, token, or
   secret value anywhere in the file.
3. **Given** the shipped template, **When** an engineer opens it, **Then**
   inline comments clearly state that secrets must never be committed, that
   the token is consumed only by the provider MCP server process, and that
   the agent must never read or echo the token value.

---

### User Story 2 - Disable rollout behavior for a team that opts out (Priority: P2)

A tech lead who does not want the `rollout` doctrine active for their team
sets a single configuration toggle, and every rollout-related briefing
becomes a no-op without uninstalling the extension.

**Why this priority**: The extension's hooks are non-optional at the manifest
level (per vision.md 5.3), so a config-level kill switch is the only
supported way to opt out short of uninstalling the extension. This is a
governance-critical capability but depends on User Story 1's config existing
first.

**Independent Test**: With a resolved configuration present, set the hooks
toggle to disabled and confirm (via a stub/placeholder briefing check) that
the resolved configuration value read by any consumer is "disabled", with no
other configuration values affected.

**Acceptance Scenarios**:

1. **Given** a resolved project configuration with the hooks toggle set to
   enabled, **When** an engineer changes the toggle to disabled and saves the
   file, **Then** any subsequent read of the resolved configuration reports
   the hooks toggle as disabled.
2. **Given** the hooks toggle is disabled in the project configuration,
   **When** a local override file also exists but does not set the toggle,
   **Then** the resolved value remains disabled (the project file's explicit
   value is not silently reverted).

---

### User Story 3 - Override configuration locally without risking a commit (Priority: P3)

An individual engineer needs to point at a personal LaunchDarkly sandbox
project or a locally-running MCP server build while developing, without
changing the values every teammate uses.

**Why this priority**: This is a developer-convenience and safety capability
(prevents accidental commits of personal/experimental values) that builds on
the layering established by User Story 1, but is not required for a team's
first successful adoption.

**Independent Test**: Create a local override file with a different value for
one field, confirm the resolved configuration reflects the override for that
field while all other fields still come from the committed project
configuration, and confirm the override file is excluded from version
control by default.

**Acceptance Scenarios**:

1. **Given** a committed project configuration and a local override file
   setting a single field to a different value, **When** the configuration is
   resolved, **Then** the resolved value for that field matches the local
   override and every other field matches the committed project
   configuration.
2. **Given** a fresh clone of the repository, **When** the engineer inspects
   version control status, **Then** the local override file (if present) does
   not appear as a trackable/committable file.

---

### Edge Cases

- What happens when the resolved project configuration file is missing
  entirely (only the template exists)? The system MUST treat this as
  unconfigured and fall back to extension defaults, without erroring, so
  doctrine can still degrade gracefully (per vision.md 6.3).
- What happens when both the project configuration and an environment
  variable set the same field? The environment variable MUST win, per the
  documented layering order.
- What happens when the `provider` field names a provider other than
  `launchdarkly` (e.g., a future provider not yet implemented)? The system
  MUST treat this as a recognized-but-unimplemented value rather than a fatal
  parse error, so the pluggable key does not break existing configs when new
  providers are documented.
- What happens if someone edits the committed project configuration and
  pastes an actual token value into it by mistake? The template's inline
  warnings are the primary mitigation; this feature does not implement
  automated secret-scanning (see Out of Scope).
- What happens when the hooks toggle is set to an invalid (non-boolean)
  value? The resolved configuration MUST fall back to the safe default
  (enabled) rather than silently disabling or crashing, and this should be
  treated as a misconfiguration signal for later validation tooling.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extension MUST ship a configuration template file
  (`rollout-config.template.yml`) containing only non-secret pointer values:
  a `provider` identifier defaulting to `"launchdarkly"`, a LaunchDarkly
  project key placeholder, a list of environment name placeholders, a
  canonical pinned MCP server reference, and the name of the environment
  variable the MCP server reads for its access token.

  > **Superseded by Feature 013**: the pinned MCP server reference and
  > token env-var name clauses no longer apply — the template carries no
  > MCP registration field of any kind.
- **FR-002**: The `provider` field MUST be structured so that adding a future
  provider (e.g., Unleash, GrowthBook) requires only a new value for this
  field and adjacent provider-specific pointer fields, not a schema
  redesign.
- **FR-003**: The pinned MCP server reference MUST include, at minimum: the
  launcher command, its arguments, a version constraint, and the source
  repository URL, so the doctrine can instruct the agent to use exactly this
  server (per vision.md 6.2) without searching for alternatives.

  > **Superseded by Feature 013**: there is no pinned MCP server reference
  > in config anymore; the doctrine instead resolves the developer's own
  > already-registered server via live introspection.
- **FR-004**: The template MUST include a field naming the operating-system
  environment variable that the MCP server process reads for its access
  token (e.g., `LAUNCHDARKLY_ACCESS_TOKEN`). This field MUST hold only the
  variable's name, never a token value.

  > **Superseded by Feature 013**: no such field exists in the schema
  > anymore; the token concept was removed from this project's config
  > entirely, not merely renamed.
- **FR-005**: The template MUST include a toggle (`hooks.enabled`, boolean,
  default `true`) that, when set to `false`, disables all rollout hooks for
  the team using that configuration.
- **FR-006**: The template MUST include inline comments stating: (a) secret
  values must never be committed to this file; (b) the token is consumed
  only by the MCP server process; and (c) the agent must never read or echo
  the token value.
- **FR-007**: The configuration system MUST resolve settings by layering, in
  increasing order of precedence: (1) extension-supplied defaults, (2) the
  project configuration file, (3) a local override file, then (4) OS
  environment variables prefixed `SPECKIT_ROLLOUT_`. A value set at a
  higher-precedence layer MUST override the same field set at a
  lower-precedence layer; unset fields MUST fall through to the next layer.
- **FR-008**: The project configuration file MUST resolve at
  `.specify/extensions/rollout/rollout-config.yml`, so gate scripts and
  briefing commands have one documented, stable location to read from.
- **FR-009**: The local override file MUST be excluded from version control
  by default (gitignored) so personal or experimental values are never
  committed.
- **FR-010**: Copying the shipped template to the resolved project
  configuration location, with no further edits, MUST produce a file that
  parses successfully and contains no secret values.
- **FR-011**: When the hooks toggle resolves to `false`, every rollout
  briefing/gate consumer MUST treat this as "do nothing" (no doctrine
  injected, no provider action attempted) — the specific no-op mechanics per
  briefing are defined by each briefing's own feature, but the resolved
  toggle value itself MUST be unambiguous and independent of any other
  field.
- **FR-012**: If the resolved project configuration file is absent, the
  system MUST fall back to extension defaults rather than failing, so
  first-run and graceful-degradation behavior (vision.md 6.3) is preserved.
- **FR-013**: None of the files this feature commits to version control
  (template, documentation, example configuration) MAY contain an actual
  secret or credential value at any point.

### Key Entities

- **Configuration Template**: The version-controlled, shipped file
  (`rollout-config.template.yml`) defining the full non-secret schema with
  placeholder values and explanatory comments; the starting point for every
  project's live configuration.
- **Resolved Configuration**: The single, in-memory (or on-disk merged) view
  of configuration values after applying the layering order; this is what
  gate scripts and briefing commands actually consult.
- **Project Configuration File**: The committed, per-project configuration at
  the documented resolved location, derived from the template and edited
  with real (still non-secret) pointer values.
- **Local Override File**: An optional, gitignored, per-developer file that
  overrides individual fields of the project configuration without changing
  what the team shares.
- **Provider Descriptor**: The pluggable identification of which delivery
  provider (LaunchDarkly in V1) the configuration targets, plus that
  provider's specific pointer fields (project key, environment names).
- **MCP Server Reference**: The canonical, pinned description of how to
  launch the official provider MCP server (command, arguments, version
  constraint, repository URL) and which environment variable it reads for
  its token.

  > **Superseded by Feature 013**: this entity no longer exists in the
  > schema. The developer's own client owns MCP server registration
  > entirely; this project only stores that server's name/key (in
  > `local-config.yml`), never its launch details or a credential.
- **Hooks Toggle**: The single boolean setting controlling whether any
  rollout hook produces doctrine output for a given team/project.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new team can go from installing the extension to having a
  working, parseable, secret-free configuration file in under one minute,
  by copying one template file and setting only their own project key and
  environment names.
- **SC-002**: 100% of committed repository content for this feature (template,
  docs, examples) contains zero secret or credential values, verifiable by
  visual inspection of every field.
- **SC-003**: A team can fully disable all rollout behavior by changing
  exactly one configuration value, with no other file edits and no
  extension uninstall required.
- **SC-004**: An individual engineer can override any single configuration
  value for local development without modifying, or risking a commit to, the
  team's shared configuration file.
- **SC-005**: Given any two of the four layering sources set the same field
  to different values, the resolved value always matches the documented
  precedence order, with zero ambiguous or conflicting outcomes.

## Assumptions

- The local override file is named `local-config.yml` (not
  `rollout-config.local.yml`), matching the generic local-override naming
  already used by the underlying Spec Kit extension configuration loader,
  so this feature's file is discoverable without a mechanism change. This
  supersedes the specific filename suggested in the input.
- The extension id `rollout` fixes both the project configuration path
  (`.specify/extensions/rollout/rollout-config.yml`) and the environment
  variable prefix (`SPECKIT_ROLLOUT_`), consistent with the extension
  skeleton delivered in feature 001.
- The existing placeholder `rollout-config.template.yml` (delivered as a
  stand-in by feature 001, at the extension package root) is superseded and
  fully populated by this feature, including migrating its flat
  `hooks_enabled` placeholder key to the nested `hooks.enabled` shape
  required here.
- "LaunchDarkly project key and environment names" are represented as
  placeholder (empty/example) values in the committed template; real values
  are filled in per-project when the team copies the template, and are
  themselves non-secret (LaunchDarkly project keys and environment names are
  identifiers, not credentials).
- Validating the configuration schema (e.g., rejecting malformed YAML or
  unknown fields with a clear error) is a reasonable implementation
  necessity but is not separately re-specified here beyond FR-010/FR-012;
  detailed validation error UX is left to the planning phase.
- Reading the resolved configuration from inside each specific briefing
  command, and writing the MCP client registration, are explicitly deferred
  to other features per the stated scope boundaries below.

## Out of Scope

- Reading or consuming the resolved configuration from within each
  individual briefing command's doctrine logic (defined per briefing
  feature).
- Writing or registering the MCP server connection with any Spec Kit client
  (delivered in the `connect` setup feature).

  > **Superseded by Feature 013**: the `connect` setup feature named here
  > was permanently removed and replaced by `speckit.rollout.config`/
  > `speckit.rollout.provider`, which never write a client's MCP
  > configuration file at all (by design, not merely a rename).
- Any provider other than LaunchDarkly (future roadmap item; this feature
  only guarantees the schema is pluggable).
- Automated secret-scanning or pre-commit enforcement preventing accidental
  secret values from being committed.
