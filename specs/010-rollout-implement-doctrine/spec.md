# Feature Specification: Rollout Implement Doctrine (Pre-Implement Briefing)

**Feature Branch**: `[010-rollout-implement-doctrine]`

**Created**: 2026-07-08

**Status**: Draft

> **Superseded acceptance criteria (Feature 013, `013-rollout-config-wizard`)**:
> this spec assumed a single canonical, pinned `mcp.*` config reference
> (vision.md §6.2, pre-013) and named `speckit.rollout.connect` as the
> plan-only-mode remediation command. Feature 013 permanently removed the
> `mcp.*` pinned-reference schema and the `connect` command; the doctrine
> now resolves the developer's own already-registered MCP server via live
> introspection, and the remediation command is `speckit.rollout.config`.
> Every acceptance scenario, FR, key entity, and success criterion below
> that assumed the pin or named `connect` is annotated inline as
> superseded; the historical text is left unchanged as a record of what
> this feature originally delivered.

**Input**: User description: "Read docs/foundation/vision.md first (sections 4, 6, 8). Specify commands/brief-implement.md, run automatically by the before_implement hook, self-gated via the shared gate (Feature 3). Requirements: If no marker: one-line no-op, stop. If marker present: use the pinned LaunchDarkly MCP server from config (do NOT search for or substitute alternative servers); introspect the MCP at runtime (tools/list, resources/list, prompts/list) and bind provider-neutral intents to the real advertised tools: discover environments, discover segments, create flag, set targeting, set percentage rollout, read flag status, archive flag; execute the rollout tasks via those tools (create/configure flag, targeting, environments) as part of implementation; content lineage: actions are derived from tasks + plan; guardrails: never auto-advance production exposure unless explicitly instructed, never read/echo/inline the token. Graceful degradation: if no MCP is available, run in plan-only mode and emit a 'configure MCP / run speckit.rollout.connect' task instead of failing. Acceptance criteria: with the MCP available, the agent performs the flag/targeting/environment actions defined by the tasks; with no MCP, implementation continues in plan-only mode and records a setup task; the token never appears in agent output. Out of scope: MCP registration/setup (Feature 11)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Execute rollout provider actions via the pinned MCP during implementation (Priority: P1)

A developer runs `/speckit.implement` on a feature whose `spec.md` carries a
`## Delivery Considerations` marker (Feature 004), whose `plan.md` contains a
`## Delivery Strategy` section (Feature 006), and whose `tasks.md` contains
the rollout tasks derived from that strategy (Feature 007). The pre-implement
briefing recognizes the marker via the shared gate script, confirms rollout
tasks exist, then instructs the agent to introspect the project's configured
LaunchDarkly MCP server at runtime, bind the doctrine's provider-neutral
intents to the tools it actually advertises, and execute the rollout tasks
(create/configure the flag, configure environments, configure targeting) by
invoking those bound tools with parameters drawn from the plan and tasks.

**Why this priority**: This is the core capability the extension exists to
deliver end-to-end (vision.md §4, §6): without this briefing, `/speckit.implement`
has no awareness that provider actions should happen at all, leaving the
rollout chain as inert documentation.

**Independent Test**: With a rollout feature whose spec/plan/tasks chain is
fully populated and a working LaunchDarkly MCP server connected, run
`/speckit.implement` and confirm the agent calls MCP tools that create the
flag, configure its environments, and configure its targeting/percentage
rollout as specified in `tasks.md` and `plan.md`.

**Acceptance Scenarios**:

1. **Given** a fully populated rollout chain (marker, Delivery Strategy,
   rollout tasks) and a reachable, pinned LaunchDarkly MCP server, **When**
   `/speckit.implement` runs, **Then** the agent introspects the MCP server
   (`tools/list`, `resources/list`, `prompts/list`) before acting.

   > **Superseded by Feature 013**: "pinned" no longer applies — the MCP
   > server is the developer's own already-registered server, resolved via
   > live introspection rather than a static config reference. The
   > introspection requirement itself is unchanged.
2. **Given** the same setup, **When** the agent proceeds, **Then** it binds
   each provider-neutral intent (discover environments, discover segments,
   create flag, set targeting, set percentage rollout, read flag status,
   archive flag) to a real tool the MCP server actually advertised, rather
   than assuming a fixed tool name.
3. **Given** the same setup, **When** the agent executes the rollout tasks,
   **Then** the flag name, environments, targeting rules, and percentages it
   passes to the MCP tools match the values in `plan.md`'s Delivery Strategy
   and `tasks.md`'s rollout tasks, not values invented independently or
   re-derived directly from the spec's marker alone.

