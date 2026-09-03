# Feature Specification: Rollout Config Wizard (Pinned MCP Server Removal & Modular Provider Config)

**Feature Branch**: `013-rollout-config-wizard`

**Created**: 2026-08-06

**Last Updated**: 2026-08-07

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 6.2, 7, 8), rollout-config.template.yml, commands/connect.md, and docs/providers.md before writing this spec — this feature permanently removes the \"pinned MCP server\" concept (Feature 002/011: command/args/version/repository written by connect into the client's MCP config) and replaces the /speckit.rollout.connect command with a new /speckit.rollout.config command that runs a guided setup wizard. Explicitly mark the superseded acceptance criteria in specs/002-config-system, specs/010-rollout-implement-doctrine, and specs/011-rollout-connect-setup. Core principle: the developer registers their own LaunchDarkly MCP server, of their own choosing, in their own client's native MCP settings, before running config — rollout never writes, creates, or modifies any client's MCP configuration file, and no longer stores or requires command/args/version/repository anywhere. /speckit.rollout.config is a re-runnable, interactive setup wizard with six steps: provider selection, MCP detection and selection, project selection, environment selection, read verification, and final confirmation."

**Revision 2 Input** (2026-08-07): Provider configuration becomes modular/pluggable instead of a
single flat `launchdarkly.*` block always assumed — `rollout-config.yml` holds `provider:
<active provider>` plus one top-level block per provider ever configured, keyed by provider name,
so a project can retain more than one provider's saved config even though only one is active. A
new command, `/speckit.rollout.provider <provider_name>`, lets the developer switch the active
provider: reuse a saved block if one exists, or trigger that provider's config preset (the same
guided flow step 1 of `/speckit.rollout.config` would trigger for a first-time selection) if none
exists yet. The LaunchDarkly preset gains a new step, immediately after MCP server selection, that
automatically (never asked of the developer) determines whether the selected server is
LaunchDarkly's hosted MCP server or a local MCP server, by attempting a read-only project-listing
call — success means hosted, failure or tool-not-available means local — re-verified on every
wizard run rather than cached. The hosted branch is unchanged (introspect projects/environments).
The new local branch asks the developer to either type the project ID and environment key(s)
directly, or explicitly opt out and configure `rollout-config.yml` by hand later — in which case no
placeholder values are fabricated and read verification is skipped with a clear note rather than
silently treated as passed. Both branches converge on read verification and final confirmation,
except the local opt-out sub-case, which skips straight to a final summary stating that
project/environment/read-verification are not yet configured. `commands/brief-implement.md`,
`docs/foundation/vision.md`, `docs/providers.md`, `docs/usage.md`, and `README.md` must be updated
(captured here as functional requirements, to be executed during this feature's own plan/implement
phases) to describe the modular config shape, the new command, and the hosted/local branching,
replacing any description that assumes a single always-hosted-style introspection flow. Out of
scope (unchanged): installing/configuring an MCP server on the developer's behalf, implementing any
provider preset other than LaunchDarkly, and managing credentials.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-time guided configuration succeeds end to end (Priority: P1)

A developer has already registered the official LaunchDarkly **hosted** MCP
server in their own client's native MCP settings (e.g., `.vscode/mcp.json`).
They run `/speckit.rollout.config` for the first time. The wizard walks them
through provider selection, detects their single registered LaunchDarkly-
capable MCP server, automatically determines (without asking) that it is the
hosted server, has them pick a LaunchDarkly project and one or more
environments, confirms read access by listing existing flags, and reports a
final summary confirming the configuration is saved and ready.

**Why this priority**: This is the entire replacement for the old `connect`
setup flow and the only path by which a project becomes usable by the rest of
the rollout doctrine (`brief-plan`, `brief-tasks`, `brief-implement`). Without
this working end to end, no other rollout capability is reachable.

**Independent Test**: Can be fully tested by running `/speckit.rollout.config`
against a project with exactly one registered LaunchDarkly hosted MCP server
and verifying that `rollout-config.yml` (and/or `local-config.yml`) ends up
with a valid `provider`, a `launchdarkly.project_key`, `launchdarkly.
environments`, and MCP server selection — and that no client MCP
configuration file is touched.

**Acceptance Scenarios**:

