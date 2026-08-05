# Feature Specification: Rollout Detection Doctrine (Pre-Specify Briefing)

**Feature Branch**: `[004-rollout-detection-doctrine]`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Read docs/foundation/vision.md first (sections 4, 5.1, 5.2). Specify commands/brief-specify.md, run automatically by the before_specify hook. Requirements: Provide the progressive-delivery DETECTION doctrine: heuristics for when a feature is a rollout candidate (high-risk/irreversible changes, major UX changes, progressive migrations, cohort language: beta/internal/canary/percentage/country/region, performance/infra-sensitive changes). Instruct the agent: when signals exist, write the \"## Delivery Considerations\" marker into spec.md (candidate flag name + rollout intent), using the exact convention from Feature 3 so the gate scripts recognize it. Do NOT name a provider at this stage. Detection is advisory: propose and explain when applicable; ask a single clarifying question on ambiguity; the user may decline. Keep the briefing lightweight; if no signals are detected, add no rollout content. Acceptance criteria: A high-risk feature spec gains a recognizable Delivery Considerations marker; a trivial feature does not. The marker matches the gate-script convention (verified against Feature 3). No provider-specific content appears in the spec. Out of scope: plan/tasks content, provider interaction."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Detect a rollout candidate and record intent (Priority: P1)

