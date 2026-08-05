# Feature Specification: Rollout Tasks Doctrine (Pre-Tasks Briefing)

**Feature Branch**: `[007-rollout-tasks-doctrine]`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 4, 5.2). Specify commands/brief-tasks.md, run automatically by the before_tasks hook, self-gated via the shared gate (Feature 3). Requirements: If no marker: one-line no-op, stop. If marker present: instruct the agent to emit concrete, ordered rollout tasks: create the LaunchDarkly feature flag, configure environments, configure targeting rules, integrate the application SDK, add telemetry validation, define rollback conditions. Content lineage (critical): rollout tasks MUST be derived from the plan's Delivery Strategy, not regenerated from the spec. spec.md is consulted only for flag/no-flag state. Acceptance criteria: tasks.md contains rollout tasks that map 1:1 to the plan's Delivery Strategy (flag, environments, targeting, SDK, telemetry, rollback). If the plan has no Delivery Strategy, no rollout tasks are added. Out of scope: provider execution (Feature 10)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Emit ordered rollout tasks from an existing Delivery Strategy (Priority: P1)

A developer runs `/speckit.tasks` on a feature whose `spec.md` carries a `##
Delivery Considerations` marker (written during specify/clarify, Features
004-005) and whose `plan.md` already contains a complete `## Delivery
Strategy` section (written during plan, Feature 006). The pre-tasks briefing
recognizes the marker via the shared gate script, then reads the plan's
Delivery Strategy section and emits six concrete, ordered rollout tasks in
`tasks.md`: create the LaunchDarkly feature flag, configure environments,
configure targeting rules, integrate the application SDK, add telemetry
validation, and define rollback conditions — each one grounded strictly in
the corresponding value already written in the Delivery Strategy section.

**Why this priority**: This is the concrete deliverable the rollout chain
(vision.md §4) exists to produce at the tasks phase — the point where the
reviewable strategy in `plan.md` becomes actionable, ordered work items.
Without it, a fully-specified Delivery Strategy would never surface as
executable tasks.

**Independent Test**: Run `/speckit.specify`, `/speckit.clarify`, and
`/speckit.plan` on a feature description with clear rollout signals so that
`spec.md` carries the marker and `plan.md` carries a complete Delivery
Strategy section, then run `/speckit.tasks` and confirm `tasks.md` contains
all six rollout tasks, each traceable to a specific value in the Delivery
Strategy section.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker and a
   `plan.md` with a complete `## Delivery Strategy` section (flag name,
   provider, phased rollout, targeting rules, telemetry gates, rollback
   conditions), **When** `/speckit.tasks` runs, **Then** the resulting
   `tasks.md` contains six ordered rollout tasks: create the feature flag,
   configure environments, configure targeting rules, integrate the
   application SDK, add telemetry validation, and define rollback
   conditions.
2. **Given** the same feature, **When** the rollout tasks are generated,
   **Then** each task's content (flag name, environment names, targeting
   rules, telemetry thresholds, rollback trigger) matches the values already
   present in the plan's Delivery Strategy section, not language re-derived
   from `spec.md`'s requirements text.
3. **Given** a Delivery Strategy section that names more than one candidate
   flag, **When** `/speckit.tasks` runs, **Then** the agent repeats the
   six-task pattern once per named flag rather than merging them into a
   single ambiguous task set.

---

### User Story 2 - Leave a non-rollout feature's tasks untouched (Priority: P1)

A developer runs `/speckit.tasks` on a feature whose `spec.md` contains no
`## Delivery Considerations` marker. The briefing's self-gate check via the
shared gate script (Feature 003) detects the absence and the tasks flow
proceeds exactly as it would without the `rollout` extension installed: no
rollout tasks, no rollout-related content, no visible overhead.

**Why this priority**: Equal priority to Story 1 — the near-zero
context-pollution guarantee for the common case (vision.md §5.1/§5.2) must
hold at the tasks phase just as it does at specify, clarify, and plan.