1. **Given** a project with no prior rollout configuration and exactly one
   LaunchDarkly-capable MCP server registered in the client's own MCP
   settings, **When** the developer runs `/speckit.rollout.config`, **Then**
   the wizard completes all seven steps in order (provider, MCP detection,
   automatic server-type detection, project, environment(s), read
   verification, final confirmation), asks for explicit input at every
   selection point except server-type detection, and ends with a saved
   configuration and a summary confirming provider, MCP server, hosted/local
   determination, project, environments, and read-access verification status.
2. **Given** the wizard is running, **When** it inspects the client's MCP
   context, project list, and environment list, **Then** it never reads,
   requests, stores, or displays a credential/token value at any step.
3. **Given** the wizard completes successfully, **When** the developer
   inspects the client's MCP configuration file(s), **Then** no file was
   created, modified, or written by the wizard.
4. **Given** the selected MCP server is LaunchDarkly's hosted server,
   **When** step 3 (server-type detection) runs, **Then** the wizard never
   asks the developer whether the server is hosted or local — it determines
   this itself via a read-only project-listing call and proceeds directly to
   the hosted branch of project selection.

---

### User Story 2 - No LaunchDarkly-capable MCP server detected (Priority: P1)

A developer runs `/speckit.rollout.config` before registering any LaunchDarkly
MCP server in their client. The wizard's detection step finds zero candidates
and must stop safely rather than saving a broken or partial configuration.

**Why this priority**: This is the most common first-run failure mode now
that `rollout` no longer installs or registers anything on the developer's
behalf. Getting this wrong (e.g., saving a partial config, or crashing)
directly blocks first-time adoption.

**Independent Test**: Can be fully tested by running `/speckit.rollout.config`
in a project/client with no LaunchDarkly-capable MCP server registered, and
verifying the wizard stops after step 2 with a clear instruction and writes no
configuration change of any kind.

**Acceptance Scenarios**:

1. **Given** no MCP server in the agent's current context appears
   LaunchDarkly-capable, **When** the detection step runs, **Then** the
   wizard explains that none was detected, instructs the developer to add the
   official LaunchDarkly MCP server themselves in their client's MCP
   settings, and stops immediately.
2. **Given** the wizard stopped at step 2 for zero detected servers,
   **When** the developer inspects `rollout-config.yml` and
   `local-config.yml`, **Then** neither file contains any newly saved value
   from this run (no partial save of provider, project, or environment
   selections made in steps 1, 4, or 5 of that same run).

---

### User Story 3 - Multiple candidate MCP servers require disambiguation (Priority: P2)

A developer has more than one MCP server registered that appears
LaunchDarkly-capable (e.g., a production and a sandbox server, or two
differently named entries). The wizard must ask which one to use rather than
guessing.

**Why this priority**: Guessing wrong silently binds the project to the wrong
LaunchDarkly account/environment set, which is a correctness and possibly a
security concern (wrong-environment flag reads/writes later). This is common
enough (multiple LD server entries) to need explicit, deterministic handling.

**Independent Test**: Can be fully tested by registering two or more
LaunchDarkly-capable MCP servers in a client and confirming the wizard lists
all candidates and proceeds only after the developer picks one.

**Acceptance Scenarios**:

1. **Given** two or more MCP servers in the agent's context appear
   LaunchDarkly-capable, **When** the detection step runs, **Then** the
   wizard lists all candidates and asks the developer to pick exactly one
   before continuing to step 3 (automatic server-type detection) and then
   project selection.
2. **Given** the developer has picked one of several candidates, **When**
   the configuration is saved, **Then** only that server's name/key is
   persisted — never a command, arguments, version, repository, or
   credential for any candidate.

---

### User Story 4 - Read verification fails after project/environment selection (Priority: P2)

After the developer selects a project and one or more environments (via
either the hosted or the local branch), the wizard attempts a read-only flag
listing call to confirm access actually works. That call fails (e.g.,
permissions error, network error, or the project/environment turns out to be
invalid).

**Why this priority**: Confirming that the project/environment selections are
not just syntactically valid but actually usable is the wizard's core value
over a dumb form; the failure path must give the developer an explicit, safe
choice rather than silently saving a configuration that will fail later
during `brief-plan`/`brief-implement`. This scenario applies only once a
project and environment(s) are actually known — the local branch's opt-out
sub-case skips this step entirely (see User Story 7).

**Independent Test**: Can be fully tested by selecting a project/environment
combination that the connected MCP server cannot read flags for, and
confirming the wizard presents exactly the cancel-or-continue choice, honors
whichever the developer picks, and never silently proceeds without asking.

**Acceptance Scenarios**:

