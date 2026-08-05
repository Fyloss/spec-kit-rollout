# Feature Specification: Rollout Gate Mechanism

**Feature Branch**: `[003-rollout-gate-mechanism]`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 5.1, 5.2). Specify the self-gating state mechanism shared by all rollout hooks. Requirements: Define the marker convention: a clearly labeled, human-readable, greppable \"## Delivery Considerations\" section written into a feature's spec.md, containing candidate flag name(s) and rollout intent. Define a stable token the scripts match deterministically regardless of surrounding prose. Provide cross-platform gate scripts: scripts/bash/rollout-gate.sh and scripts/powershell/rollout-gate.ps1. The gate script must: resolve the current feature directory (specs/<feature>/) so state is per-feature and never leaks across features; grep spec.md (and optionally plan.md/tasks.md when invoked for analyze) for the marker; honor hooks.enabled:false from config (treated as \"no rollout\"); output a machine-readable result (e.g., hasFlags=true|false plus candidate flag names) and an exit code the briefing commands can branch on. Define the contract briefing commands use: marker absent -> emit a one-line no-op and stop; marker present -> proceed with doctrine. Acceptance criteria: Running the gate on a spec with the marker returns hasFlags=true and the flag name(s); without the marker returns hasFlags=false. Scripts work on Linux/macOS (sh) and Windows (ps) and use relative paths compatible with Spec Kit script path rewriting. Disabling hooks via config forces hasFlags=false. Out of scope: the doctrine text of each phase (later features)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Skip rollout doctrine when no rollout intent exists (Priority: P1)

A developer runs any Spec Kit workflow command (`specify`, `clarify`, `plan`,
`tasks`, `analyze`, `checklist`, `implement`) on a feature that has no
delivery-risk signals. The rollout hook attached to that command checks the
feature's own spec for rollout intent, finds none, and the command proceeds
exactly as it would without the `rollout` extension installed — no extra
doctrine, no extra prompts, no visible overhead beyond a single no-op line.

**Why this priority**: This is the foundational promise of the extension
(vision.md 5.1-5.2): near-zero context pollution for the common case where a
feature does not need progressive delivery. Every other hook behavior in the
extension depends on this gate being correct and fast.

**Independent Test**: Run the gate script directly against a feature directory
whose `spec.md` has no `## Delivery Considerations` section and confirm it
reports "no rollout" via both its machine-readable output and its exit code,
without needing any other extension component to be present.

**Acceptance Scenarios**:

1. **Given** a feature's `spec.md` contains no `## Delivery Considerations`
   section, **When** the gate script is run against that feature's directory,
   **Then** it reports `hasFlags=false`, an empty candidate-flags list, and an
   exit code that signals "no rollout" to a calling command.
2. **Given** a feature's `spec.md` contains no marker, **When** a briefing
   command invokes the gate as part of its own execution, **Then** the
   briefing command contract calls for emitting a single no-op line and
   stopping, with no rollout doctrine injected.

---

### User Story 2 - Surface rollout intent to later workflow phases (Priority: P1)

A developer runs `/speckit.specify` on a feature that does carry
delivery-risk signals. The agent records that intent as a `## Delivery
Considerations` section in the feature's `spec.md`, naming one or more
candidate flags. When the developer later runs `/speckit.plan`,
`/speckit.tasks`, or other phase commands on the same feature, each command's
rollout hook detects the marker and proceeds to the doctrine-injection branch
of its contract, carrying the candidate flag name(s) forward.

**Why this priority**: This is the other half of the self-gating contract and
what makes the marker useful as shared state across the seven hooks
(vision.md 5.1). Without reliable detection, later phases could not shape
`Delivery Strategy` or rollout tasks around confirmed intent.

**Independent Test**: Run the gate script directly against a feature directory
whose `spec.md` contains a `## Delivery Considerations` section naming one or
more candidate flags, and confirm it reports `hasFlags=true` plus the exact
candidate flag name(s), independent of any specific calling command.

