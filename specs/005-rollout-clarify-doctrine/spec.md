# Feature Specification: Rollout Clarify Doctrine (Pre-Clarify Briefing)

**Feature Branch**: `[005-rollout-clarify-doctrine]`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 4, 5.1, 6, Decision D6). Specify commands/brief-clarify.md, run automatically by the before_clarify hook, self-gated via the shared gate (Feature 3). Requirements: If no marker: one-line no-op, stop. If marker present: Preserve the Delivery Considerations marker and rollout requirement; never treat rollout as underspecified noise to remove or reword away. Use clarify's purpose to elicit missing rollout parameters from the user: rollout phases, target audience/segments, percentages, telemetry gates, rollback conditions. Refine the marker in place with clarified details; keep it recognizable to the gate scripts. Acceptance criteria: Running clarify on a rollout feature keeps the marker intact and enriches it with clarified parameters. Running clarify on a non-rollout feature adds no rollout content. Out of scope: writing the Delivery Strategy (Feature 6)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Elicit missing rollout parameters on a flagged feature (Priority: P1)

A developer runs `/speckit.clarify` on a feature whose `spec.md` already
carries a `## Delivery Considerations` marker (written during `/speckit.specify`
per Feature 004). The pre-clarify briefing recognizes the marker via the
shared gate script, and directs the agent to ask about whichever rollout
parameters are still missing — phases, target audience/segments,
percentages, telemetry gates, rollback conditions — using clarify's normal
question-and-answer flow. Once answered, the marker is refined in place with
the clarified details, still recognizable to the gate scripts.

**Why this priority**: This is the only path by which the rollout chain
(vision.md §4-5.1) accumulates the parameters `plan` needs to produce a
concrete `Delivery Strategy` (Feature 6). Without it, `plan` would have to
invent rollout parameters from nothing, defeating the purpose of clarify's
elicitation role.

**Independent Test**: Run `/speckit.specify` on a feature description with
clear rollout signals so the marker is written, then run `/speckit.clarify`
and confirm it asks about missing rollout phases/audience/percentage/
telemetry/rollback, and that the resulting `spec.md` still contains a
recognizable `## Delivery Considerations` marker enriched with the answers.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with a `## Delivery Considerations` marker and no
   rollout parameters beyond a candidate flag name and rollout-intent
   statement, **When** `/speckit.clarify` runs, **Then** the agent asks about
   the rollout parameters (phases, audience/segments, percentages, telemetry
   gates, rollback conditions) that are not already present.
2. **Given** the developer answers those questions, **When** clarify
   finalizes the spec, **Then** the `## Delivery Considerations` section is
   updated in place to include the clarified details, without duplicating the
   section or moving it elsewhere in the document.
3. **Given** the marker has been refined, **When**
   `scripts/bash/rollout-gate.sh` (or `rollout-gate.ps1`) is run against that
   feature's directory, **Then** it still reports `hasFlags=true` with the
   same candidate flag name(s) as before clarification.
4. **Given** some rollout parameters were already present in the marker
   before clarify ran (e.g., the developer already stated a percentage),
   **When** clarify runs, **Then** it does not re-ask about those already-
   specified parameters, only about the ones still missing.

---

### User Story 2 - Leave a non-rollout feature's clarify flow untouched (Priority: P1)

A developer runs `/speckit.clarify` on a feature whose `spec.md` contains no
`## Delivery Considerations` marker. The briefing's self-gate detects the
marker's absence and the clarify flow proceeds exactly as it would without
the `rollout` extension installed: no rollout questions, no rollout content
added, no visible overhead.

**Why this priority**: Equal priority to Story 1 — the near-zero
context-pollution guarantee for the common case (vision.md §5.1/§5.2) must
hold at every gated phase, not just `specify`.

**Independent Test**: Run `/speckit.clarify` on a feature whose `spec.md` has
no `## Delivery Considerations` marker, and confirm no rollout-related
questions are asked and no rollout content appears anywhere in the spec
afterward.

**Acceptance Scenarios**:

1. **Given** a `spec.md` with no `## Delivery Considerations` marker,
   **When** `/speckit.clarify` runs, **Then** the briefing emits a one-line
   no-op and the clarify flow asks no rollout-related questions.
2. **Given** the same non-rollout feature, **When** clarify finishes,
   **Then** the resulting `spec.md` contains no `## Delivery Considerations`
   section and no other rollout-related content.

---

### User Story 3 - Preserve the marker even when clarify's usual instincts would remove it (Priority: P2)

