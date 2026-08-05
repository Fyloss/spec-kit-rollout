# Feature Specification: Rollout Analyze Doctrine (Pre-Analyze Briefing)

**Feature Branch**: `[008-rollout-analyze-doctrine]`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 5.1, Decision D6). Specify commands/brief-analyze.md, run automatically by the before_analyze hook, self-gated via the shared gate (Feature 3; analyze reads spec.md, plan.md, tasks.md). Requirements: If no marker: one-line no-op, stop. If marker present: treat rollout artifacts as intentional. Verify the rollout chain is consistent: spec Delivery Considerations marker <-> plan Delivery Strategy <-> tasks rollout tasks. Do NOT report rollout content as orphaned or untraceable. Report a gap ONLY when the chain is broken (e.g., marker present but no Delivery Strategy, or Delivery Strategy present but no rollout tasks). Acceptance criteria: Analyze on a consistent rollout feature reports no false orphans for rollout content. Analyze detects and reports a genuinely broken rollout chain. Out of scope: modifying artifacts to fix gaps (analyze reports only)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent rollout chain analyzed with no false orphans (Priority: P1)

A developer runs `/speckit.analyze` on a feature whose `spec.md` carries a
`## Delivery Considerations` marker (Feature 004), whose `plan.md` contains a
complete `## Delivery Strategy` section (Feature 006), and whose `tasks.md`
contains the corresponding rollout tasks (Feature 007). The pre-analyze
briefing recognizes the marker via the shared gate script, confirms the
Delivery Strategy section and rollout tasks are present, and instructs the
agent to treat all of this rollout content as intentional and already
cross-referenced — never flagging the marker, the Delivery Strategy section,
or the rollout tasks as orphaned requirements, unmapped tasks, duplication,
or ambiguity in the standard analyze report.

**Why this priority**: This is the core problem this feature exists to
solve (vision.md §5.1, Decision D6): without this briefing, `/speckit.analyze`
has no rollout-specific awareness and would very plausibly misclassify
legitimate, traceable rollout content as noise — undermining trust in both
the rollout chain and the analyze report itself.

**Independent Test**: Run `/speckit.specify`, `/speckit.clarify`,
`/speckit.plan`, and `/speckit.tasks` on a feature description with clear
rollout signals so that all three artifacts carry consistent rollout
content, then run `/speckit.analyze` and confirm the report contains zero
orphan/coverage-gap/duplication/ambiguity findings referencing the
Delivery Considerations marker, the Delivery Strategy section, or any
rollout task.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker, a
   `plan.md` with a complete `## Delivery Strategy` section, and a
   `tasks.md` with the corresponding rollout tasks, **When**
   `/speckit.analyze` runs, **Then** the report contains no finding that
   treats any of this rollout content as an orphaned requirement,
   an unmapped task, a duplication, or an ambiguity.
2. **Given** the same feature, **When** the report's Coverage Summary and
   Unmapped Tasks sections are produced, **Then** the Delivery Considerations
   marker, the Delivery Strategy section, and the rollout tasks are excluded
   from being counted as gaps.

---

### User Story 2 - Non-rollout feature analyze unaffected (Priority: P1)

A developer runs `/speckit.analyze` on a feature whose `spec.md` contains no
`## Delivery Considerations` marker. The briefing's self-gate check via the
shared gate script (Feature 003) detects the absence and the analyze flow
proceeds exactly as it would without the `rollout` extension installed: no
rollout-specific findings, no rollout-chain checks, no visible overhead.

**Why this priority**: Equal priority to Story 1 — the near-zero
context-pollution guarantee for the common case (vision.md §5.1/§5.2) must
hold at the analyze phase just as it does at specify, clarify, plan, and
tasks.

**Independent Test**: Run `/speckit.analyze` on a feature whose `spec.md`
has no `## Delivery Considerations` marker, and confirm the briefing emits a
single-line no-op message and that the rest of the analyze report is
identical to what it would be without the extension installed.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker,
   **When** `/speckit.analyze` runs, **Then** the briefing emits a one-line
   no-op message and performs no further rollout-chain checks.
2. **Given** the same non-rollout feature, **When** the analyze report is
   produced, **Then** it contains no rollout-chain finding of any kind.

---

### User Story 3 - Detect a chain broken between spec and plan (Priority: P2)

A developer runs `/speckit.analyze` on a feature whose `spec.md` carries a
`## Delivery Considerations` marker, but whose `plan.md` has no
`## Delivery Strategy` section (for example, the plan phase ran before the
rollout extension's plan doctrine was active, or the section was manually
removed). The briefing detects this specific break in the chain and
instructs the agent to report it as a distinct, clearly worded finding
rather than silently ignoring it or miscategorizing it as a generic
requirement-coverage gap.