1. **Given** the read-only flag-listing call fails or returns an error for
   the selected project and environments, **When** the wizard reaches step 6
   (read verification), **Then** it explains the error clearly and offers
   exactly two choices: cancel the whole run (discarding any not-yet-saved
   selections) or continue anyway and save what was gathered so far with a
   clear warning that read access could not be confirmed.
2. **Given** the developer chooses to cancel after a read failure, **When**
   the wizard exits, **Then** no configuration from that run (provider, MCP
   server, project, or environments) is saved.
3. **Given** the developer chooses to continue after a read failure,
   **When** the wizard reaches step 7 (final confirmation), **Then** the
   final summary explicitly states that read access could not be verified.

---

### User Story 5 - Re-running the wizard to change a prior selection (Priority: P2)

A developer who already has a working configuration wants to switch to a
different LaunchDarkly project, add another environment, or point at a
different registered MCP server (e.g., after registering a new one). They run
`/speckit.rollout.config` again.

**Why this priority**: Configuration needs change over a project's lifetime
(new environments, project reorganization, switching MCP servers); without a
re-runnable wizard, developers would have to hand-edit config files with no
guided validation, reintroducing the error-prone experience the wizard
exists to prevent.

**Independent Test**: Can be fully tested by running `/speckit.rollout.config`
a second time against a project with existing saved configuration, changing
at least one selection (e.g., environments), and confirming the new
selections are saved while unrelated existing settings remain intact.

**Acceptance Scenarios**:

1. **Given** a project with a previously saved rollout configuration,
   **When** the developer runs `/speckit.rollout.config` again, **Then** the
   wizard runs all seven steps again (including the automatic server-type
   detection step) and allows changing any previous selection (provider, MCP
   server, project, or environments).
2. **Given** the developer changes only the environment selection on a
   re-run, **When** the run completes successfully, **Then** the saved
   `launchdarkly.environments` reflects the new choice while `provider` and
   `launchdarkly.project_key` remain whatever was newly confirmed in that
   same run (the wizard does not silently carry forward stale values without
   presenting them for confirmation).

---

### User Story 6 - Provider selection and switching communicates future multi-provider intent (Priority: P3)

A developer running the wizard for the first time sees a provider selection
step. Only "LaunchDarkly" is usable in V1, but the UI already signals that
other providers are planned. Separately, a developer who has already
configured one or more providers can switch which one is active at any time
without re-running the whole guided wizard, using a dedicated command.

**Why this priority**: Lower priority because it does not block any
functional path in V1 (LaunchDarkly is the only real choice), but it sets
correct expectations, avoids confusing "why is this the only option" support
questions, and gives multi-provider projects a lightweight way to change the
active provider without discarding a previously configured one.

**Independent Test**: Can be fully tested two ways: (a) running the wizard's
first step and confirming LaunchDarkly is selectable while any other listed
provider name is visibly disabled/greyed with a "coming soon" label; and (b)
running `/speckit.rollout.provider <provider_name>` and confirming it reuses
an existing saved config block for a previously configured provider with no
re-prompting, or triggers that provider's config preset for a provider with
no saved block yet.

**Acceptance Scenarios**:

1. **Given** the wizard's step 1 provider list, **When** it is displayed,
   **Then** "LaunchDarkly" is selectable and any other provider name shown is
   visibly disabled with a "coming soon" label and cannot be selected.
2. **Given** the developer selects "LaunchDarkly", **When** step 1 completes,
   **Then** `provider: launchdarkly` is saved to `rollout-config.yml`,
   unchanged from the existing field name and location.
3. **Given** a project with a previously saved `launchdarkly:` config block,
   **When** the developer runs `/speckit.rollout.provider launchdarkly`,
   **Then** the command sets `provider: launchdarkly` as active and reuses
   the existing `launchdarkly:` block as-is — a plain switch, with no
   guided wizard steps re-run.
4. **Given** a project with no saved config block for a given provider name,
   **When** the developer runs `/speckit.rollout.provider <that_provider>`,
   **Then** the command triggers that provider's config preset (the same
   guided flow step 1 of `/speckit.rollout.config` would trigger for a
   first-time selection of that provider), and only sets that provider
   active once its preset completes (or leaves the prior provider active if
   the preset run is cancelled).

---

### User Story 7 - Local MCP server: manual project/environment entry or explicit opt-out (Priority: P2)

