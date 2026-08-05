# Feature Specification: Rollout Section Template

**Feature Branch**: `012-rollout-section-template`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "Specify templates/rollout-section.md — an OPTIONAL structural template for the Delivery Strategy block. Requirements: Provide a reusable structure: feature flag, provider, phased rollout, targeting, telemetry gates, rollback conditions (matching the vision example). It must be optional: brief-plan (Feature 6) may reference it for consistency but must never require it, and its absence must not break the plan phase."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Delivery Strategy structure when the template is present (Priority: P1)

A tech lead wants every plan.md's `## Delivery Strategy` section to follow the
same field order and shape across features, regardless of who runs
`/speckit.plan` or when. With `templates/rollout-section.md` present in the
extension, the plan briefing produces a Delivery Strategy section that
consistently follows this reusable structure.

**Why this priority**: This is the entire value proposition of the template —
without consistent structure to reference, there's no reason for the file to
exist. It's the primary, most-visible benefit.

**Independent Test**: Can be fully tested by placing `templates/rollout-section.md`
in the extension, running `/speckit.plan` on a feature with rollout intent
present, and confirming the resulting `## Delivery Strategy` section in
plan.md contains the same fields, in the same order, as the template.

**Acceptance Scenarios**:

1. **Given** `templates/rollout-section.md` exists in the extension and a
   feature's spec.md carries a `Delivery Considerations` marker, **When**
   `/speckit.plan` runs, **Then** the generated `## Delivery Strategy` section
   in plan.md contains feature flag, provider, phased rollout stages,
   targeting, telemetry gates, and rollback conditions in the structure the
   template defines.
2. **Given** the template is present, **When** two different features each
   run `/speckit.plan` with rollout intent, **Then** both features' Delivery
   Strategy sections share the same field order and labels (structural
   consistency across features).

---

### User Story 2 - Plan phase is unaffected when the template is absent (Priority: P1)