**Independent Test**: Run `/speckit.tasks` on a feature whose `spec.md` has
no `## Delivery Considerations` marker, and confirm the briefing emits a
single-line no-op message and that no rollout task of any kind appears
anywhere in the resulting `tasks.md`.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker,
   **When** `/speckit.tasks` runs, **Then** the briefing emits a one-line
   no-op message and stops without adding any rollout content.
2. **Given** the same non-rollout feature, **When** task generation
   finishes, **Then** `tasks.md` contains no rollout tasks and no other
   rollout-related content.

---

### User Story 3 - Withhold rollout tasks when the plan has no Delivery Strategy (Priority: P2)

A developer runs `/speckit.tasks` on a feature whose `spec.md` does carry a
`## Delivery Considerations` marker, but whose `plan.md` was generated,
edited, or regenerated in a way that leaves it without a `## Delivery
Strategy` section (for example, the plan phase was run before the rollout
extension was installed, or the section was manually removed). The briefing
must not fall back to inventing rollout task content from `spec.md`'s
requirements — because content lineage requires tasks to be derived from the
plan, not the spec, the briefing withholds all rollout tasks and reports the
gap instead.

**Why this priority**: This is the strict content-lineage guardrail called
out in vision.md §5.2 ("Content lineage") — without it, the briefing might
regenerate a plausible-looking but ungrounded rollout strategy directly from
the spec, duplicating and potentially contradicting the plan phase's actual
decisions. Depends on Story 2's gate-check mechanics but adds a second,
plan-specific check.

**Independent Test**: Run `/speckit.specify` on a feature description with
clear rollout signals so the marker is written, then run `/speckit.plan` in
a way that produces no `## Delivery Strategy` section (or manually remove
it), then run `/speckit.tasks` and confirm no rollout tasks appear in
`tasks.md`.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker and a
   `plan.md` with no `## Delivery Strategy` section, **When**
   `/speckit.tasks` runs, **Then** the briefing emits a one-line status
   message noting the missing Delivery Strategy and adds no rollout tasks to
   `tasks.md`.
2. **Given** the same feature, **When** task generation finishes, **Then**
   `tasks.md` contains no task whose content was derived from `spec.md`'s
   requirements text as a substitute for the missing Delivery Strategy.

---

### Edge Cases

- What happens when the plan's Delivery Strategy section is present but only
  partially populated (e.g., rollback conditions left as a placeholder or
  omitted)? The briefing emits tasks only for the elements actually present
  in the Delivery Strategy and does not fabricate values for missing
  elements from `spec.md` or general assumptions.
- How does the briefing handle a Delivery Strategy section that uses
  non-standard formatting (e.g., missing the literal element labels used in
  Feature 006's doctrine)? The briefing makes a best-effort match against
  the six expected element categories and, for any category it cannot
  confidently locate, omits that task rather than guessing.
- What happens if the shared gate script itself fails to resolve the feature
  directory (diagnostic exit code)? The briefing treats this identically to
  the no-marker case: one-line no-op, no rollout tasks added.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `before_tasks` briefing (`commands/brief-tasks.md`) MUST
  invoke the shared rollout gate script (Feature 003) in its default mode
  before generating any rollout task content.
- **FR-002**: If the gate script reports no marker present (`hasFlags=false`,
  including the diagnostic exit code), the briefing MUST emit a single-line
  no-op message and add no rollout content to `tasks.md`.
- **FR-003**: If the gate script reports a marker present (`hasFlags=true`),
  the briefing MUST next check `plan.md` for a `## Delivery Strategy`
  section before generating any rollout tasks.
- **FR-004**: If `plan.md` contains no `## Delivery Strategy` section, the
  briefing MUST emit a one-line status message reporting the gap and MUST
  add no rollout tasks to `tasks.md` — it MUST NOT regenerate rollout task
  content from `spec.md`'s requirements as a substitute.
- **FR-005**: If a `## Delivery Strategy` section is present in `plan.md`,
  the briefing MUST instruct the agent to emit six ordered rollout tasks in
  `tasks.md`, each mapped to one element of the Delivery Strategy: create
  the feature flag, configure environments, configure targeting rules,
  integrate the application SDK, add telemetry validation, and define
  rollback conditions.
- **FR-006**: Each rollout task's content MUST be derived exclusively from
  the values already present in the plan's Delivery Strategy section (flag
  name, provider, phased rollout, targeting rules, telemetry gates, rollback
  trigger) — the briefing MUST NOT instruct re-reading `spec.md`'s
  requirements text as a content source for task details.