**Acceptance Scenarios**:

1. **Given** a feature's `spec.md` contains a `## Delivery Considerations`
   section naming one candidate flag, **When** the gate script is run against
   that feature's directory, **Then** it reports `hasFlags=true`, a
   candidate-flags list containing that flag name, and an exit code that
   signals "rollout" to a calling command.
2. **Given** a `## Delivery Considerations` section naming multiple candidate
   flags, **When** the gate script is run, **Then** all candidate flag names
   are present in the machine-readable output.
3. **Given** the marker section text varies in surrounding prose, punctuation,
   or wording, **When** the gate script is run, **Then** detection still
   succeeds because matching relies on a stable heading token rather than any
   specific sentence content.

---

### User Story 3 - Team-level opt-out overrides any marker (Priority: P2)

A tech lead has set the extension's `hooks.enabled` configuration to `false`
for their team. Even on a feature whose `spec.md` already contains a `##
Delivery Considerations` section from before the toggle was flipped (or
written by a teammate who ignored the toggle), every rollout hook treats the
feature as having no rollout intent.

**Why this priority**: Per vision.md 5.3, the config toggle is the supported
opt-out short of uninstalling the extension, and it must win deterministically
over marker content so a team can fully suppress the behavior without editing
every feature's spec. This depends on User Stories 1 and 2's detection logic
already existing.

**Independent Test**: With `hooks.enabled` set to `false` in the resolved
configuration, run the gate script against a feature directory whose
`spec.md` contains a `## Delivery Considerations` section, and confirm the
result is identical to the "no marker" case.

**Acceptance Scenarios**:

1. **Given** the resolved configuration has `hooks.enabled: false`, **When**
   the gate script is run against a feature whose `spec.md` contains the
   marker, **Then** it reports `hasFlags=false` and the "no rollout" exit
   code, regardless of marker content.
2. **Given** `hooks.enabled` is `true` (or unset, defaulting to enabled),
   **When** the gate script is run against the same feature, **Then** it
   reports `hasFlags=true` and the candidate flag name(s).

---

### User Story 4 - Consistent behavior across chained artifacts for analyze (Priority: P3)

A developer runs `/speckit.analyze` on a feature where the rollout intent
was captured in `spec.md` but the marker check needs to additionally confirm
the intent is still reflected downstream. The gate script, when invoked in
its "analyze" mode, also inspects `plan.md` and/or `tasks.md` in the same
feature directory rather than `spec.md` alone.

**Why this priority**: Vision.md 5.1 lists `before_analyze` as validating
"rollout chain consistency (spec marker <-> plan strategy <-> tasks)". This
mode is an extension of the core detection behavior and lower priority than
the primary gate contract, since `analyze` is an optional command.

**Independent Test**: Run the gate script in its analyze-oriented mode against
a feature directory where `spec.md` has no marker but `plan.md` contains
rollout content, and confirm the script still reports `hasFlags=true` and
sourced flag name(s), separately from a default invocation that checks only
`spec.md`.

**Acceptance Scenarios**:

1. **Given** a feature directory's `plan.md` contains rollout content, **When**
   the gate script is run in analyze mode, **Then** it includes `plan.md` in
   its search and reports `hasFlags=true` if content is found there.
2. **Given** the same feature directory, **When** the gate script is run in its
   default (non-analyze) mode, **Then** it only searches `spec.md` and does
   not report a match sourced solely from `plan.md`.

### Edge Cases

- What happens when a feature directory cannot be resolved at all (command run
  outside of any recognized feature context)? The gate script MUST fail safe
  by reporting "no rollout" (`hasFlags=false`) with a distinct diagnostic exit
  code, rather than crashing or blocking the calling command.
- What happens when `spec.md` does not exist yet in the resolved feature
  directory (e.g., the gate is invoked before `/speckit.specify` has written
  anything)? The gate script MUST treat this the same as "marker absent."