**Why this priority**: This is the first of the two genuinely-broken-chain
scenarios named in the acceptance criteria — without detection here, a
feature could silently lose its rollout strategy between plan and tasks
with no signal to the developer.

**Independent Test**: Run `/speckit.specify` on a feature description with
clear rollout signals so the marker is written, run `/speckit.tasks`
without ever producing a `## Delivery Strategy` section in `plan.md` (or
manually remove it), then run `/speckit.analyze` and confirm the report
contains exactly one rollout-chain finding describing "marker present, no
Delivery Strategy in plan.md."

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker and a
   `plan.md` with no `## Delivery Strategy` section, **When**
   `/speckit.analyze` runs, **Then** the report contains a rollout-chain
   finding stating the marker is present but the Delivery Strategy section
   is missing from `plan.md`.
2. **Given** the same feature, **When** the finding is produced, **Then** it
   is not worded or categorized as if the marker itself were an orphaned or
   untraceable requirement — the gap is the missing plan content, not the
   spec marker.

---

### User Story 4 - Detect a chain broken between plan and tasks (Priority: P2)

A developer runs `/speckit.analyze` on a feature whose `plan.md` contains a
complete `## Delivery Strategy` section, but whose `tasks.md` contains no
rollout tasks traceable to it (for example, `/speckit.tasks` ran before the
rollout extension's tasks doctrine was active, or the tasks were manually
removed). The briefing detects this specific break and instructs the agent
to report it as a distinct finding, separate from the spec-to-plan break
described in Story 3.

**Why this priority**: This is the second of the two genuinely-broken-chain
scenarios named in the acceptance criteria — it guards the other end of the
chain, where a fully-specified Delivery Strategy exists but never made it
into actionable work items.

**Independent Test**: Produce a feature whose `plan.md` has a complete
`## Delivery Strategy` section but whose `tasks.md` has no rollout tasks
(e.g., by removing them after generation), run `/speckit.analyze`, and
confirm the report contains exactly one rollout-chain finding describing
"Delivery Strategy present, no rollout tasks in tasks.md," distinguishable
from the Story 3 finding.

**Acceptance Scenarios**:

1. **Given** a `plan.md` with a complete `## Delivery Strategy` section and
   a `tasks.md` with no rollout tasks, **When** `/speckit.analyze` runs,
   **Then** the report contains a rollout-chain finding stating the
   Delivery Strategy is present but no corresponding rollout tasks exist in
   `tasks.md`.
2. **Given** the same feature, **When** the finding is produced, **Then** it
   is distinguishable in wording and location from the Story 3 finding, so a
   reader can tell which link in the chain is broken.

---

### Edge Cases

- What happens when `tasks.md` contains only some of the six rollout task
  categories established by Feature 007 (a partially populated Delivery
  Strategy legitimately yields fewer tasks)? The briefing treats any
  non-zero count of traceable rollout tasks as chain-consistent for that
  link — it does not require all six categories to avoid reporting a break.
- What happens when the Delivery Considerations marker names more than one
  candidate flag and only some of them have corresponding rollout tasks?
  Per-flag chain granularity is out of scope for this feature; the briefing
  evaluates chain consistency at the feature level (marker present overall,
  Delivery Strategy present overall, at least one traceable rollout task
  present overall), not per individual flag name.
- What happens if the shared gate script itself fails to resolve the
  feature directory (diagnostic exit code)? The briefing treats this
  identically to the no-marker case: one-line no-op, no rollout-chain checks
  performed.
- What happens when `plan.md` or `tasks.md` is missing entirely (e.g.,
  `/speckit.analyze` is somehow invoked before those phases completed)? The
  briefing relies on analyze's own prerequisite check (which already aborts
  before this briefing runs if `tasks.md` is absent) and does not duplicate
  that validation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `before_analyze` briefing (`commands/brief-analyze.md`)
  MUST invoke the shared rollout gate script (Feature 003) in its default
  mode against `spec.md` before evaluating rollout-chain consistency.
- **FR-002**: If the gate script reports no marker present (`hasFlags=false`,
  including the diagnostic exit code), the briefing MUST emit a single-line
  no-op message and MUST NOT perform any further rollout-chain checks or
  alter any other part of the standard analyze report.
- **FR-003**: If the gate script reports a marker present (`hasFlags=true`),
  the briefing MUST instruct the agent to treat the `spec.md` `## Delivery
  Considerations` marker and its candidate flag name(s), the `plan.md` `##
  Delivery Strategy` section (when present), and any `tasks.md` rollout
  tasks (when present) as intentional, already-cross-referenced content —
  and MUST NOT report any of them as orphaned requirements, unmapped tasks,
  duplication, or ambiguity findings in analyze's standard detection passes.
