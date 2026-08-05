# Feature Specification: Rollout Plan Doctrine (Pre-Plan Briefing)

**Feature Branch**: `[006-rollout-plan-doctrine]`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 4, 5.2, 9). Specify commands/brief-plan.md, run automatically by the before_plan hook, self-gated via the shared gate (Feature 3). Requirements: If no marker: one-line no-op, stop. Keep a minimal cheap sniff of the /plan arguments so rollout intent introduced at plan time is caught and back-fills the marker. If marker present: instruct the agent to add a \"## Delivery Strategy\" section to plan.md containing: feature flag name, provider (LaunchDarkly), phased rollout (e.g., internal -> 5% -> 25% -> 100%), targeting rules, telemetry gates, rollback conditions. Content lineage: the Delivery Strategy is derived from the spec's requirements and clarified parameters; spec.md is used for state, plan content is authored here. Reference the optional rollout-section template if present (Feature 12) but do not require it. Acceptance criteria: A rollout feature's plan.md contains a complete Delivery Strategy section matching the vision's example structure. Late-introduced rollout intent at /plan is detected and the marker is back-filled. Non-rollout features get no Delivery Strategy. Out of scope: task breakdown (Feature 7), provider execution."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Produce a Delivery Strategy for an already-flagged feature (Priority: P1)

A developer runs `/speckit.plan` on a feature whose `spec.md` already carries
a `## Delivery Considerations` marker (written during `/speckit.specify` per
Feature 004, and possibly enriched during `/speckit.clarify` per Feature 005).
The pre-plan briefing recognizes the marker via the shared gate script, and
directs the agent to add a `## Delivery Strategy` section to `plan.md`: feature
flag name, provider (LaunchDarkly), phased rollout, targeting rules, telemetry
gates, and rollback conditions — grounded in the spec's requirements and any
clarified rollout parameters.

**Why this priority**: This is the concrete deliverable the whole rollout
chain (vision.md §4-5.1) exists to produce — the first point where a real,
reviewable rollout strategy appears in a Spec Kit artifact. Without it, the
marker and clarified parameters accumulated by Features 004-005 would never
surface as usable plan content.

**Independent Test**: Run `/speckit.specify` and `/speckit.clarify` on a
feature description with clear rollout signals so the marker is written and
enriched, then run `/speckit.plan` and confirm the resulting `plan.md`
contains a `## Delivery Strategy` section with all six elements populated.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker containing
   a candidate flag name and clarified rollout parameters, **When**
   `/speckit.plan` runs, **Then** the resulting `plan.md` contains a `##
   Delivery Strategy` section with a feature flag name, `Provider: LaunchDarkly`,
   a phased rollout sequence, targeting rules, telemetry gates, and rollback
   conditions.
2. **Given** the marker's rollout parameters are only partially specified
   (e.g., phases and audience given, telemetry gates left open), **When**
   `/speckit.plan` runs, **Then** the agent still produces a complete Delivery
   Strategy section, proposing reasonable draft values for any still-missing
   element grounded in the spec's stated requirements, rather than omitting
   that element or blocking the plan.
3. **Given** a `templates/rollout-section.md` file exists in the extension,
   **When** `/speckit.plan` runs on a flagged feature, **Then** the agent may
   consult it for structural consistency, but the Delivery Strategy section is
   still produced correctly if the file is absent.

---

### User Story 2 - Leave a non-rollout feature's plan untouched (Priority: P1)

A developer runs `/speckit.plan` on a feature whose `spec.md` contains no
`## Delivery Considerations` marker, and whose `/plan` arguments contain no
rollout signals either. The briefing's self-gate detects the absence and the
plan flow proceeds exactly as it would without the `rollout` extension
installed: no Delivery Strategy section, no rollout content, no visible
overhead.

**Why this priority**: Equal priority to Story 1 — the near-zero
context-pollution guarantee for the common case (vision.md §5.1/§5.2) must
hold at the plan phase just as it does at specify and clarify.

**Independent Test**: Run `/speckit.plan` on a feature whose `spec.md` has no
`## Delivery Considerations` marker and whose `/plan` invocation carries no
rollout language, and confirm no `## Delivery Strategy` section or other
rollout content appears anywhere in the resulting `plan.md`.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker and
   `/plan` arguments with no rollout signals, **When** `/speckit.plan` runs,
   **Then** the briefing emits a one-line no-op and the plan proceeds with no
   rollout content added.
2. **Given** the same non-rollout feature, **When** planning finishes,
   **Then** the resulting `plan.md` contains no `## Delivery Strategy` section
   and no other rollout-related content.