---

### User Story 2 - Guardrails prevent unattended production exposure changes and token leakage (Priority: P1)

While executing rollout provider actions, the agent never uses an MCP tool
to advance a flag's live production exposure (e.g., raising a percentage
rollout already serving production traffic, or enabling a flag in a
production environment) beyond what the current task or plan explicitly
specifies, unless the user has explicitly instructed that specific advance.
Independently, at no point during introspection or execution does the agent
read, echo, log, or otherwise surface the provider API token in any output.

**Why this priority**: These are the two non-negotiable safety properties of
provider execution (vision.md §6, §8; constitution Principle VI). A single
violation — an unintended production rollout advance or a leaked token —
would undermine the credential-security and guardrail guarantees the entire
extension depends on.

**Independent Test**: Run `/speckit.implement` on a rollout feature whose
plan specifies a partial rollout (e.g., "Phase 2: 5% production") and confirm
the agent's MCP calls never request a production percentage or environment
state beyond Phase 2 without explicit user instruction, and that no
transcript, log, or tool-call argument contains the literal token value at
any point in the run.

**Acceptance Scenarios**:

1. **Given** a plan specifying a partial production rollout phase, **When**
   the agent executes rollout tasks, **Then** it does not call any MCP tool
   that would set production exposure beyond the phase currently specified.
2. **Given** the user has not explicitly instructed a specific production
   exposure advance, **When** `/speckit.implement` completes, **Then** no
   guardrail-restricted action was taken for that advance.
3. **Given** any point in a `/speckit.implement` run on a rollout feature,
   **When** the agent's output, tool-call arguments, or logs are reviewed,
   **Then** the provider API token value never appears in any of them.

---

### User Story 3 - Non-rollout feature gets no rollout behavior (Priority: P1)

A developer runs `/speckit.implement` on a feature whose `spec.md` contains
no `## Delivery Considerations` marker. The briefing's self-gate check via
the shared gate script (Feature 003) detects the absence and implementation
proceeds exactly as it would without the `rollout` extension installed: no
MCP introspection, no provider actions, no plan-only-mode task.

**Why this priority**: Equal priority to Stories 1 and 2 — the near-zero
context-pollution guarantee for the common case (vision.md §5.1/§5.2) must
hold at the implement phase just as it does at every other phase.

**Independent Test**: Run `/speckit.implement` on a feature whose `spec.md`
has no `## Delivery Considerations` marker, and confirm the briefing emits a
single-line no-op message with no MCP introspection attempted and no rollout
task added to the implementation flow.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker,
   **When** `/speckit.implement` runs, **Then** the briefing emits a
   one-line no-op message and performs no MCP introspection or provider
   action.
2. **Given** the same non-rollout feature, **When** implementation
   completes, **Then** no "configure MCP" task or any other rollout-related
   content was added.

---

### User Story 4 - Graceful degradation when no MCP server is available (Priority: P2)

A developer runs `/speckit.implement` on a rollout feature whose marker and
rollout tasks are present, but no LaunchDarkly MCP server is configured,
reachable, or successfully introspectable at runtime. Rather than failing
the implementation run, the agent continues implementing the feature's
non-rollout work normally and adds a single task instructing the user to
configure the MCP connection (pointing at the `speckit.rollout.connect`
setup command) in place of the provider actions it cannot perform.

**Why this priority**: Ensures the workflow never hard-fails due to
provider/environment issues outside the agent's control (vision.md §6.3),
while still leaving a clear, actionable trail back to a working state.

**Independent Test**: Run `/speckit.implement` on a rollout feature with the
MCP server intentionally unreachable (or unconfigured) and confirm
implementation completes without failing overall, no provider action is
attempted, and exactly one task referencing `speckit.rollout.connect` is
recorded.

**Acceptance Scenarios**:

1. **Given** a rollout feature with rollout tasks present but no reachable
   MCP server, **When** `/speckit.implement` runs, **Then** the agent does
   not fail the overall implementation run.
2. **Given** the same setup, **When** the agent finishes evaluating the
   provider connection, **Then** it records one task directing the user to
   run `speckit.rollout.connect` (or otherwise configure the MCP) instead of
   performing any provider action.

   > **Superseded by Feature 013**: the remediation command is
   > `speckit.rollout.config`, not `speckit.rollout.connect` (removed).
3. **Given** the same setup, **When** the recorded task is reviewed, **Then**
   it contains no attempt to guess, fabricate, or partially simulate provider
   actions in place of the missing MCP.

---

### Edge Cases