A developer has registered a **local** LaunchDarkly MCP server (one that
exposes no tool to list projects or environments, e.g., an npx-based or
self-hosted server tied to a single API key) rather than the hosted server.
After the wizard automatically determines the selected server is local, it
cannot introspect projects or environments the way the hosted branch does, so
it must ask the developer directly for that information — or let them
explicitly defer it.

**Why this priority**: Without this branch, developers using a local MCP
server would have no path through the wizard at all once server-type
detection lands on "local", since the hosted branch's introspection calls are
unavailable to them. This is common enough (federal/EU environments, or any
self-hosted server) to require explicit, non-blocking handling.

**Independent Test**: Can be fully tested by registering a local LaunchDarkly
MCP server, running `/speckit.rollout.config`, confirming the wizard reaches
the local branch after step 3, and then testing both the manual-entry path
(typed project ID + environment keys are saved correctly) and the opt-out
path (no fields are fabricated, and step 6 is skipped with a clear note
rather than silently passed).

**Acceptance Scenarios**:

1. **Given** step 3 determines the selected MCP server is local, **When**
   the wizard reaches project/environment selection, **Then** it asks the
   developer to either type the project ID and one or more environment keys
   directly, or explicitly opt out and configure `rollout-config.yml`
   themselves afterward.
2. **Given** the developer types a project ID and one or more environment
   keys, **When** the wizard saves the configuration, **Then**
   `launchdarkly.project_key` and `launchdarkly.environments` are saved
   exactly as typed, and the wizard proceeds to step 6 (read verification)
   using those values.
3. **Given** the developer explicitly opts out of entering project/
   environment values, **When** the wizard proceeds, **Then** it does NOT
   save any placeholder or fabricated value for `launchdarkly.project_key` or
   `launchdarkly.environments`, skips step 6 entirely, and step 7's summary
   clearly states that project, environment, and read verification are not
   yet configured and must be completed manually or via a future wizard
   re-run — never silently treated as passed.

---

### Edge Cases

- What happens when the developer cancels the wizard voluntarily partway
  through (e.g., at step 4 or step 5) without an error occurring? No
  configuration changes from that run are saved (same no-partial-save rule as
  the zero-detection and read-failure-cancel paths).
- What happens when the selected LaunchDarkly project has zero environments?
  In the hosted branch, the wizard reports this and cannot proceed past step
  5 until at least one environment exists in the project, since
  `launchdarkly.environments` requires one or more values; in the local
  branch the developer is trusted to type valid environment keys, so this
  case does not apply the same way.
- What happens if the hosted-vs-local detection call itself errors
  ambiguously — neither clearly succeeding nor clearly indicating "tool not
  found" (e.g., a timeout, or an error whose type cannot be distinguished)?
  The wizard MUST treat this the same as a clear local determination and let
  the local branch's manual-entry-or-opt-out path handle it, rather than
  blocking the wizard on an ambiguous signal.
- What happens if a previously saved MCP server selection now points at a
  different server type than it did on a prior wizard run (e.g., the
  developer reconfigured their client to swap a hosted registration for a
  local one under the same name, or vice versa)? Because server-type
  detection is re-verified fresh on every run rather than cached, the wizard
  follows whatever the current run's detection call determines — no stale
  hosted/local assumption carries over from a prior run.
- What happens when the agent's MCP context cannot be introspected at all
  (e.g., the client does not expose any MCP tool/resource listing to the
  agent)? This is treated the same as zero detected servers in step 2 —
  explain and stop, no partial save.
- What happens when a previously selected MCP server, project, or
  environment no longer exists on re-run (e.g., project renamed/deleted,
  server unregistered)? The wizard re-runs detection/introspection fresh each
  time rather than trusting the previously saved values, so a stale
  selection surfaces as "not found" during the relevant step rather than
  being silently reused.
- What happens if the developer runs `/speckit.rollout.config` and then, in
  the same session, the previously selected MCP server is unregistered before
  `brief-implement` runs? Out of scope for this wizard itself; covered by the
  fresh-detection fallback in the doctrine that consumes this config (see
  FR-020).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a new `/speckit.rollout.config` command
  that replaces `/speckit.rollout.connect`; the `connect` command and its
  "write the client's MCP configuration file" behavior are permanently
  removed, not deprecated-alongside.
- **FR-002**: `/speckit.rollout.config` MUST NOT, at any step, write, create,
  or modify any client's MCP configuration file (e.g., `.vscode/mcp.json`,
  `.mcp.json`, `.cursor/mcp.json`, `.codex/config.toml`, `.gemini/settings.json`,
  or any other client-native MCP settings location).