- **FR-007**: The briefing MUST instruct that `spec.md` is consulted only
  through the gate script's state output (marker presence), never mined
  directly for rollout task content at the tasks phase.
- **FR-008**: The six rollout tasks MUST be ordered to reflect a logical
  delivery sequence (flag creation before environment and targeting
  configuration; SDK integration before telemetry validation; rollback
  conditions defined alongside or after telemetry validation).
- **FR-009**: If the Delivery Strategy section is missing one or more of its
  six expected elements, the briefing MUST instruct generating tasks only
  for the elements actually present and MUST NOT fabricate missing values.
- **FR-010**: If the Delivery Strategy section names more than one candidate
  flag, the briefing MUST instruct repeating the six-task pattern once per
  named flag rather than collapsing them into one ambiguous task set.
- **FR-011**: The briefing's content MUST NOT include instructions to invoke
  any provider MCP tool or execute any live provider action — task content
  describes what must be done, not how it is executed against a provider
  (reserved for the `before_implement` briefing, Feature 10).

### Key Entities

- **Delivery Strategy section**: The `## Delivery Strategy` block inside
  `plan.md` (Feature 006), the sole content source for rollout tasks —
  contains flag name(s), provider, phased rollout sequence, targeting rules,
  telemetry gates, and rollback conditions.
- **Rollout task set**: The six ordered tasks emitted into `tasks.md` for a
  given flag — create flag, configure environments, configure targeting,
  integrate SDK, add telemetry validation, define rollback conditions.
- **Delivery Considerations marker**: The `## Delivery Considerations`
  heading in `spec.md` (Feature 004), used here only as the gate script's
  state signal, never as rollout task content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a feature with a complete Delivery Strategy section, 100%
  of the six rollout task categories appear in `tasks.md`, and each one is
  traceable to a specific value already present in that Delivery Strategy
  section.
- **SC-002**: For a feature with no `## Delivery Considerations` marker,
  `tasks.md` gains zero rollout-related lines, and the briefing's own output
  is a single line.
- **SC-003**: For a feature with a marker in `spec.md` but no `## Delivery
  Strategy` section in `plan.md`, `tasks.md` gains zero rollout tasks, and
  the briefing reports the gap in a single status line rather than
  silently doing nothing or inventing content.
- **SC-004**: Reviewers comparing any generated rollout task against the
  feature's `plan.md` can confirm the task's specific details (flag name,
  environment, targeting rule, telemetry threshold, or rollback trigger)
  originated in the Delivery Strategy section, with no detail traceable
  only to `spec.md`'s requirements text.

## Assumptions

- The shared gate script's default mode (spec.md only, Feature 003) remains
  sufficient for tasks-phase state detection; the marker's presence or
  absence is not expected to change between plan and tasks within the same
  workflow run, so no additional analyze-mode check is required here.
- The `## Delivery Strategy` heading and its six element labels follow the
  exact convention established by Feature 006's doctrine in
  `commands/brief-plan.md`; this briefing does not redefine that structure.
- `tasks.md`'s existing generated structure (phases / user-story groupings)
  can accommodate the additional rollout tasks without requiring any change
  to Spec Kit's core `tasks-template.md` (per the additive-only extension
  principle).
- A single canonical flag is the common case; the multi-flag repetition
  behavior (FR-010) is a secondary guardrail, not the primary design target.