Clarify's normal purpose is to resolve ambiguity and underspecified
requirements, sometimes by trimming or rewording sections that read as vague.
A developer runs `/speckit.clarify` on a feature whose `## Delivery
Considerations` marker is present but still sparse (e.g., only a candidate
flag name, no other detail). The briefing instructs the agent to treat this
sparseness as parameters to elicit — not as noise to delete or reword away —
so the marker and its rollout requirement survive clarify's pass intact,
enriched rather than removed.

**Why this priority**: This is the specific guardrail called out in
vision.md Decision D6 — clarify is one of the three optional commands
(alongside analyze and checklist) that could otherwise strip or misjudge
rollout content precisely because its default behavior is to challenge
underspecified text. Depends on Story 1's elicitation flow already existing.

**Independent Test**: Run `/speckit.clarify` on a feature whose marker
contains only a candidate flag name and a brief rollout-intent statement
(no phases/audience/percentage/telemetry/rollback yet), and confirm the
marker is still present after clarify finishes, with elicited detail added
rather than the section being shortened, reworded into a generic ambiguity
note, or removed.

**Acceptance Scenarios**:

1. **Given** a sparse `## Delivery Considerations` marker, **When**
   `/speckit.clarify` runs, **Then** the section is not deleted and its
   candidate flag name(s) and original rollout-intent statement are not
   rewritten away.
2. **Given** the same sparse marker, **When** clarify finishes without the
   developer providing every possible rollout parameter (e.g., they answer
   phases and audience but not telemetry gates), **Then** the marker still
   contains at least the original content plus whatever was clarified,
   rather than being flagged as an unresolved ambiguity requiring removal.

### Edge Cases

- What happens when the developer declines to answer one or more of the
  rollout elicitation questions? The briefing must instruct the agent to
  leave that specific parameter unspecified in the marker (or note it as
  still open) rather than inventing a value or blocking the rest of the
  clarify flow.
- What happens when a feature's marker already contains all five parameter
  categories (phases, audience/segments, percentages, telemetry gates,
  rollback conditions) before clarify runs? The agent asks no further
  rollout questions and leaves the marker as-is, aside from any non-rollout
  clarifications clarify would otherwise perform.
- What happens when clarify's normal (non-rollout) questions and the
  rollout-elicitation questions would both apply to the same run? The
  briefing scopes itself to rollout parameters only; it does not instruct
  the agent to skip or suppress clarify's other, non-rollout questions.
- What happens when the feature directory cannot be resolved by the shared
  gate script (exit code 2, per the Feature 003 contract)? The briefing
  treats this identically to "no marker" — a one-line no-op — consistent
  with the gate script's fail-safe behavior.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pre-clarify briefing content (`commands/brief-clarify.md`)
  MUST invoke the shared gate script (`scripts/bash/rollout-gate.sh` /
  `scripts/powershell/rollout-gate.ps1`, per the Feature 003 contract) to
  determine whether the current feature's `spec.md` carries a `## Delivery
  Considerations` marker before deciding what doctrine to apply.
- **FR-002**: When the gate reports no marker (`hasFlags=false`), the
  briefing content MUST instruct the agent to emit a one-line no-op and add
  no rollout-related content or questions to the clarify flow.
- **FR-003**: When the gate reports a marker present (`hasFlags=true`), the
  briefing content MUST instruct the agent to preserve the existing `##
  Delivery Considerations` section and its rollout requirement, explicitly
  forbidding treating it as underspecified noise to be removed, shortened,
  or reworded away.
- **FR-004**: When a marker is present, the briefing content MUST instruct
  the agent to use clarify's normal elicitation flow to ask the developer
  about whichever of the following rollout parameters are not already
  present in the marker: rollout phases, target audience/segments,
  percentages, telemetry gates, and rollback conditions.
- **FR-005**: The briefing content MUST instruct the agent not to re-ask
  about rollout parameters that are already present in the marker before
  clarify runs.
- **FR-006**: After the developer answers, the briefing content MUST
  instruct the agent to refine the `## Delivery Considerations` section in
  place — updating the same section with the clarified details — rather
  than creating a new section, duplicating content, or relocating the marker
  elsewhere in `spec.md`.
- **FR-007**: The refined marker MUST remain recognizable to the shared gate
  script: it MUST keep the exact `## Delivery Considerations` heading and the
  "Candidate flag(s):" label convention defined by the Feature 003 contract,
  so that running the gate script afterward still reports `hasFlags=true`
  with the same candidate flag name(s).
