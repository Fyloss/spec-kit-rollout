# Data Model: Rollout Section Template

**Feature**: 012-rollout-section-template | **Date**: 2026-07-08

This feature has no runtime data, database, or config schema — it delivers a
single static Markdown file. This document captures the two conceptual
entities from spec.md's Key Entities section as structural shapes (field
sets), not as data records.

## Entity: Delivery Strategy Template

The structural content file itself, at `templates/rollout-section.md`.

| Field | Description | Source |
|-------|-------------|--------|
| Optionality statement | Explicit text stating the file is an optional structural reference, not a required artifact or validation schema | FR-003 |
| Feature flag | Labeled placeholder for the flag name | vision.md §9, FR-002 |
| Provider | Labeled placeholder for the provider (worked example: `LaunchDarkly`, per vision.md §9 and Feature 006 precedent) | vision.md §9, FR-002 |
| Rollout (phased) | Labeled placeholder for multiple ordered stages (`Phase 1`, `Phase 2`, ... `Phase N`) | vision.md §9, FR-002 |
| Targeting | Labeled placeholder for audience/segment targeting rules | vision.md §9, FR-002 |
| Telemetry gates | Labeled placeholder for quantitative/qualitative health gates | vision.md §9, FR-002 |
| Rollback conditions | Labeled placeholder for auto-rollback trigger conditions | vision.md §9, FR-002 |
| Guidance text | Explanatory prose for each element so a reader unfamiliar with the extension can fill it in unaided | FR-002/FR-003, spec.md SC-004 |

**Validation rules** (all enforced by human/agent review, not tooling, per
research.md Decision 4):
- All six labeled elements MUST be present, in the vision.md §9 order.
- The file MUST NOT reference or imply a standalone `rollout.md` artifact
  (FR-006).
- The file MUST contain no executable logic and no gate-script dependency
  (FR-007).
- The file MUST NOT contain a token, secret, or credential-shaped value
  (Constitution Principle V).

**State transitions**: None — this is a static reference file with no
lifecycle states.

## Entity: Delivery Strategy Section

The actual `## Delivery Strategy` content produced inside a feature's
`plan.md` by `commands/brief-plan.md` (Feature 006), either shaped with this
template as a reference (when present) or produced directly from Feature
006's own doctrine (when absent).

| Field | Description | Source |
|-------|-------------|--------|
| Feature flag | Real flag name derived from spec.md/marker content | Feature 006 doctrine |
| Provider | `Provider: LaunchDarkly` | Feature 006 doctrine |
| Rollout (phased) | Ordered `Phase N:` lines with real stage descriptions | Feature 006 doctrine |
| Targeting | Real targeting rule(s) | Feature 006 doctrine |
| Telemetry gates | Real quantitative/qualitative gate(s) | Feature 006 doctrine |
| Rollback conditions | Real rollback trigger(s) | Feature 006 doctrine |

**Invariant** (spec.md Key Entities): The two paths — templated reference
present vs. absent — MUST be structurally indistinguishable to a reader.
This invariant is owned and already satisfied by Feature 006's independent
doctrine (verified during Phase 0 research read of `commands/brief-plan.md`);
this feature does not implement or re-verify Feature 006's own logic, only
ensures the optional file it may reference exists and matches the same
field set.

**Relationship**: Delivery Strategy Template (optional, static, this
feature) → *may inform, never gates* → Delivery Strategy Section (real
content, produced by Feature 006, every plan run). This is a one-directional,
optional advisory relationship, not a data dependency — there is no
programmatic link between the two files.
