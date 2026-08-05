---
description: "rollout: pre-clarify briefing"
---

# `speckit.rollout.brief-clarify`

**Role**: Inject pre-clarify doctrine before `/speckit.clarify` runs. This
briefing tells the agent how to treat a feature's `## Delivery Considerations`
marker (written by the `before_specify` briefing, Feature 004) during the
clarify pass: preserve it, elicit whichever rollout parameters are still
missing, and refine it in place — never treating it as underspecified noise
to be removed or reworded away.

**Scope boundary**: This file covers **clarify-phase elicitation and marker
preservation only**. It MUST NOT include `## Delivery Strategy` content, or
any plan-phase or tasks-phase content, or instructions for interacting with a
feature-flag provider or its MCP server — those belong to the `before_plan`,
`before_tasks`, and `before_implement` briefings (see
`docs/foundation/vision.md` §5.1). It MUST NOT name any specific feature-flag
provider anywhere in its output.

## Determine whether this feature is a rollout candidate

Before doing anything else, invoke the shared gate script to determine
whether the current feature's `spec.md` carries a `## Delivery Considerations`
marker:

```bash
scripts/bash/rollout-gate.sh
```

```powershell
scripts/powershell/rollout-gate.ps1
```

- Exit code `0` (`hasFlags=true`): a marker is present and hooks are enabled
  — proceed to "When a marker is present" below.
- Exit code `1` (`hasFlags=false`): no marker, or hooks disabled — proceed to
  "When no marker is present" below.
- Exit code `2` (feature directory could not be resolved): treat identically
  to exit code `1` — proceed to "When no marker is present" below.

## When no marker is present

Emit a single, one-line acknowledgment that no rollout considerations apply
(for example: "No `Delivery Considerations` marker found; proceeding with
normal clarify flow.") and add **no** other rollout-related content or
questions to the clarify flow. The resulting clarify session should look
exactly as it would if the `rollout` extension were not installed.

## When a marker is present: preserve it — never treat it as noise to remove

Before eliciting anything, internalize this rule: the `## Delivery
Considerations` section and its rollout requirement — however sparse — MUST
NOT be treated as underspecified ambiguity to be removed, shortened, or
reworded into a generic ambiguity note. Clarify's normal instinct to
challenge underspecified text does not apply to this section, whether it is
already detailed or still sparse.

## Rollout Parameter Set

When a marker is present, elicit whichever of the following five categories
are not already specified in the marker:

| Category | Elicited detail |
|---|---|
| Rollout phases | Staged sequence of the rollout (e.g., internal → beta → GA) |
| Target audience/segments | Who receives the change first/next (e.g., internal users, a named cohort, a region) |
| Percentages | Traffic or user percentage at each phase |
| Telemetry gates | Metrics/signals that must hold before advancing a phase |
| Rollback conditions | Conditions that trigger reverting the rollout |

## Elicit missing parameters

Ask about whichever Rollout Parameter Set categories are not already present
in the marker, using clarify's normal interactive question-and-answer flow —
no new mechanism is introduced. Do not re-ask about a category already
present in the marker; if all five categories are already present, ask no
further rollout questions. These questions are additive: continue asking
clarify's other, normal non-rollout questions as usual — never suppress or
skip them because rollout questions are being asked.

## Handle declines

If the developer declines to answer a specific rollout elicitation question,
leave that parameter unspecified in the marker (or note it as still open).
Never invent a value for a declined parameter, and never block or pause the
rest of the clarify flow — including its other non-rollout questions —
because of a decline.

## Refine the marker in place

After answers are given, update the `## Delivery Considerations` section in
place with the clarified details:

- Keep the heading line exactly `## Delivery Considerations`, unchanged.
- Keep the `Candidate flag(s):` line and its value unchanged.
- Keep the original rollout-intent statement, verbatim or near-verbatim.
- Add the newly clarified detail as additional prose within the same
  section.

Never create a new section, duplicate the marker, or relocate it elsewhere in
`spec.md`. There must be exactly one `## Delivery Considerations` section in
the resulting `spec.md`.

## Sparse markers are elicitation targets, not ambiguity

A marker containing only a candidate flag name and a brief rollout-intent
statement — with none of the five Rollout Parameter Set categories filled in
yet — is not unresolved ambiguity requiring removal, shortening, or generic
rewording. It is simply a set of elicitation targets: ask about the missing
categories as described above, and refine the section in place with whatever
the developer answers. A partial answer (e.g., phases and audience answered,
telemetry gates declined) still leaves the section intact — enriched with
the new detail, with the still-unanswered categories left unspecified rather
than invented or treated as a reason to flag the section as ambiguous.