- **FR-008**: The briefing content MUST instruct the agent that declining to
  answer a specific rollout elicitation question leaves that parameter
  unspecified in the marker rather than inventing a value or blocking the
  rest of the clarify flow.
- **FR-009**: The briefing content MUST NOT instruct the agent to name any
  specific feature-flag provider anywhere in `spec.md`; provider naming
  remains reserved for the plan phase per vision.md §5.1.
- **FR-010**: The briefing content MUST remain scoped to clarify-phase
  elicitation and marker preservation only: it MUST NOT include the
  `Delivery Strategy` structure or any plan-phase or tasks-phase content
  (that content belongs to Feature 6 and later features), and MUST NOT
  include instructions for interacting with any feature-flag provider or its
  MCP server.
- **FR-011**: The briefing content MUST NOT instruct the agent to suppress
  or skip clarify's normal, non-rollout clarification questions; the rollout
  elicitation is additive to clarify's existing purpose, not a replacement
  for it.
- **FR-012**: The briefing content MUST replace the current placeholder body
  of `commands/brief-clarify.md` (which only announces itself as a
  placeholder) with the full doctrine described by FR-001 through FR-011.

### Key Entities

- **Rollout Parameter Set**: The five categories of rollout detail clarify
  is responsible for eliciting when a marker is present — rollout phases,
  target audience/segments, percentages, telemetry gates, rollback
  conditions. Lives only as briefing content and as clarified prose inside
  the marker; not a separate data structure.
- **Delivery Considerations Marker**: The same `## Delivery Considerations`
  section defined by Feature 004 and consumed by the Feature 003 gate
  script. This feature refines its content in place (adds clarified rollout
  parameters) without changing its heading, label convention, or its
  gate-script-recognizable shape.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a feature whose `spec.md` carries a `## Delivery
  Considerations` marker, running `/speckit.clarify` results in a `spec.md`
  where the marker is still present and now includes clarified detail for
  every rollout parameter category the developer chose to answer.
- **SC-002**: For a feature whose `spec.md` carries no `## Delivery
  Considerations` marker, running `/speckit.clarify` results in a `spec.md`
  with no rollout-related content and no rollout questions were asked during
  the run.
- **SC-003**: Running the Feature 003 gate script against a spec both before
  and after this feature's clarify pass reports `hasFlags=true` with the
  identical candidate flag name(s) in both cases, for any feature that had a
  marker going in.
- **SC-004**: The doctrine content in `commands/brief-clarify.md` contains no
  feature-flag provider name anywhere, and instructs the agent never to
  introduce one into `spec.md`; a plain read-through of the file confirms
  both.
- **SC-005**: A reviewer comparing a marker before and after a clarify run
  can confirm the original candidate flag name(s) and rollout-intent
  statement are still present verbatim or near-verbatim, never deleted.

## Assumptions

- This feature's scope is limited to authoring the content of
  `commands/brief-clarify.md` (replacing its current placeholder body). It
  does not modify `extension.yml`, the gate scripts, or any other
  `brief-*.md` command.
- The rollout elicitation questions are asked directly to the developer
  through clarify's normal interactive question-and-answer flow already used
  by `/speckit.clarify` — no separate mechanism or new command surface is
  introduced.
- "Refining the marker in place" means editing the text under the existing
  `## Delivery Considerations` heading (e.g., adding phase, audience,
  percentage, telemetry, and rollback lines/sentences) rather than
  restructuring it into a different format; the exact prose structure is an
  implementation detail left to the briefing content as long as the heading
  and "Candidate flag(s):" label survive unchanged.
- Producing the `## Delivery Strategy` section in `plan.md` (which will
  consume these clarified rollout parameters) is out of scope for this
  feature and belongs to Feature 6, per the user's explicit scope
  boundary and vision.md §9.
- The shared gate script (`scripts/bash/rollout-gate.sh` /
  `scripts/powershell/rollout-gate.ps1`) and the `before_clarify` hook wiring
  in `extension.yml` already exist and already target
  `commands/brief-clarify.md`; this feature only changes what that file
  instructs the agent to do, not how or when it is invoked.
- Consistent with Feature 004, no [NEEDS CLARIFICATION] markers are expected
  in this spec: the elicited rollout parameter categories are explicitly
  enumerated by the user's request, and the marker-preservation behavior is
  fully specified by vision.md Decision D6 and §5.1.