- **FR-004**: When `hasFlags=true`, the briefing MUST instruct checking
  `plan.md` for a `## Delivery Strategy` heading, reusing the same
  heading-detection convention established in Features 006 and 007.
- **FR-005**: If the `## Delivery Strategy` heading is absent from
  `plan.md`, the briefing MUST instruct emitting a distinct rollout-chain
  finding in analyze's standard findings table reporting that the marker is
  present but the Delivery Strategy section is missing, and MUST NOT
  suppress or omit this finding.
- **FR-006**: If the `## Delivery Strategy` heading is present, the
  briefing MUST instruct checking `tasks.md` for the presence of at least
  one rollout task traceable to it, reusing the six rollout task categories
  established by Feature 007's doctrine (create flag, configure
  environments, configure targeting, integrate SDK, add telemetry
  validation, define rollback conditions), matched by presence rather than
  exact count or full per-flag completeness.
- **FR-007**: If the `## Delivery Strategy` heading is present but
  `tasks.md` contains no rollout task traceable to it, the briefing MUST
  instruct emitting a distinct rollout-chain finding in analyze's standard
  findings table reporting that the Delivery Strategy is present but no
  rollout tasks exist, and this finding MUST be distinguishable in wording
  from the FR-005 finding.
- **FR-008**: If the marker, the Delivery Strategy section, and at least one
  traceable rollout task are all present, the briefing MUST instruct
  reporting the rollout chain as consistent and MUST NOT emit any gap or
  orphan finding for rollout content.
- **FR-009**: Both rollout-chain break findings (FR-005, FR-007) MUST be
  instructed to carry a severity consistent with analyze's existing
  heuristic for lineage and coverage breaks (HIGH), since a broken rollout
  chain is a Constitution Principle III (Strict Content Lineage) concern,
  not a cosmetic one.
- **FR-010**: The briefing's instructions MUST be strictly report-only —
  MUST NOT instruct editing `spec.md`, `plan.md`, or `tasks.md` to fix any
  detected gap; remediation remains an explicit, separate follow-up action
  by the user, consistent with `/speckit.analyze`'s existing read-only
  operating constraint.
- **FR-011**: The briefing MUST NOT introduce any new required artifact or
  section beyond the three already established by prior features (the
  Delivery Considerations marker, the Delivery Strategy section, and
  rollout tasks) — it validates the existing chain, it does not define new
  chain elements.

### Key Entities

- **Rollout chain**: The three-link sequence — `spec.md`'s Delivery
  Considerations marker, `plan.md`'s Delivery Strategy section, and
  `tasks.md`'s rollout tasks — whose end-to-end consistency this briefing
  validates during `/speckit.analyze`.
- **Rollout-chain finding**: A distinct entry in analyze's standard
  findings table reporting a specific, named break in the rollout chain
  (marker-to-plan or plan-to-tasks), emitted only when that break actually
  exists.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a feature with a complete, consistent rollout chain
  (marker, Delivery Strategy, and at least one traceable rollout task all
  present), an `/speckit.analyze` run reports zero orphan, coverage-gap,
  duplication, or ambiguity findings referencing any rollout-related
  content.
- **SC-002**: For a feature with no Delivery Considerations marker, an
  `/speckit.analyze` run's rollout-specific output is a single line, and
  every other part of the report is unaffected by the rollout briefing.
- **SC-003**: For a feature with a marker but no Delivery Strategy section,
  an `/speckit.analyze` run reports exactly one rollout-chain finding
  describing that specific break, and the marker itself is not separately
  reported as orphaned.
- **SC-004**: For a feature with a Delivery Strategy section but no rollout
  tasks, an `/speckit.analyze` run reports exactly one rollout-chain
  finding describing that specific break, worded distinguishably from the
  SC-003 finding.
- **SC-005**: Across repeated `/speckit.analyze` runs on an unchanged
  feature, rollout-chain finding wording and count remain identical
  (deterministic), matching analyze's existing determinism guarantee.

## Assumptions

- The shared gate script's default mode (`spec.md` only, Feature 003)
  remains sufficient for the initial marker check; this briefing adds its
  own direct reads of `plan.md` and `tasks.md` for the two additional chain
  links, consistent with the two-stage gating pattern established in
  Feature 007.
- The `## Delivery Strategy` heading convention (Feature 006) and the six
  rollout task categories (Feature 007) are the reference shapes this
  briefing matches against; it does not redefine either.
- Per-flag chain verification (confirming each individual candidate flag
  has its own complete chain) is a secondary concern not required for this
  feature; feature-level presence/absence is sufficient to satisfy the
  stated acceptance criteria.
- `commands/brief-analyze.md`'s existing placeholder frontmatter and body
  will be replaced with active doctrine content, mirroring the pattern
  established by Features 004-007.