- What happens when the `## Delivery Considerations` heading appears inside a
  code block or is quoted as an example rather than used as a real heading?
  The gate script MUST match on the literal heading line, accepting the
  documented risk that a quoted example could produce a false positive; this
  is an acceptable tradeoff for a lightweight, deterministic text match.
- What happens when the configuration file is missing or unreadable? The gate
  script MUST fall back to the documented default for `hooks.enabled` (enabled)
  rather than failing.
- What happens when the marker section is present but names zero candidate
  flags (e.g., intent captured but flag name not yet decided)? The gate script
  MUST still report `hasFlags=true` (marker presence, not flag-name presence,
  is the gating signal) with an empty or partial candidate-flags list.
- What happens when the two script implementations (`sh` and `ps1`) are run
  against the same feature directory and configuration? Both MUST produce
  equivalent `hasFlags` results and equivalent candidate-flags content.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extension MUST define a standard marker convention for
  capturing rollout intent inside a feature's `spec.md`: a section headed by
  the literal, stable heading text `## Delivery Considerations`, containing
  human-readable prose that names one or more candidate feature-flag names and
  describes rollout intent.
- **FR-002**: The marker MUST be matched deterministically by the heading
  token alone (`## Delivery Considerations`), independent of whatever
  surrounding prose, flag names, or formatting appears beneath it, so detection
  never depends on interpreting free-form text.
- **FR-003**: The extension MUST provide two independently invocable gate
  scripts that produce equivalent results for equivalent inputs: a POSIX-shell
  script at `scripts/bash/rollout-gate.sh` (Linux/macOS) and a PowerShell
  script at `scripts/powershell/rollout-gate.ps1` (Windows).
- **FR-004**: Each gate script MUST resolve the current feature's own
  directory (`specs/<feature>/`) using the same feature-resolution convention
  already used by other Spec Kit scripts, so gate state is always scoped to
  one feature and never leaks into or reads from another feature's artifacts.
- **FR-005**: By default, each gate script MUST search only the resolved
  feature's `spec.md` for the marker.
- **FR-006**: Each gate script MUST support an invocation mode intended for the
  `analyze` phase in which it additionally searches the resolved feature's
  `plan.md` and/or `tasks.md` for the marker, in addition to `spec.md`.
- **FR-007**: Each gate script MUST read the resolved rollout extension
  configuration and treat `hooks.enabled: false` as equivalent to "no rollout
  intent," overriding marker presence in `spec.md` (and, in analyze mode,
  `plan.md`/`tasks.md`) so the reported result is `hasFlags=false` regardless
  of marker content.
- **FR-008**: When the configuration cannot be resolved or is missing, each
  gate script MUST fall back to the documented default for `hooks.enabled`
  (enabled) rather than failing or blocking the calling command.
- **FR-009**: Each gate script MUST produce a machine-readable result
  containing at minimum: a `hasFlags` boolean-equivalent value and the list of
  candidate flag name(s) found in the marker section (empty when
  `hasFlags=false` or when no flag names are present).
- **FR-010**: Each gate script MUST terminate with a distinct, documented exit
  code for each of the following outcomes so a calling briefing command can
  branch on exit code alone without parsing output: marker present and hooks
  enabled ("rollout"); marker absent or hooks disabled ("no rollout"); feature
  directory could not be resolved (fail-safe "no rollout" with a diagnostic
  code).
- **FR-011**: The extension MUST define a shared contract that every rollout
  briefing command follows when consuming the gate result: when the gate
  reports "no rollout," the command MUST emit a single-line no-op statement and
  stop without further processing; when the gate reports "rollout," the
  command proceeds to its phase-specific doctrine (the doctrine content itself
  is out of scope for this feature).
- **FR-012**: Gate scripts MUST reference feature-relative paths (e.g.,
  `specs/<feature>/spec.md`) in a form compatible with Spec Kit's existing
  script path rewriting so the scripts function correctly regardless of which
  supported AI assistant integration invokes them.
