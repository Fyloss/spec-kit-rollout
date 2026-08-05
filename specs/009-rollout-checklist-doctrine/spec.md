# Feature Specification: Rollout Checklist Doctrine (Pre-Checklist Briefing)

**Feature Branch**: `[009-rollout-checklist-doctrine]`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (section 5.1). Specify commands/brief-checklist.md, run automatically by the before_checklist hook, self-gated via the shared gate (Feature 3). Requirements: If no marker: one-line no-op, stop. If marker present: add rollout-quality checklist items, e.g.: flag naming defined; environments/targeting specified; telemetry gates defined; rollback conditions present; rollout phases ordered and complete. Acceptance criteria: Generated checklist for a rollout feature includes the rollout-quality items. Non-rollout features get no rollout checklist items. Out of scope: other checklist categories (handled by Spec Kit core)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add rollout-quality checklist items to a flagged feature (Priority: P1)

A developer runs `/speckit.checklist` on a feature whose `spec.md` carries a
`## Delivery Considerations` marker (Feature 004). The pre-checklist
briefing recognizes the marker via the shared gate script and instructs the
agent to add a dedicated rollout-quality category to the generated
checklist, covering: flag naming defined; environments/targeting specified;
telemetry gates defined; rollback conditions present; rollout phases ordered
and complete.

**Why this priority**: This is the core problem this feature exists to
solve (vision.md §5.1, Decision D6): without this briefing, `/speckit.checklist`
has no awareness that rollout content exists and would produce a checklist
that never verifies the quality of the Delivery Strategy the rest of the
rollout chain depends on.

**Independent Test**: Run `/speckit.specify` on a feature description with
clear rollout signals so the marker is written, then run `/speckit.checklist`
and confirm the generated checklist file contains a rollout-quality category
with items covering flag naming, environments/targeting, telemetry gates,
rollback conditions, and rollout phase ordering/completeness.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker, **When**
   `/speckit.checklist` runs, **Then** the resulting checklist file contains
   a rollout-quality category with checklist items covering flag naming,
   environments/targeting, telemetry gates, rollback conditions, and
   rollout phase ordering/completeness.
2. **Given** the same feature, **When** the rollout-quality items are
   generated, **Then** each item is phrased as a verifiable checklist item
   (testable against `spec.md` and/or `plan.md`), consistent with the
   format of the other categories already produced by `/speckit.checklist`.
3. **Given** a feature whose `plan.md` already contains a `## Delivery
   Strategy` section, **When** `/speckit.checklist` runs, **Then** the
   rollout-quality items are worded to check that section's completeness
   (e.g., "rollback conditions present" checks the Delivery Strategy's
   rollback field), not just the presence of the spec marker.

---

### User Story 2 - Non-rollout feature gets no rollout checklist items (Priority: P1)

A developer runs `/speckit.checklist` on a feature whose `spec.md` contains
no `## Delivery Considerations` marker. The briefing's self-gate check via
the shared gate script (Feature 003) detects the absence and the checklist
flow proceeds exactly as it would without the `rollout` extension installed:
no rollout-quality category, no rollout-related items, no visible overhead.

**Why this priority**: Equal priority to Story 1 — the near-zero
context-pollution guarantee for the common case (vision.md §5.1/§5.2) must
hold at the checklist phase just as it does at specify, clarify, plan,
tasks, and analyze.

**Independent Test**: Run `/speckit.checklist` on a feature whose `spec.md`
has no `## Delivery Considerations` marker, and confirm the briefing emits a
single-line no-op message and that the generated checklist contains no
rollout-quality category or item of any kind.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker,
   **When** `/speckit.checklist` runs, **Then** the briefing emits a
   one-line no-op message and adds no rollout content to the checklist
   generation flow.
2. **Given** the same non-rollout feature, **When** the checklist file is
   produced, **Then** it contains no rollout-quality category and no
   rollout-related checklist item.

---

### User Story 3 - Rollout items reflect actual gaps rather than a fixed boilerplate list (Priority: P2)

A developer runs `/speckit.checklist` on a feature whose marker is present
but whose `plan.md` has no `## Delivery Strategy` section yet (e.g.,
checklist is run before `/speckit.plan`). The briefing still adds the
rollout-quality category — checklist items validate a future artifact's
expected quality, so their presence does not require the target content to
already exist — but each item remains phrased as a check to perform, not as
a status claim, so it reads correctly regardless of when in the workflow
checklist is invoked.

**Why this priority**: Prevents the briefing from either wrongly requiring a
Delivery Strategy to already exist before adding rollout items, or from
mis-wording items as if they were findings — keeping the checklist's role
(a quality gate, not a report) intact. Depends on Story 1's item set already
existing.

**Independent Test**: Run `/speckit.specify` on a feature description with
clear rollout signals so the marker is written, then run `/speckit.checklist`
before ever running `/speckit.plan`, and confirm the rollout-quality items
still appear, phrased as checks (e.g., "Rollback conditions are defined") to
be verified against the plan once it exists, rather than as findings
asserting a gap.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker and no
   `plan.md` yet (or a `plan.md` with no `## Delivery Strategy` section),
   **When** `/speckit.checklist` runs, **Then** the rollout-quality category
   is still added with all five items, phrased as checks to perform rather
   than as pass/fail findings.
2. **Given** the same feature, **When** a reader reviews the generated
   checklist, **Then** nothing in the rollout-quality category asserts that
   the Delivery Strategy is missing or incomplete — the checklist items
   simply state what must be verified.

---

### Edge Cases