- **FR-003**: Step 1 (provider selection) MUST present "LaunchDarkly" as the
  only selectable provider in V1 and MUST display any other provider name as
  visibly disabled with a "coming soon" label; selecting LaunchDarkly MUST
  save `provider: launchdarkly` to `rollout-config.yml`'s `provider` field,
  unchanged in name and location from the current schema, and MUST save the
  LaunchDarkly-specific values gathered by the rest of the preset into the
  modular `launchdarkly:` block described in FR-026 (superseding any prior
  assumption that `launchdarkly:` is the only provider block the file can
  ever hold).
- **FR-004**: Step 2 (MCP detection and selection) MUST inspect the agent's
  current MCP context for servers that appear LaunchDarkly-capable, using
  introspection-based heuristics (server name/key, advertised tool
  namespace, or similar signals) — never a hardcoded or pinned server
  reference.
- **FR-005**: If step 2 detects zero candidate servers, the wizard MUST
  explain that none was detected, instruct the developer to add the official
  LaunchDarkly MCP server themselves in their client's MCP settings, and stop
  the wizard immediately with no configuration saved from that run.
- **FR-006**: If step 2 detects exactly one candidate server, the wizard
  MUST report it and proceed automatically to step 3 without requiring an
  extra confirmation prompt.
- **FR-007**: If step 2 detects more than one candidate server, the wizard
  MUST ask the developer to pick exactly one before proceeding, and MUST
  persist only that server's name/key — never a command, arguments, version,
  repository, or credential value, for the chosen server or any other
  candidate.
- **FR-008**: Immediately after step 2 completes, step 3 (server-type
  detection) MUST automatically determine whether the selected MCP server is
  LaunchDarkly's hosted MCP server or a local MCP server, by attempting a
  read-only call to whichever introspected tool lists the developer's
  LaunchDarkly projects. A clear success MUST be treated as hosted; a clear
  failure, or the absence of any such tool in the server's advertised tool
  list, MUST be treated as local; an ambiguous outcome (neither a clear
  success nor a clear "tool not found/not available" signal, e.g., a timeout
  or an unclassifiable error) MUST also be treated as local rather than
  blocking the wizard. This determination MUST NEVER be asked of the
  developer directly, and MUST be re-run fresh on every wizard run rather
  than cached or reused from a prior run's result, since the same saved MCP
  server name/key could point at a different server type after a client-side
  reconfiguration.
- **FR-009**: (Hosted branch) Step 4 (project selection) MUST use the
  selected MCP server to perform a read-only introspection call listing the
  developer's available LaunchDarkly projects, ask the developer to pick one,
  and save the chosen project's key as `launchdarkly.project_key`.
- **FR-010**: (Hosted branch) Step 5 (environment selection) MUST introspect
  the environments that exist within the project chosen in step 4, ask the
  developer to pick one or more, and save the chosen environment keys as
  `launchdarkly.environments`.
- **FR-011**: (Local branch) Since a local MCP server exposes no tool to list
  projects or environments, steps 4 and 5 MUST instead present the developer
  with exactly one combined choice: (a) type the project ID and one or more
  environment keys directly, saved the same way as the hosted branch
  (`launchdarkly.project_key` / `launchdarkly.environments`); or (b)
  explicitly opt out of entering them now, stating they will edit
  `rollout-config.yml` themselves afterward.
- **FR-012**: (Local branch opt-out) If the developer chooses option (b) in
  FR-011, the wizard MUST proceed without setting `launchdarkly.project_key`
  or `launchdarkly.environments`, and MUST NOT fabricate placeholder values
  for either field. Step 6 (read verification) MUST be skipped for this run,
  with a clear, explicit note in the eventual summary that it could not run
  because project/environment are not yet known — never silently treated as
  passed or skipped without explanation.
- **FR-013**: Step 6 (read verification) MUST perform a read-only call that
  lists existing flags for the selected project and environments, to confirm
  read access works end to end (not merely that steps 4-5 returned
  selectable or typed values). This step runs identically for both the
  hosted and local (manual-entry) branches once project/environment are
  known; it is skipped only in the local opt-out sub-case (FR-012).
- **FR-014**: If the step 6 read call fails or returns an error, the wizard
  MUST explain the error clearly and offer exactly two choices: (a) cancel
  the whole run, discarding any not-yet-saved selections, or (b) continue
  anyway and save the configuration gathered so far with a clear warning that
  read access could not be confirmed. The wizard MUST NOT silently swallow
  the error or proceed without presenting this choice.