- **FR-013**: The two gate script implementations MUST be kept behaviorally
  equivalent: given the same feature directory, spec content, and
  configuration, both MUST report the same `hasFlags` value and the same
  candidate-flags content.

### Key Entities

- **Delivery Considerations marker**: A section within a feature's `spec.md`,
  identified by the stable heading `## Delivery Considerations`, whose body
  names candidate feature-flag(s) and describes rollout intent in prose. This
  is the persisted state read by every gate invocation for that feature.
- **Gate result**: The machine-readable output of a gate script invocation for
  one feature: a `hasFlags` value, a list of candidate flag names, and an exit
  code, always scoped to a single resolved feature directory and a single
  invocation mode (default vs. analyze).
- **Hooks-enabled toggle**: A resolved configuration value (`hooks.enabled`)
  that, when `false`, forces every gate result for every feature to "no
  rollout" regardless of marker content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running the gate against a feature whose `spec.md` contains the
  `## Delivery Considerations` marker returns `hasFlags=true` and the correct
  candidate flag name(s) in 100% of tested cases, regardless of surrounding
  prose variations.
- **SC-002**: Running the gate against a feature whose `spec.md` does not
  contain the marker returns `hasFlags=false` in 100% of tested cases.
- **SC-003**: Setting the team-level toggle to disabled forces `hasFlags=false`
  for every feature tested, even when a marker is present, in 100% of tested
  cases.
- **SC-004**: The bash and PowerShell gate scripts produce identical
  `hasFlags` results and identical candidate-flag lists across an equivalent
  set of test features on both a Linux/macOS environment and a Windows
  environment.
- **SC-005**: A calling briefing command can determine "proceed with doctrine"
  vs. "stop with no-op" purely from the gate's exit code, without needing to
  parse or interpret any output text.
- **SC-006**: Gate state for one feature is never affected by the presence or
  content of a marker in any other feature's directory, verified across at
  least two concurrently existing features with different marker states.

## Assumptions

- The feature-directory resolution mechanism already established by Spec
  Kit's own scripts (e.g., `.specify/feature.json` and/or branch-based
  fallback, as used by `check-prerequisites.sh`) is reused rather than
  reinvented, so gate scripts stay consistent with the rest of the toolchain.
- The rollout extension's configuration resolution (layered defaults, project
  config, local overrides, env vars) and the `hooks.enabled` field's shape and
  default are delivered by the configuration-system feature
  ([002-config-system](../002-config-system/spec.md)); this feature only
  consumes the resolved `hooks.enabled` value, it does not define the
  resolution mechanism itself.
- "Candidate flag name(s)" are plain text tokens written by the agent into the
  marker section (e.g., a short identifier-like string); this feature does not
  impose or validate a specific flag-naming syntax beyond being able to
  extract them as text.
- The doctrine text injected by each phase's briefing command when the gate
  reports "rollout" is out of scope for this feature and is delivered by the
  per-phase command features (`brief-specify.md`, `brief-plan.md`, etc.).
- FR-011's no-op/proceed contract and FR-012's script-path-rewriting
  compatibility describe how the seven `brief-*.md` briefing commands must
  eventually behave, but this feature does not itself edit those command
  files (see plan.md's Project Structure). This feature delivers and
  verifies the contract's shape (documented interface, output fields, exit
  codes) in isolation; each command's actual end-to-end wiring to that
  contract is verified by the per-phase feature that authors its doctrine.
- Machine-readable output format (e.g., JSON vs. simple key=value lines) is an
  implementation detail to be finalized during planning, as long as it
  satisfies FR-009's minimum content requirement and is parsed consistently by
  both script implementations' callers.
- The exact syntax of the optional candidate-flag sub-convention (the
  `Candidate flag(s):` line within the marker) is defined during planning in
  research.md and data-model.md, not restated here, per the spec/plan WHAT/HOW
  separation.