- What happens when the developer's `/speckit.checklist` request already
  targets a specific, unrelated checklist type (e.g., "security checklist")
  for a rollout feature? The briefing still adds the rollout-quality
  category as an additional category alongside whatever the user requested;
  it does not replace or crowd out the user's requested focus.
- What happens when the marker names more than one candidate flag? The
  briefing adds one shared rollout-quality category whose items apply
  across all named flags, rather than duplicating the category once per
  flag (per-flag granularity is out of scope for this feature, consistent
  with Feature 008's chain-validation approach).
- What happens if the shared gate script itself fails to resolve the
  feature directory (diagnostic exit code)? The briefing treats this
  identically to the no-marker case: one-line no-op, no rollout-quality
  category added.
- What happens when `plan.md`'s `## Delivery Strategy` section already
  exists and is fully populated? The rollout-quality items still appear as
  standard checklist items (not pre-marked as passed) — `/speckit.checklist`
  produces a checklist to be worked through, not an auto-graded report; this
  feature only ensures the right items exist, not their checked/unchecked
  state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `before_checklist` briefing (`commands/brief-checklist.md`)
  MUST invoke the shared rollout gate script (Feature 003) in its default
  mode against `spec.md` before deciding whether to add any rollout content
  to the checklist generation flow.
- **FR-002**: If the gate script reports no marker present (`hasFlags=false`,
  including the diagnostic exit code), the briefing MUST emit a single-line
  no-op message and MUST add no rollout-quality category, item, or other
  rollout-related content to the generated checklist.
- **FR-003**: If the gate script reports a marker present (`hasFlags=true`),
  the briefing MUST instruct the agent to add a distinct rollout-quality
  category to the checklist it generates, in addition to whatever
  category/categories the user's checklist request already produces.
- **FR-004**: The rollout-quality category MUST include, at minimum, checklist
  items covering each of the following: flag naming is defined; target
  environments/targeting rules are specified; telemetry gates are defined;
  rollback conditions are present; and rollout phases are ordered and
  complete.
- **FR-005**: Each rollout-quality item MUST be phrased as a verifiable
  checklist item consistent with the existing checklist item format
  (`- [ ] CHKxxx <item text>`), not as a status report, finding, or
  pass/fail assertion.
- **FR-006**: The rollout-quality items MUST be worded to be checked
  against the feature's actual rollout content (the spec's Delivery
  Considerations marker and, once it exists, the plan's Delivery Strategy
  section per Feature 006) rather than as generic, content-free boilerplate
  text.
- **FR-007**: The briefing MUST instruct adding the rollout-quality category
  regardless of whether `plan.md` yet contains a `## Delivery Strategy`
  section — item presence in the checklist MUST NOT depend on the target
  artifact already being complete, since checklist items describe what to
  verify, not a current state.
- **FR-008**: If the marker names more than one candidate flag, the briefing
  MUST instruct adding a single shared rollout-quality category whose items
  apply across all named flags, rather than duplicating the category per
  flag.
- **FR-009**: The briefing MUST NOT instruct removing, replacing, or
  reordering any other checklist category the user's request or Spec Kit
  core would otherwise produce — the rollout-quality category is additive
  only.
- **FR-010**: The briefing's content MUST remain scoped to the
  rollout-quality checklist category only: it MUST NOT include instructions
  for other checklist categories (security, performance, UX, etc.), MUST NOT
  include Delivery Strategy authoring doctrine (reserved for Feature 006),
  and MUST NOT include instructions for interacting with any feature-flag
  provider or its MCP server.
- **FR-011**: The briefing content MUST replace the current placeholder body
  of `commands/brief-checklist.md` (which only announces itself as a
  placeholder) with the full doctrine described by FR-001 through FR-010.

### Key Entities

- **Rollout-quality category**: The dedicated checklist category this
  briefing adds when a marker is present, containing the five rollout
  checklist items (flag naming, environments/targeting, telemetry gates,
  rollback conditions, rollout phase ordering/completeness).
- **Delivery Considerations marker**: The `## Delivery Considerations`
  heading in `spec.md` (Feature 004), used here only as the gate script's
  state signal that determines whether the rollout-quality category is
  added.
- **Delivery Strategy section**: The `## Delivery Strategy` block inside
  `plan.md` (Feature 006), the artifact the rollout-quality items are
  ultimately meant to be checked against once it exists.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A checklist generated by `/speckit.checklist` for a feature
  with a `## Delivery Considerations` marker contains a rollout-quality
  category with all five specified items 100% of the time.
- **SC-002**: A checklist generated by `/speckit.checklist` for a feature
  without a `## Delivery Considerations` marker contains zero rollout-related
  items or categories 100% of the time.
- **SC-003**: The one-line no-op path adds no more than a single line of
  visible overhead to the checklist generation flow for non-rollout
  features.
- **SC-004**: Running the gate script before and after `/speckit.checklist`
  produces the same `hasFlags` result, confirming the briefing never
  modifies `spec.md`'s marker state as a side effect of adding checklist
  items.

## Assumptions

- The rollout-quality category is additive to whatever checklist type the
  user requests (e.g., "UX checklist", "requirements checklist"); it is
  never the sole category produced.
- "Rollout phases ordered and complete" refers to the phased rollout
  sequence established in the Delivery Strategy section (Feature 006, e.g.,
  internal → 5% → 25% → 100%), not to Spec Kit workflow phases.
- The five rollout-quality items listed in FR-004 are the minimum required
  set; the agent MAY add closely related items (e.g., a specific item per
  named flag) as long as the five baseline categories are represented.
- This feature does not define a new checklist file or command invocation
  path; it only augments the content of whatever checklist
  `/speckit.checklist` already generates for the current feature.