A maintainer removes or has never installed `templates/rollout-section.md`
(it's optional and not part of every install). The plan phase must still
complete normally and still produce a fully-formed Delivery Strategy section
when rollout intent is present, using the doctrine already built into the
plan briefing.

**Why this priority**: This is the hard constraint from the vision and the
acceptance criteria — an optional file must never become a silent hard
dependency. Equal priority to Story 1 because failing this would make the
"optional" claim false.

**Independent Test**: Can be fully tested by deleting or renaming
`templates/rollout-section.md`, running `/speckit.plan` on a feature with
rollout intent present, and confirming plan.md still gets a complete
`## Delivery Strategy` section with no errors, warnings, or missing-file
messages surfaced to the user.

**Acceptance Scenarios**:

1. **Given** `templates/rollout-section.md` does not exist, **When**
   `/speckit.plan` runs on a feature with rollout intent, **Then** the plan
   phase completes successfully and plan.md still contains a complete
   `## Delivery Strategy` section with all required elements.
2. **Given** `templates/rollout-section.md` does not exist, **When**
   `/speckit.plan` runs on a feature with no rollout intent, **Then** the
   plan phase completes exactly as it would if the template existed (no
   behavior difference either way for non-rollout features).

---

### User Story 3 - Maintainer reviews or adapts the template structure (Priority: P2)

A maintainer opens `templates/rollout-section.md` to review or lightly adapt
the field set (e.g., add an org-specific note) while keeping it recognizable
as the same reusable structure referenced by the plan briefing.

**Why this priority**: Valuable for long-term maintainability and team
customization, but not required for the template to deliver its core value on
day one.

**Independent Test**: Can be fully tested by opening the file and confirming a
reader unfamiliar with the extension can identify all six required elements
(flag, provider, phased rollout, targeting, telemetry gates, rollback) and
understand how to fill each one in, without consulting any other document.

**Acceptance Scenarios**:

1. **Given** the template file, **When** a maintainer reads it, **Then** each
   of the six required elements is labeled and its purpose is clear from the
   template content alone.
2. **Given** a maintainer adds an extra, org-specific field to their local
   copy, **When** the plan briefing references the template for structural
   consistency, **Then** the six required elements remain present and
   correctly structured (the template tolerates additive customization).

---

### Edge Cases

- What happens when `templates/rollout-section.md` exists but is empty or
  malformed? The plan briefing does not depend on parsing the file
  programmatically (it's a human/agent-readable reference, not a schema), so
  a malformed file cannot block the plan phase — worst case, the resulting
  Delivery Strategy section simply doesn't benefit from the reference.
- What happens when the template's placeholder tokens (e.g., a literal flag
  name placeholder) are copied verbatim into plan.md without being filled in?
  Ensuring placeholders are replaced with real values is the responsibility
  of the plan briefing doctrine (Feature 006), not this template file.
- How does the system handle a project that has never installed the
  `templates/` directory at all? Identical to the file being absent — no
  different code path, no different outcome.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extension MUST provide a template file at
  `templates/rollout-section.md` describing a reusable structure for the
  `## Delivery Strategy` block.
- **FR-002**: The template MUST define, at minimum, the following elements in
  the structure and order shown in vision.md §9: feature flag name, provider,
  phased rollout (multiple ordered stages), targeting, telemetry gates, and
  rollback conditions.
- **FR-003**: The template MUST be explicitly documented as optional within
  its own content, making clear it is a structural reference, not a required
  artifact or a validation schema.
- **FR-004**: The plan briefing (`commands/brief-plan.md`, Feature 006) MAY
  reference this template for structural consistency but MUST NOT require
  its presence to produce a `## Delivery Strategy` section.
- **FR-005**: The absence of `templates/rollout-section.md` MUST NOT cause the
  plan phase to fail, warn, or produce an incomplete Delivery Strategy
  section — the plan briefing's own doctrine (Feature 006) remains fully
  capable of producing the complete structure independent of this file.
- **FR-006**: The template MUST NOT imply that a standalone `rollout.md`
  artifact is required or expected; it structures content that lives inside
  `plan.md` only, consistent with V1 scope.
- **FR-007**: The template MUST be static content only (no executable logic,
  no gate-script dependency, no changes to `extension.yml` commands or hooks).
- **FR-008**: Removing or deleting `templates/rollout-section.md` MUST NOT
  change the pass/fail outcome of any other feature's existing quickstart or
  acceptance validation in this repository.

### Key Entities *(include if feature involves data)*

- **Delivery Strategy Template**: The structural content file itself
  (`templates/rollout-section.md`) — defines labeled placeholders for the six
  required elements, with guidance text explaining its optional status.
- **Delivery Strategy Section**: The actual `## Delivery Strategy` content
  produced inside a feature's `plan.md`, either shaped by this template (when
  present) or produced directly by the plan briefing's own doctrine (when
  absent) — the two paths must be structurally indistinguishable to a reader.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When `templates/rollout-section.md` is present, 100% of
  reviewed Delivery Strategy sections produced by the plan phase contain all
  six required elements (flag, provider, phased rollout, targeting, telemetry
  gates, rollback) in the template's field order.
- **SC-002**: When `templates/rollout-section.md` is absent, the plan phase
  completes with zero errors or blocking incidents attributable to the
  missing file, across all rollout and non-rollout feature scenarios tested.
- **SC-003**: Removing the template file changes zero prior features' existing
  quickstart or acceptance results (verified by re-running the affected
  checks with the file absent).
- **SC-004**: A reader unfamiliar with the extension can identify all six
  required elements directly from the template's own content, without
  consulting any other document.

## Assumptions

- `commands/brief-plan.md` (Feature 006) already contains doctrine sufficient
  to produce a complete Delivery Strategy section independent of this
  template; this feature only adds an optional structural reference file and
  does not change Feature 006's core requirement to work without it.
- The template is authored in Markdown, consistent with other template and
  command files in this extension.
- No automated schema validation of the template's shape is required in V1
  (per vision.md, this is a reference structure, not a linted contract).
- The template lives at repository-root `templates/rollout-section.md` per
  the extension layout in vision.md §12, distinct from Spec Kit's own
  `.specify/templates/` directory.