- **FR-015**: Step 7 (final confirmation) MUST report a summary covering
  provider, MCP server used, hosted/local determination, project,
  environments, and whether read access was verified, and MUST confirm the
  configuration is saved and ready. In the local opt-out sub-case (FR-012),
  step 7's summary instead states that project, environment, and read
  verification are not yet configured and must be completed manually or via
  a future wizard re-run.
- **FR-016**: `/speckit.rollout.config` MUST be re-runnable, and re-running it
  MUST allow changing any previous selection made in a prior run (provider,
  MCP server, project, or environments), and MUST re-run server-type
  detection (FR-008) fresh rather than reusing a prior run's hosted/local
  result.
- **FR-017**: The `command`, `args`, `version`, `repository`, and
  `token_env_var` fields MUST be permanently removed from
  `rollout-config.template.yml`, from
  `specs/002-config-system/contracts/rollout-config-schema.md`, from
  `extension.yml`'s `config_schema`, and from every other place they are
  documented or declared — they MUST NOT be reintroduced in any form by this
  feature.
- **FR-018**: The resolved configuration schema MUST add a new field
  recording the MCP server selected in step 2 (name/key only). This field
  MUST live in the local, per-developer configuration layer
  (`.specify/extensions/rollout/local-config.yml`) by default, since it
  reflects what is registered in one specific developer's own client rather
  than a team-shared value; this decision and its rationale MUST be
  documented in the schema contract and the four-layer precedence
  documentation.
- **FR-019**: `token_env_var` MUST be permanently removed alongside
  `mcp.command`/`args`/`version`/`repository` (FR-017), never reintroduced
  in any form. Credential handling (obtaining, storing, and supplying the
  LaunchDarkly API token to the MCP server process) becomes entirely the
  responsibility of the developer's own already-registered MCP client/
  server, outside this project's config surface; this feature MUST continue
  to never request, read, store, echo, or forward a token value at any step
  (FR-023).