A developer runs `/speckit.specify` describing a feature with clear
delivery-risk signals (e.g., "roll out the new checkout flow to 5% of
production traffic first, then expand by country"). The agent, briefed by the
pre-specify doctrine, recognizes the cohort language and progressive-rollout
intent, proposes a candidate flag name, and records both the flag name and
the rollout intent in a `## Delivery Considerations` section of the generated
`spec.md`.

**Why this priority**: This is the entry point of the entire rollout chain
(vision.md §4-5.1). If detection and marker-writing do not work at the
specify phase, no downstream phase (clarify, plan, tasks, implement) ever
receives rollout signal, and the whole extension is inert.

**Independent Test**: Run `/speckit.specify` with a feature description that
contains unambiguous high-risk or cohort language, and confirm the resulting
`spec.md` contains a `## Delivery Considerations` section naming a candidate
flag and describing rollout intent, with no feature-flag provider named
anywhere in the file.

**Acceptance Scenarios**:

1. **Given** a feature description naming an irreversible or high-risk change
   (e.g., a payments or auth migration), **When** `/speckit.specify` runs,
   **Then** the generated `spec.md` contains a `## Delivery Considerations`
   section with a candidate flag name and a rollout-intent statement.
2. **Given** a feature description using explicit cohort language (beta,
   internal, canary, a percentage, a country/region), **When**
   `/speckit.specify` runs, **Then** the same marker section is added.
3. **Given** the marker has been written, **When** `scripts/bash/rollout-gate.sh`
   (or `rollout-gate.ps1`) is run against that feature's directory, **Then**
   it reports `hasFlags=true` and returns the candidate flag name(s), per the
   Feature 003 gate-script contract.
4. **Given** the marker has been written, **When** the spec is reviewed,
   **Then** no feature-flag provider name (e.g., "LaunchDarkly") appears
   anywhere in the document.

---

### User Story 2 - Leave a trivial feature spec untouched (Priority: P1)

A developer runs `/speckit.specify` describing a low-risk, everyday feature
with no delivery-risk or cohort signals (e.g., "fix a typo in the footer
copyright text"). The agent's briefing keeps the specify flow exactly as it
would run without the `rollout` extension installed: no rollout section, no
extra questions, no visible overhead.

**Why this priority**: Equal priority to Story 1 — this is the "near-zero
context pollution for the common case" promise from vision.md §5.1/§5.2. A
detection doctrine that over-triggers is as harmful as one that never fires.

**Independent Test**: Run `/speckit.specify` with a feature description that
contains none of the documented heuristics, and confirm the resulting
`spec.md` contains no `## Delivery Considerations` section and no other
rollout-related content.

**Acceptance Scenarios**:

1. **Given** a feature description with no high-risk, UX-migration,
   cohort, or performance/infra signals, **When** `/speckit.specify` runs,
   **Then** the generated `spec.md` contains no `## Delivery Considerations`
   section.
2. **Given** the same trivial feature, **When**
   `scripts/bash/rollout-gate.sh` is run against its feature directory,
   **Then** it reports `hasFlags=false`.

---

### User Story 3 - Ask one clarifying question on ambiguous signals (Priority: P2)

A developer describes a feature whose language is ambiguous with respect to
rollout candidacy (e.g., mentions "internal" in a way that could mean an
internal-only cohort or could simply mean "internal tooling," with no other
risk signal). The agent asks exactly one targeted clarifying question about
rollout intent, then proceeds according to the answer — writing the marker
only if the answer confirms rollout intent.

**Why this priority**: Depends on Stories 1 and 2's detection logic already
distinguishing clear matches from clear non-matches; this covers the residual
ambiguous middle ground called out as advisory in vision.md §4.

**Independent Test**: Run `/speckit.specify` with a deliberately ambiguous
feature description and confirm the agent asks exactly one rollout-related
clarifying question (not zero, not several), and that the final `spec.md`
reflects the user's answer (marker present only if the answer indicates
rollout intent).

**Acceptance Scenarios**:

1. **Given** an ambiguous feature description, **When** `/speckit.specify`
   runs, **Then** the agent asks exactly one clarifying question about
   rollout intent before finalizing the spec.
2. **Given** the user's answer confirms rollout intent, **When** the spec is
   finalized, **Then** it contains the `## Delivery Considerations` marker.
3. **Given** the user's answer denies or declines rollout intent, **When**
   the spec is finalized, **Then** it contains no rollout-related content.

---

### User Story 4 - User declines a proposed rollout framing (Priority: P3)

A developer describes a feature that clearly matches one or more detection
heuristics, but when the agent proposes the rollout framing, the developer
explicitly declines it (e.g., "no, this doesn't need a flag"). The agent
respects that choice and does not write the marker.

**Why this priority**: Reinforces that detection is advisory, never a
mandate (vision.md §4) — a lower-priority but necessary guardrail on top of
Stories 1-3.

**Independent Test**: Run `/speckit.specify` with a feature description that
matches detection heuristics, explicitly decline the agent's proposed rollout
framing, and confirm the resulting `spec.md` contains no `## Delivery
Considerations` section.

**Acceptance Scenarios**:

1. **Given** a feature matches one or more detection heuristics, **When** the
   agent proposes rollout framing and the user declines, **Then** the
   generated `spec.md` contains no `## Delivery Considerations` section and
   no other rollout-related content.

### Edge Cases

- What happens when a feature description contains a cohort-sounding word
  (e.g., "internal") in an unrelated sense, with no other risk signal? The
  doctrine must instruct weighing combined signals and, in a genuinely
  ambiguous case, ask the single clarifying question rather than firing on
  one keyword alone.
- What happens when a feature description matches multiple heuristic
  categories at once (e.g., both "high-risk" and explicit "percentage
  rollout" language)? The agent still writes exactly one `## Delivery
  Considerations` section (not one per matched heuristic), naming one or
  more candidate flags as appropriate.
- What happens when the user's feature description already names a
  feature-flag provider (e.g., mentions "LaunchDarkly" directly)? The
  briefing still instructs the agent not to carry a provider name into the
  spec's `## Delivery Considerations` section, deferring provider naming to
  the plan phase (vision.md §5.1).
- What happens when a feature is ambiguous and the developer does not answer
  the single clarifying question (e.g., ignores it or the flow proceeds
  without a reply)? The agent MUST default to not writing the marker,
  consistent with detection being advisory and opt-in rather than opt-out.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pre-specify briefing content (`commands/brief-specify.md`)
  MUST present a set of detection heuristics the agent uses to judge whether
  a feature is a progressive-delivery ("rollout") candidate, explicitly
  covering: high-risk or irreversible changes (e.g., payments, authentication,
  data migrations); major user-experience changes; progressive/staged
  migrations; explicit cohort or audience language (beta, internal, canary, a
  percentage, a country/region); and performance- or infrastructure-sensitive
  changes.
- **FR-002**: When the agent judges that a feature description matches one or
  more of the detection heuristics in FR-001, the briefing content MUST
  instruct it to propose adding a `## Delivery Considerations` section to the
  feature's `spec.md`, explaining why the feature appears to be a rollout
  candidate.
- **FR-003**: The `## Delivery Considerations` section the agent writes MUST
  contain at least one candidate flag name and a rollout-intent statement,
  and MUST use the exact heading text and the exact "Candidate flag(s):"
  label already defined and consumed by the Feature 003 gate-script contract
  (`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` and
  `scripts/bash/rollout-gate.sh` / `scripts/powershell/rollout-gate.ps1`), so
  that running the gate script against the feature deterministically reports
  `hasFlags=true` with the candidate flag name(s).
- **FR-004**: The briefing content MUST instruct the agent not to name any
  specific feature-flag provider (e.g., LaunchDarkly) anywhere in the spec at
  the specify phase; provider naming is reserved for the plan phase per
  vision.md §5.1.
- **FR-005**: When no detection heuristic from FR-001 is matched, the
  briefing content MUST instruct the agent to add no rollout-related content
  of any kind to the spec, and to add no visible overhead to the specify flow
  beyond what the hook mechanism itself already contributes.
- **FR-006**: The briefing content MUST frame detection as advisory: on a
  match, the agent proposes the rollout framing and briefly explains why,
  rather than silently or unconditionally inserting the marker.
- **FR-007**: When signals are ambiguous (do not clearly match or clearly
  fail to match the heuristics in FR-001), the briefing content MUST instruct
  the agent to ask exactly one clarifying question about rollout intent
  before finalizing the spec, rather than asking multiple questions or
  proceeding without asking.
- **FR-008**: The briefing content MUST make explicit that the user may
  decline a proposed rollout framing (whether proposed directly on a clear
  match, or after the single clarifying question), and that on decline (or on
  no answer to the clarifying question) the agent MUST NOT write the marker.
- **FR-009**: The `commands/brief-specify.md` content MUST remain scoped to
  specify-phase detection doctrine only: it MUST NOT include plan-phase or
  tasks-phase content (e.g., `Delivery Strategy` structure, rollout task
  lists) and MUST NOT include instructions for interacting with any
  feature-flag provider or its MCP server.
- **FR-010**: The briefing content MUST replace the current placeholder body
  of `commands/brief-specify.md` (which only announces itself as a
  placeholder) with the full doctrine described by FR-001 through FR-009.

### Key Entities

- **Detection Heuristic Set**: The named categories of signal the agent
  checks a feature description against — high-risk/irreversible change,
  major UX change, progressive/staged migration, explicit cohort/audience
  language, performance/infrastructure sensitivity. Lives only as briefing
  content; not a data structure the system stores.
- **Delivery Considerations Marker**: The `## Delivery Considerations`
  section written into a feature's `spec.md`, containing one or more
  candidate flag names (via a "Candidate flag(s):" line) and a rollout-intent
  statement. Its exact shape is defined by the Feature 003 gate-script
  contract and consumed downstream by every other rollout hook.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a feature description containing unambiguous high-risk or
  cohort-language signals, a reviewer can open the resulting `spec.md` and
  find a `## Delivery Considerations` section naming a candidate flag and
  stating rollout intent, without consulting any other document.
- **SC-002**: For a feature description containing none of the documented
  signals, a reviewer finds no rollout-related content anywhere in the
  resulting `spec.md`.
- **SC-003**: Running the Feature 003 gate script against a spec produced
  under this doctrine reports `hasFlags=true` with the correct candidate
  flag name(s) for a signal-matching feature, and `hasFlags=false` for a
  signal-free feature — confirming the marker convention matches exactly.
- **SC-004**: No feature-flag provider name appears in any `spec.md` produced
  under this doctrine, in 100% of reviewed cases.
- **SC-005**: When signals are ambiguous, the developer is asked exactly one
  rollout-related clarifying question — never zero and never more than one —
  before the spec is finalized.

## Assumptions

- This feature's scope is limited to authoring the content of
  `commands/brief-specify.md` (replacing its current placeholder body). It
  does not modify `extension.yml`, the gate scripts, or any other
  `brief-*.md` command.
- The single clarifying question, when needed, is asked directly to the
  developer through the normal interactive flow already used by
  `/speckit.specify` — no separate mechanism is introduced.
- A "candidate flag name" is a short, descriptive identifier the agent
  proposes based on the feature (e.g., `checkout_v2`); the developer may
  adjust it, and multiple candidate flags may be listed when a feature
  clearly implies more than one, consistent with the comma-separated
  `flags` output already supported by the Feature 003 gate-script contract.
- Detection heuristics apply only at the specify phase. Preserving the
  marker and eliciting further rollout parameters (phases, audience,
  percentage, telemetry, rollback) at later phases is the responsibility of
  separate features (`before_clarify`, `before_plan`, etc., per vision.md
  §5.1) and is out of scope here.
- The seven-hook wiring (`extension.yml`, `hooks.before_specify`) already
  exists and already targets `commands/brief-specify.md`; this feature only
  changes what that file instructs the agent to do, not how or when it is
  invoked.