---

### User Story 3 - Catch rollout intent introduced late, at plan time (Priority: P2)

A developer did not signal rollout intent during `/speckit.specify` or
`/speckit.clarify`, so `spec.md` has no `## Delivery Considerations` marker.
At `/speckit.plan` time, the developer's own `/plan` arguments introduce
rollout language for the first time (e.g., "release to 5% first" or "roll
this out to internal users before GA"). The briefing performs a minimal,
cheap sniff of the `/plan` arguments, recognizes the rollout intent, back-fills
a `## Delivery Considerations` marker into `spec.md`, and proceeds to produce
the `## Delivery Strategy` section in `plan.md` as if the marker had existed
from the start.

**Why this priority**: This is the specific late-detection guardrail called
out in vision.md §5.2 ("Late-introduced intent") — without it, a developer
who only thinks to mention rollout at plan time would get no Delivery
Strategy and no persisted state for later phases (tasks, analyze, checklist,
implement) to pick up. Depends on Story 1's Delivery Strategy content already
existing to reuse once the marker is back-filled.

**Independent Test**: Run `/speckit.specify` on a feature description with no
rollout signals (no marker written), then run `/speckit.plan` with arguments
that contain rollout language, and confirm both that `spec.md` gains a `##
Delivery Considerations` marker and that `plan.md` gains a `## Delivery
Strategy` section in the same run.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker,
   **When** `/speckit.plan` runs with arguments containing rollout signals
   (e.g., cohort language, percentage language, phased-release language),
   **Then** the briefing writes a `## Delivery Considerations` marker into
   `spec.md` before proceeding.
2. **Given** the marker was just back-filled per the previous scenario,
   **When** the same `/speckit.plan` run continues, **Then** the resulting
   `plan.md` contains a `## Delivery Strategy` section, populated from the
   `/plan` arguments' rollout language and the spec's existing requirements.
3. **Given** `/plan` arguments contain no rollout signals and `spec.md` has no
   marker, **When** the sniff runs, **Then** no marker is written and the
   briefing proceeds exactly as in Story 2 (one-line no-op).

### Edge Cases

- What happens when the feature directory cannot be resolved by the shared
  gate script (exit code 2, per the Feature 003 contract)? The briefing
  treats this identically to "no marker" — falls through to the cheap `/plan`
  arguments sniff, and to a one-line no-op if that sniff also finds nothing.
- What happens when the marker is present but every one of its rollout
  parameters (phases, audience, percentages, telemetry gates, rollback
  conditions) is still unanswered? The agent still produces a complete
  Delivery Strategy section, proposing draft values grounded in the spec's
  requirements for each missing element rather than omitting it.
- What happens when `templates/rollout-section.md` does not exist in the
  installed extension? The agent produces the Delivery Strategy section from
  the doctrine's own instructions without needing that file.
- What happens when the `/plan` arguments sniff and an existing marker are
  both present at once? The existing marker takes precedence as the state
  signal; the sniff is only consulted in the no-marker branch and never
  overwrites or duplicates an existing marker.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pre-plan briefing content (`commands/brief-plan.md`) MUST
  invoke the shared gate script (`scripts/bash/rollout-gate.sh` /
  `scripts/powershell/rollout-gate.ps1`, per the Feature 003 contract) to
  determine whether the current feature's `spec.md` carries a `## Delivery
  Considerations` marker before deciding what doctrine to apply.
- **FR-002**: When the gate reports no marker (`hasFlags=false`, or exit code
  2 per the Feature 003 contract), the briefing content MUST instruct the
  agent to perform a minimal, cheap sniff of the current `/plan` invocation's
  arguments for rollout signals (the same category of signals used at
  specify time per vision.md §4: high-risk/irreversible changes, major UX
  changes, progressive migrations, explicit cohort or percentage language,
  performance/infra-sensitive changes) before deciding whether to no-op.
- **FR-003**: If that sniff finds no rollout signals, the briefing content
  MUST instruct the agent to emit a one-line no-op and add no `## Delivery
  Strategy` section or other rollout content to `plan.md`.
- **FR-004**: If that sniff finds rollout signals in the `/plan` arguments,
  the briefing content MUST instruct the agent to back-fill a `## Delivery
  Considerations` marker into `spec.md` (following the exact marker
  convention established by Feature 004: the literal heading and the
  "Candidate flag(s):" label recognized by the shared gate script), and then
  proceed as if the marker had been present from the start.
- **FR-005**: When a marker is present — whether pre-existing or just
  back-filled per FR-004 — the briefing content MUST instruct the agent to
  add a `## Delivery Strategy` section to `plan.md` containing: a feature
  flag name, `Provider: LaunchDarkly`, a phased rollout sequence (e.g.,
  internal → 5% → 25% → 100%), targeting rules, telemetry gates, and rollback
  conditions, matching the structure shown in vision.md §9.
- **FR-006**: The briefing content MUST instruct the agent to derive the
  Delivery Strategy's content from the spec's stated requirements and any
  rollout parameters already clarified in the `## Delivery Considerations`
  marker (phases, audience/segments, percentages, telemetry gates, rollback
  conditions per Feature 005) — never inventing the strategy independently of
  the spec — while treating `spec.md` itself as consulted only for
  flag/no-flag state during the gate check, per vision.md §5.2's content
  lineage rule.
- **FR-007**: When a rollout parameter needed for the Delivery Strategy is
  still missing from the marker at plan time, the briefing content MUST
  instruct the agent to propose a reasonable draft value grounded in the
  spec's requirements for that element rather than omitting it or blocking
  the plan.
- **FR-008**: The briefing content MUST instruct the agent that if an optional
  `templates/rollout-section.md` file exists in the extension, it may be
  consulted for structural consistency when authoring the Delivery Strategy
  section, but MUST NOT require its presence — the Delivery Strategy MUST be
  produced correctly even when that file is absent.
- **FR-009**: The briefing content MUST remain scoped to plan-phase Delivery
  Strategy authoring only: it MUST NOT include task-breakdown content or
  instructions for generating rollout tasks (that content belongs to Feature
  7's `before_tasks` briefing), and MUST NOT include instructions for
  interacting with any feature-flag provider or its MCP server (that content
  belongs to the `before_implement` briefing).
- **FR-010**: The briefing content MUST replace the current placeholder body
  of `commands/brief-plan.md` (which only announces itself as a placeholder)
  with the full doctrine described by FR-001 through FR-009.

### Key Entities

- **Delivery Strategy section**: A `## Delivery Strategy` block in `plan.md`
  containing feature flag name, provider, phased rollout sequence, targeting
  rules, telemetry gates, and rollback conditions — the plan-phase
  counterpart to the spec-phase `Delivery Considerations` marker.
- **`/plan` arguments sniff**: A lightweight, no-marker-branch check of the
  current `/plan` invocation's own arguments for rollout signals, used only
  to decide whether to back-fill a marker; distinct from the shared gate
  script's `spec.md` marker check.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a feature whose spec carries a `Delivery Considerations`
  marker, 100% of generated `plan.md` files contain a `Delivery Strategy`
  section with all six required elements (flag name, provider, phased
  rollout, targeting, telemetry gates, rollback conditions).
- **SC-002**: On a feature whose spec has no marker and whose `/plan`
  arguments carry no rollout signals, 100% of generated `plan.md` files
  contain no `Delivery Strategy` section or other rollout content.
- **SC-003**: On a feature whose spec has no marker but whose `/plan`
  arguments carry rollout signals, 100% of such runs result in both a
  back-filled marker in `spec.md` and a `Delivery Strategy` section in
  `plan.md` in the same run.
- **SC-004**: A review of `commands/brief-plan.md` confirms it contains no
  task-breakdown instructions and no feature-flag-provider MCP interaction
  instructions.

## Assumptions

- The `/plan` arguments sniff reuses the same category of rollout-signal
  heuristics already established for `/speckit.specify` in vision.md §4
  (high-risk/irreversible changes, major UX changes, progressive migrations,
  cohort/percentage language, performance/infra-sensitive changes), rather
  than defining a new, separate heuristic set, since both are advisory,
  cheap, natural-language sniffs over free-text input.
- Unlike the `before_specify` and `before_clarify` briefings, which forbid
  naming a feature-flag provider in `spec.md`, this briefing is expected to
  name the provider (`LaunchDarkly`, per vision.md §1's V1 scope) explicitly
  in `plan.md`'s Delivery Strategy section, since vision.md §5.1 reserves
  provider naming for the plan phase onward.
- When rollout parameters needed for the Delivery Strategy are still missing
  at plan time, proposing a reasonable draft value is preferred over leaving
  the element blank or blocking the plan, consistent with Spec Kit's general
  planning behavior of filling gaps with reasonable defaults.
- `templates/rollout-section.md` (Feature 12, out of scope for this feature)
  may or may not exist in the installed extension at the time this briefing
  runs; the doctrine must not assume its presence.