- **FR-020**: Doctrine that previously referenced "the pin" (notably
  `commands/brief-implement.md`'s introspection section) MUST be updated to
  resolve the MCP server via the config value saved by this wizard, or, if
  config was never run, by performing the same detection heuristics from
  step 2 fresh at runtime — never by referencing a canonical/pinned server
  spec. This update MUST also account for configurations saved via the local
  branch (FR-011/FR-012), including the opt-out sub-case where
  `launchdarkly.project_key`/`launchdarkly.environments` are entirely absent
  — in that case, the consuming doctrine MUST degrade to plan-only mode
  exactly as it already does today for "no MCP available", rather than
  fabricating or guessing project/environment values.
- **FR-021**: Every remaining repository reference to a "pinned" or
  "canonical" MCP server, to `connect` writing/registering a client's MCP
  configuration file, to a single always-hosted-style project/environment
  introspection flow, or to a flat `launchdarkly:`-only config assumption,
  MUST be updated to reflect this feature (including the modular per-provider
  config shape of FR-026, the `/speckit.rollout.provider` command of FR-025,
  and the hosted/local branching of FR-008 through FR-012) or explicitly
  marked as superseded by it. This includes, at minimum: `docs/foundation/vision.md`
  (§6.2, §7, §8), `docs/providers.md`, `docs/usage.md`, `README.md`,
  `rollout-config.template.yml`, `extension.yml`, `commands/brief-implement.md`,
  and the acceptance criteria in `specs/002-config-system/spec.md`,
  `specs/010-rollout-implement-doctrine/spec.md`, and
  `specs/011-rollout-connect-setup/spec.md`. These file edits are executed
  during this feature's own plan/implement phases, not ahead of them.
- **FR-022**: `extension.yml`'s command registration for
  `speckit.rollout.connect` MUST be renamed to `speckit.rollout.config` (new
  file `commands/config.md` replacing `commands/connect.md`), with its
  description updated to describe the seven-step guided wizard rather than
  MCP-config-file writing, and a new command registration MUST be added for
  `speckit.rollout.provider` (FR-025).
- **FR-023**: The wizard MUST NOT request, read, store, echo, or forward a
  credential/token value at any of its steps; only non-secret pointers
  (provider id, MCP server name/key, project key, environment keys) are ever
  saved.
- **FR-024**: Installing or configuring an MCP server on the developer's
  behalf, supporting any provider other than LaunchDarkly beyond the visible
  "coming soon" placeholder, and managing credentials remain out of scope for
  this feature and MUST NOT be implemented as part of it.
- **FR-025**: The system MUST provide a new `/speckit.rollout.provider
  <provider_name>` command that switches the active provider. If a saved
  config block already exists for `<provider_name>` (per FR-026), the
  command MUST set `provider: <provider_name>` and reuse that block as-is —
  a plain switch with no guided wizard steps re-run. If no saved config block
  exists yet for `<provider_name>`, the command MUST trigger that provider's
  config preset (the same guided flow step 1 of `/speckit.rollout.config`
  would trigger for a first-time selection of that provider) and only set
  `provider: <provider_name>` once that preset run completes; if the preset
  run is cancelled, the previously active provider MUST remain active. This
  command's doctrine MUST be written generically enough that adding a second
  real provider preset later requires only adding that preset — not changing
  `/speckit.rollout.provider`'s control flow. In V1, only `launchdarkly` is a
  real, implemented preset.
- **FR-026**: `rollout-config.yml`'s schema MUST be modular per provider: a
  `provider` field naming the currently active provider (unchanged field
  name/location), plus one top-level block per provider that has ever been
  configured in that project, keyed by provider name (e.g. `launchdarkly:
  <launchdarkly-specific fields>`), so a project MAY hold more than one
  provider's saved config at once even though only one is active at a time.
  This supersedes any prior assumption (including the original wording of
  FR-003 and the Key Entities section) that `launchdarkly:` is the only
  provider block the schema can ever contain; `rollout-config.template.yml`,
  `extension.yml`'s `config_schema`, and the schema contract in
  `specs/002-config-system/contracts/rollout-config-schema.md` MUST reflect
  this modular shape.

### Key Entities

- **Rollout Config Wizard Run**: One execution of `/speckit.rollout.config`,
  moving through seven ordered steps (provider, MCP detection/selection,
  automatic server-type detection, project, environment(s), read
  verification, final confirmation); may end in a completed-and-saved state
  (hosted branch, or local branch with manual entry), a completed-with-gaps
  state (local branch opt-out, skipping read verification), a
  safely-stopped state (zero servers detected), or a cancelled state (read
  failure choice or voluntary cancellation) with no partial save in the
  stopped/cancelled cases.
- **MCP Server Selection**: The developer's chosen LaunchDarkly-capable MCP
  server, identified by name/key only; never accompanied by a command,
  arguments, version, repository, or credential value.
- **MCP Server Type Determination**: The automatic, non-interactive outcome
  of step 3 — hosted or local — derived from a read-only project-listing
  call against the selected MCP server. Never cached across wizard runs;
  re-verified fresh every time the wizard runs, since the same saved server
  name/key can point at a different server type after a client-side
  reconfiguration.
- **LaunchDarkly Project Selection**: The chosen project's key, saved as
  `launchdarkly.project_key` — via hosted-branch introspection (FR-009) or
  local-branch manual entry (FR-011); absent entirely in the local-branch
  opt-out sub-case (FR-012).
- **LaunchDarkly Environment Selection**: One or more chosen environment
  keys within the selected project, saved as `launchdarkly.environments` —
  via hosted-branch introspection (FR-010) or local-branch manual entry
  (FR-011); absent entirely in the local-branch opt-out sub-case (FR-012).
- **Read Verification Result**: The outcome of the step 6 flag-listing call
  — verified, failed-and-cancelled, failed-and-continued-with-warning, or
  not-attempted (local-branch opt-out, FR-012) — reflected in the step 7
  summary and, when relevant, in the saved configuration's warning state.
- **Provider Config Block**: A top-level, provider-keyed block in
  `rollout-config.yml` (e.g., `launchdarkly:`) holding that provider's
  non-secret pointer fields. A project MAY hold more than one such block at
  once (one per provider ever configured), even though only one provider is
  active at a time (FR-026). This entity supersedes the original
  single-flat-`launchdarkly:`-block assumption implied by this spec's
  original FR-003 wording.
- **Provider Switch (`/speckit.rollout.provider`)**: One execution of the
  provider-switch command for a given `<provider_name>`; resolves to either
  a plain switch (reusing an existing saved Provider Config Block) or a
  triggered config preset run (when no saved block exists yet for that
  provider) (FR-025).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer who has already registered a LaunchDarkly MCP
  server in their client can complete all seven wizard steps — via either
  the hosted or the local (manual-entry) branch — and reach a saved,
  verified configuration in a single guided run, without editing any YAML
  file by hand.
- **SC-002**: 100% of configurations produced by this wizard contain zero
  `command`, `args`, `version`, `repository`, or `token_env_var` fields
  anywhere in `rollout-config.yml` or `local-config.yml`.
- **SC-003**: Every wizard error path (zero servers detected, read
  verification failure, voluntary cancellation) results in zero partially
  saved configuration values — the saved configuration is always either
  fully absent (from that run) or fully confirmed by the developer.
- **SC-004**: Re-running the wizard successfully changes at least one
  previously saved selection (MCP server, project, or environments) in
  100% of re-run scenarios, without requiring manual file edits.
- **SC-005**: Across all supported clients, zero client-native MCP
  configuration files are ever created or modified by this feature.
- **SC-006**: Every acceptance criterion in specs/002-config-system,
  specs/010-rollout-implement-doctrine, and specs/011-rollout-connect-setup
  that referenced a pinned/canonical MCP server or connect's write behavior
  is either updated to reference this wizard or explicitly marked as
  superseded — zero such references remain unmarked after this feature ships.
- **SC-007**: 100% of local-branch wizard runs where the developer opts out
  of entering project/environment values end with zero fabricated or
  placeholder values saved for `launchdarkly.project_key` or
  `launchdarkly.environments`, and a final summary that explicitly states
  these fields (and read verification) are not yet configured — never
  silently presented as if they had been.
- **SC-008**: Switching the active provider via `/speckit.rollout.provider
  <provider_name>` reuses an existing saved config block with zero
  re-prompting in 100% of cases where that provider was previously
  configured, and triggers that provider's config preset in 100% of cases
  where no saved block exists yet for it.

## Assumptions

- The developer is responsible for registering the official LaunchDarkly MCP
  server in their own client's native MCP settings before running
  `/speckit.rollout.config`; this feature never installs, writes, or
  registers an MCP server on the developer's behalf (unchanged principle
  from the removed `connect` command's non-action guarantees, now extended
  to cover the server registration step itself).
