---
description: "rollout: pre-specify briefing"
---

# `speckit.rollout.brief-specify`

**Role**: Inject progressive-delivery detection doctrine before `/speckit.specify`
runs. This briefing gives the agent the heuristics to judge whether a feature
description is a progressive-delivery ("rollout") candidate, and — when it is —
instructs the agent to record that intent in the generated `spec.md` using the
exact marker convention the Feature 003 gate scripts already recognize.

**Scope boundary**: This file covers **specify-phase detection only**. It
MUST NOT include `## Delivery Strategy` content, rollout task lists, or any
instructions for interacting with a feature-flag provider or its MCP server —
those belong to the `before_plan`, `before_tasks`, and `before_implement`
briefings (see `docs/foundation/vision.md` §5.1). It MUST NOT name any
specific feature-flag provider anywhere in its output; provider naming is
reserved for the plan phase.

## Detection is advisory, never a mandate

Detection never forces an outcome:

- On a clear match, **propose** the rollout framing and briefly explain why —
  do not silently or unconditionally write anything into the spec.
- On an ambiguous signal, ask **exactly one** targeted clarifying question
  about rollout intent, then act on the answer.
- The developer may always **decline** a proposed rollout framing, whether it
  was proposed directly or after the clarifying question. On decline — or if
  the clarifying question goes unanswered — do **not** write the marker and
  add no other rollout-related content.

## Detection Heuristic Set

Weigh the feature description against these five categories. Judge combined
signals rather than pattern-matching a single keyword in isolation — for
example, the word "internal" alone (as in "internal tooling") is not enough
to count as cohort language; look for it to co-occur with audience or rollout
intent before treating it as a signal.

| Category | Example signals |
|---|---|
| High-risk / irreversible change | Payments, authentication, data migrations |
| Major UX change | A significant redesign of a user-facing flow |
| Progressive / staged migration | A multi-step rollout of a replacement system |
| Explicit cohort / audience language | beta, internal, canary, a percentage, a country/region |
| Performance- / infrastructure-sensitive change | A change with meaningful performance or infrastructure blast radius |

## On a clear match

When the feature description clearly matches one or more categories above:

1. Propose adding a `## Delivery Considerations` section to `spec.md` and
   briefly explain which signal(s) triggered the proposal.
2. If the developer agrees, write **exactly one** `## Delivery Considerations`
   section — even when multiple heuristic categories match at once — using
   this exact convention so the gate scripts recognize it:
   - The heading line must be exactly `## Delivery Considerations`, with no
     trailing text on that line.
   - Within the section, include a line containing the literal label
     `Candidate flag(s):` followed by one or more comma-separated candidate
     flag names (e.g., `Candidate flag(s): checkout_v2`).
   - Include a rollout-intent statement explaining the intended rollout
     approach (e.g., staged percentage rollout, cohort/beta gating).
   - Never name a specific feature-flag provider anywhere in this section
     or elsewhere in the spec — even if the developer's own description
     names one. Provider naming happens at the plan phase, not here.

## When no heuristic matches

When none of the five categories above are matched, add **no** rollout-related
content of any kind to the spec, and add no visible overhead to the specify
flow beyond what the hook mechanism itself already contributes. The resulting
spec should look exactly as it would if the `rollout` extension were not
installed.

## Ambiguous signals: ask exactly one clarifying question

When the description is genuinely ambiguous — neither a clear match above nor
clearly free of any signal — ask exactly one clarifying question about
rollout intent, using the normal interactive `/speckit.specify` flow (no new
mechanism is introduced). Then:

- If the answer confirms rollout intent, proceed as in "On a clear match"
  above and write the marker.
- If the answer denies or declines rollout intent, or the developer does not
  answer, do not write the marker and add no other rollout-related content.

Never ask more than one clarifying question about rollout intent for a single
`/speckit.specify` run.

## If the developer declines

If the developer explicitly declines the proposed rollout framing — whether
it was proposed directly on a clear match, or after the single clarifying
question — do not write the `## Delivery Considerations` marker, and add no
other rollout-related content to the spec.