- What happens when the marker is present but `tasks.md` contains none of the
  rollout task categories established by Feature 007 (e.g., `/speckit.tasks`
  was never run, or ran before the marker existed)? The briefing treats this
  the same as "nothing to execute yet": it emits a distinct status noting
  rollout tasks have not been generated (recommending `/speckit.tasks`) and
  performs no MCP introspection or provider action, never fabricating actions
  directly from the spec marker or the plan's Delivery Strategy alone.
- What happens when the MCP server is reachable but does not advertise a
  tool for one of the seven provider-neutral intents (e.g., no "archive
  flag" capability)? The agent skips only that specific action, notes it
  could not be performed, and continues with the intents it could bind,
  rather than failing the entire implementation run.
- What happens when the shared gate script itself fails to resolve the
  feature directory (diagnostic exit code)? The briefing treats this
  identically to the no-marker case: one-line no-op, no MCP introspection,
  no rollout task added.
- What happens when the user's request during `/speckit.implement` explicitly
  asks for a specific production exposure advance (e.g., "roll checkout_v2
  out to 25% in production now")? That explicit instruction is the one
  documented exception to the production-exposure guardrail — the agent may
  perform exactly that advance, and no more than what was explicitly asked.
- What happens when `plan.md`'s Delivery Strategy is present but missing a
  value the rollout tasks need (e.g., no environments listed)? The agent
  performs only the actions it has concrete values for and does not invent
  missing values, noting the gap rather than guessing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `before_implement` briefing (`commands/brief-implement.md`)
  MUST invoke the shared rollout gate script (Feature 003) in its default
  mode against `spec.md` before deciding whether to perform any
  rollout-related behavior during `/speckit.implement`.
- **FR-002**: If the gate script reports no marker present (`hasFlags=false`,
  including the diagnostic exit code), the briefing MUST emit a single-line
  no-op message and MUST NOT introspect any MCP server, execute any provider
  action, or add any plan-only-mode task.
- **FR-003**: If the gate script reports a marker present (`hasFlags=true`),
  the briefing MUST check `tasks.md` for the presence of rollout tasks (the
  task categories established by Feature 007's doctrine: create flag,
  configure environments, configure targeting, integrate SDK, add telemetry
  validation, define rollback conditions) before attempting any MCP
  introspection or provider action.
- **FR-004**: If rollout tasks are absent from `tasks.md` when the marker is
  present, the briefing MUST emit a distinct status message recommending
  `/speckit.tasks` be run, and MUST NOT attempt MCP introspection, execute
  any provider action, or fabricate actions directly from the spec marker or
  the plan's Delivery Strategy section.
- **FR-005**: When rollout tasks are present, the briefing MUST instruct the
  agent to use exactly the canonical, pinned LaunchDarkly MCP server
  reference from the resolved rollout configuration (vision.md §6.2) and
  MUST instruct the agent never to search for, substitute, or fall back to
  any alternative MCP server implementation.

  > **Superseded by Feature 013**: no pinned config reference exists
  > anymore; the agent instead uses exactly the developer's own
  > already-registered server (resolved via live introspection), still
  > never substituting an alternative.
- **FR-006**: The briefing MUST instruct the agent to introspect the
  configured MCP server at runtime via its discovery operations
  (`tools/list`, `resources/list`, `prompts/list`) before binding or invoking
  any tool, rather than relying on any hardcoded or assumed tool catalogue.
- **FR-007**: The briefing MUST define the following provider-neutral
  intents and instruct the agent to bind each to the real tool(s) the MCP
  server advertises at runtime: discover environments; discover segments;
  create flag; set targeting; set percentage rollout; read flag status;
  archive flag.
- **FR-008**: The briefing MUST instruct the agent to execute the feature's
  rollout tasks (create/configure the flag, configure environments,
  configure targeting) using the bound MCP tools, with parameters (flag
  name, environments, targeting rules, percentages) sourced from `plan.md`'s
  Delivery Strategy section (Feature 006) and `tasks.md`'s rollout tasks
  (Feature 007) — never invented independently and never re-derived directly
  from `spec.md`'s marker alone.
- **FR-009**: The briefing MUST instruct the agent never to invoke any MCP
  tool that would advance a flag's live production exposure (e.g.,
  increasing a percentage rollout already serving production traffic, or
  enabling a flag in a production environment) beyond what the current task
  or plan explicitly specifies, unless the user has explicitly instructed
  that specific advance.
- **FR-010**: The briefing MUST instruct the agent never to read, echo, log,
  or inline the provider API token under any circumstance, reiterating that
  credential handling belongs solely to the MCP server process (vision.md
  §8) and that the briefing content itself must never reference or request a
  token value.
- **FR-011**: If no MCP server is available at runtime (not configured, not
  reachable, or introspection fails), the briefing MUST instruct the agent
  to continue implementation in a plan-only mode: it MUST NOT fail or halt
  the overall implementation run, and MUST instead record a task instructing
  the user to configure the MCP connection, referencing the
  `speckit.rollout.connect` setup command, in place of the provider actions
  it cannot perform.

  > **Superseded by Feature 013**: the referenced command is
  > `speckit.rollout.config` (`speckit.rollout.connect` was removed).
- **FR-012**: The briefing MUST NOT include instructions for registering,
  installing, or configuring the MCP server connection itself (out of
  scope, reserved for Feature 011 / `connect.md`) beyond naming
  `speckit.rollout.connect` as the remediation step in the plan-only-mode
  task.

  > **Superseded by Feature 013**: `connect.md` was permanently removed;
  > the remediation step names `speckit.rollout.config` instead. The
  > underlying scope boundary (this briefing never itself performs MCP
  > registration) is unchanged.
- **FR-013**: If the MCP server is reachable but does not advertise a tool
  for one or more of the seven provider-neutral intents, the briefing MUST
  instruct the agent to skip only the affected action(s), note that they
  could not be performed, and continue with the intents it could bind,
  rather than failing the entire implementation run.
- **FR-014**: The briefing content MUST author the full body of the
  currently-empty `commands/brief-implement.md` with the full doctrine
  described by FR-001 through FR-013.

### Key Entities

- **Provider-neutral intent**: One of the seven named actions (discover
  environments, discover segments, create flag, set targeting, set
  percentage rollout, read flag status, archive flag) the doctrine defines
  in natural language and instructs the agent to bind to a real, introspected
  MCP tool at runtime.
- **Pinned MCP server reference**: The canonical, non-secret LaunchDarkly MCP
  server configuration (command, args, version, repository, token env-var
  name) resolved from the project's rollout configuration, which the agent
  must use exactly as configured.

  > **Superseded by Feature 013**: this entity no longer exists; the agent
  > instead resolves the developer's own already-registered MCP server via
  > live introspection (see `local-config.yml`'s MCP server selection).
- **Rollout task**: An entry in `tasks.md` (Feature 007) describing a
  concrete provider action to perform (create flag, configure environments,
  configure targeting, etc.), the unit of work this briefing executes.
- **Plan-only-mode task**: The single remediation task the briefing records
  when no MCP is available, directing the user to `speckit.rollout.connect`.

  > **Superseded by Feature 013**: the task now directs the user to
  > `speckit.rollout.config`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When a rollout feature's marker, Delivery Strategy, and
  rollout tasks are all present and a pinned LaunchDarkly MCP server is
  reachable, running `/speckit.implement` results in the flag/targeting/
  environment actions defined by the tasks being performed 100% of the
  time.
- **SC-002**: When no MCP server is reachable for a rollout feature,
  `/speckit.implement` completes without failing the overall run and
  records exactly one setup task referencing `speckit.rollout.connect`,
  100% of the time such runs occur.

  > **Superseded by Feature 013**: the recorded task references
  > `speckit.rollout.config`.
- **SC-003**: A review of the agent's output, tool-call arguments, and logs
  from any `/speckit.implement` run on a rollout feature contains zero
  instances of the provider API token value.
- **SC-004**: Non-rollout features see zero MCP introspection attempts and
  zero rollout-related tasks added, with no more than a single line of
  visible overhead from the briefing.

## Assumptions

- The pinned LaunchDarkly MCP server reference (command, args, version,
  repository, token env-var name) is resolvable from the project's rollout
  configuration by the time `/speckit.implement` runs; populating that
  configuration is the responsibility of the setup command (Feature 011),
  not this feature.

  > **Superseded by Feature 013**: there is no pinned reference to resolve
  > from config anymore; the developer's own MCP server selection is
  > resolved from `local-config.yml`, populated by `speckit.rollout.config`
  > (Feature 013), not the removed Feature 011 `connect` command.
- "MCP available" is determined by a runtime connection/introspection
  attempt, not by a static file or config presence check alone.
- Feature 007's six rollout task categories are the execution unit this
  briefing consumes; this feature does not redefine or regenerate them.
- The `speckit.rollout.connect` command referenced in the plan-only-mode
  task already exists as a registered command (currently a placeholder body
  per Feature 011's scope) so the reference is valid even before that
  feature's doctrine is authored.

  > **Superseded by Feature 013**: `speckit.rollout.connect` was
  > permanently removed; the plan-only-mode task now references
  > `speckit.rollout.config`, registered by Feature 013.