- "LaunchDarkly-capable" detection in step 2 is heuristic (server name/key,
  advertised tool namespace, or similar introspection signals) rather than a
  hardcoded identifier, consistent with the MCP-introspection model already
  used elsewhere in this project (vision.md §6.1).
- Hosted-vs-local server-type detection (step 3) is likewise
  introspection-based (attempting a read-only project-listing call and
  interpreting success/failure/tool-absence) rather than a hardcoded rule
  keyed on server name — consistent with the same MCP-introspection model,
  and re-verified every run rather than cached, since the underlying server
  behind a saved name/key can change between runs.
- The MCP server selection field introduced by this feature belongs in the
  local, per-developer configuration layer (`local-config.yml`) by default,
  since it reflects one developer's own client registration rather than a
  team-shared value; a project could still choose to promote it to the
  shared `rollout-config.yml` layer later if a team standardizes on one
  server, but that is not this feature's default behavior.
- Credential handling (obtaining, storing, and supplying the LaunchDarkly API
  token to the MCP server process) becomes entirely the developer's and the
  MCP server's own responsibility, now fully outside this project's config
  surface; this feature removes the now-obsolete `mcp.command`/`args`/
  `version`/`repository`/`token_env_var` fields entirely rather than
  carrying any of them forward.
- Renaming `speckit.rollout.connect` to `speckit.rollout.config` is a
  breaking rename, not an alias — no backward-compatible `connect` command
  is retained after this feature ships.
- The seven wizard steps run in the fixed order specified (provider → MCP
  detection/selection → automatic server-type detection → project →
  environment(s) → read verification → final confirmation); no step is
  skipped except where explicitly defined (e.g., step 2 skips the pick-one
  prompt when exactly one candidate is found; step 6 is skipped in the
  local-branch opt-out sub-case).
- The modular per-provider config shape (FR-026) is additive: existing
  single-provider projects with only a `launchdarkly:` block remain valid,
  since "one block per configured provider" degrades to exactly one block
  when only one provider has ever been configured. No migration step is
  required for existing V1 projects.
- In V1, `/speckit.rollout.provider` has exactly one real, implemented
  preset destination (`launchdarkly`); any other `<provider_name>` argument
  is handled the same way step 1's "coming soon" providers are (rejected as
  not yet available), not silently accepted.
