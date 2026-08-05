---
description: "rollout: pre-plan briefing — Delivery Strategy doctrine with marker detection and late-intent sniff"
---

# `speckit.rollout.brief-plan`

**Role**: When `/speckit.plan` runs, detect whether the feature's `spec.md`
carries a `## Delivery Considerations` marker (rollout flag intent); if
marked, instruct the plan to include a `## Delivery Strategy` section with
feature flag name, provider, phased rollout, targeting rules, telemetry
gates, and rollback conditions. If no marker is present, perform a minimal
sniff of the current `/plan` invocation's own arguments for rollout-related
language; if found, back-fill the marker into `spec.md` and then generate
the Delivery Strategy section; if not found, emit a one-line no-op and add
no rollout content to the plan.

**Status**: Active doctrine. This docstring and the instructions below
replace the placeholder body, implementing the three-branch pre-plan logic
specified in `docs/foundation/vision.md` (§4, §5.1, §5.2, §9) and refined
in `specs/006-rollout-plan-doctrine/`.

---

## Your Task

Your task is to decide whether to produce a **Delivery Strategy** section in
`plan.md`, and if so, to populate it with complete rollout details. The
decision depends on whether the feature already carries rollout intent from
the specify/clarify phases, or whether that intent is being introduced for
the first time during this plan phase. Follow the branching logic below:

---

## Step 1: Invoke the Rollout Gate Script (Authority Check)

Before making any decision, invoke the shared rollout-detection gate script to
check whether `spec.md` carries a `## Delivery Considerations` marker:

```bash
scripts/bash/rollout-gate.sh
```

(If you are on Windows or PowerShell, use `scripts/powershell/rollout-gate.ps1`
instead. The output format is identical.)

The script will output four lines:

```
hasFlags=<true|false>
flags=<comma-separated names>
source=<spec.md|plan.md|tasks.md|(empty)>
hooksEnabled=<true|false>
```

**What the output means**:
- `hasFlags=true`: A `## Delivery Considerations` marker (with flag names) was
  found in `spec.md` (or plan.md/tasks.md if run in analyze mode, but default
  mode checks spec.md only).
- `hasFlags=false`: No marker was found.
- `flags`: If marker exists, the comma-separated list of candidate flag names.
- `source`: Which file the marker was found in (typically `spec.md` for this
  briefing).
- `hooksEnabled`: Whether the rollout extension's hooks are enabled in config
  (informational; does not affect your branching decision).

**Important**: The gate script is the source of truth for marker presence. Use
its `hasFlags` output to branch your logic.

---

## Step 2: Decision Branches

### Branch A: Marker Already Present (`hasFlags=true`)

**Scenario**: The feature was marked for rollout at specify time (Feature 004)
and refined at clarify time (Feature 005). The rollout intent is already
captured in the marker's `Candidate flag(s):` line.

**Your action**: Proceed directly to **Step 3: Produce the Delivery Strategy
Section** (below), using the spec's requirements and the marker's candidate
flag name(s) as the source of truth.

---

### Branch B: No Marker; Sniff the `/plan` Arguments

**Scenario**: The feature was not flagged during specify/clarify, but this
`/speckit.plan` invocation's arguments suggest rollout intent is being
introduced for the first time. You must decide whether to back-fill the marker
and produce a Delivery Strategy, or proceed as if the feature is non-rollout.

**Your sniff heuristic**: Scan the current `/plan` invocation's own arguments
(the text supplied in this command's `arguments` field, if any) for signals in
these categories:

1. **High-risk or irreversible changes**: Major breaking changes, significant
   API shifts, deprecations without graceful fallback, or changes that cannot
   be undone once deployed.

2. **Major UX changes**: Visible interface overhauls, workflow restructures, or
   user-facing behavior shifts that might surprise or require re-training.

3. **Progressive or phased migrations**: Explicit language about staging,
   phasing, onboarding users gradually, or rolling out to cohorts (e.g.,
   "release to internal team first", "5% users", "beta testers only").

4. **Cohort or percentage language**: References to percentages, segments,
   audiences, user tiers, or explicit staging ("5%", "25%", "100%", "internal",
   "early adopters", "beta").

5. **Performance or infrastructure-sensitive changes**: Deployment
   optimizations, scaling concerns, load-shedding behavior, or infrastructure
   decisions that affect overall system stability and might warrant staged
   rollout to monitor metrics.

**Sniff window**: Only examine the `/plan` invocation's **own** arguments. Do
not re-examine `spec.md` here — the gate script already did that, and Branch B
only runs when `hasFlags=false`. Never override an existing marker based on
plan-time arguments.

---

### Branch B1: Sniff Finds Rollout Signals

**Your action**: 

1. **Back-fill the marker into `spec.md`**. Add a new `## Delivery
   Considerations` section to `spec.md` (if it does not already have one) with
   the following structure:

   ```markdown
   ## Delivery Considerations

   Candidate flag(s): <infer-flag-name>

   <brief statement of the rollout intent captured from this plan invocation's
   arguments>
   ```

   **Conventions**:
   - Use the exact heading `## Delivery Considerations` (literal match,
     case-insensitive matching for the marker's label, but the heading itself
     is always this exact text).
   - Include the line containing the literal text `Candidate flag(s):` followed
     by a flag name you infer from the plan-time language (e.g., if the
     arguments mention "phased feature roll-out", infer a flag like
     `phased_feature_rollout` or similar; keep it concise and descriptive).
   - Write a brief one-line statement of the rollout intent (e.g., "Staged
     rollout of phased feature to monitor adoption metrics").
   - This marker will be recognized by the shared gate script on any subsequent
     phase (clarify, analyze, checklist, or a later plan re-run), exactly as if
     it had been written during specify time.

2. **Then proceed to Step 3: Produce the Delivery Strategy Section** (below),
   treating the newly back-filled marker as authoritative source for the flag
   name and creating a complete Delivery Strategy from the plan-time signals
   and the spec's requirements.

---

### Branch B2: Sniff Finds No Rollout Signals

**Your action**: Emit a one-line status message:

```
No rollout signals detected in this plan; feature will roll out 100% on deploy.
```

Add **no** `## Delivery Strategy` section to `plan.md`. Add **no** marker to
`spec.md`. The feature's plan.md proceeds as a standard, non-rollout plan,
mirroring how it would be planned if specify/clarify had not detected rollout
intent either.

---

## Step 3: Produce the Delivery Strategy Section

**Trigger**: This step runs after Branch A (marker already present) or Branch
B1 (sniff found signals and marker is back-filled). In both cases, a marker
is now present in `spec.md`.

**Your task**: Add a `## Delivery Strategy` section to `plan.md` at an
appropriate location (typically after the overview/summary and before
detailed phases or implementation sections). The section must contain all six
of the following elements, even if some rollout parameters were not fully
clarified during the clarify phase:

1. **Feature Flag Name**: The candidate flag name from the marker's
   `Candidate flag(s):` line (or inferred from Branch B1's back-fill). If
   multiple flags are listed, use them all.

2. **Provider**: Write exactly: `Provider: LaunchDarkly`.

3. **Phased Rollout Sequence**: Describe the stages of rollout (e.g., internal
   team → 5% → 25% → 100%). If the marker's clarified parameters from Feature
   005 specify phases, use them. If not, derive a reasonable default from the
   feature's risk profile and the spec's requirements:
   - High-risk or high-impact features: start with internal-only or <1%,
     progress in 5-10% steps, with telemetry gates between phases.
   - Medium-risk features: start 5%, progress to 25%, then 100%.
   - Low-risk or routine updates: may go wider earlier if confidence is high,
     but still include at least two phases to allow early monitoring.

4. **Targeting Rules**: Describe which users/segments will receive each phase.
   If the marker's clarified parameters (Feature 005) specify an audience or
   segments (e.g., "internal team", "EU-region users", "paying customers"),
   use them. If not, infer from the spec's requirements and the feature's
   nature:
   - If this is an internal-only change, target internal employee accounts.
   - If this is a public feature, specify the audience (e.g., "US-based users",
     "enterprise tier", "mobile app users").
   - If the spec mentions specific user groups, target them explicitly.

5. **Telemetry Gates**: Describe the metrics or signals that must hold (or
   improve) before advancing to the next phase. If the marker's clarified
   parameters specify gates (e.g., "error rate < 1%", "latency p99 < 500ms"),
   use them. If not, propose reasonable defaults grounded in the feature:
   - For features affecting user experience: error rate, latency percentiles,
     user-reported issues.
   - For infrastructure changes: error rate, resource utilization, availability.
   - For behavioral changes: adoption rates, retention, cohort-based metrics.

6. **Rollback Conditions**: Describe conditions under which the rollout will
   be halted and reverted. Propose specific, actionable criteria:
   - Example: "Revert if error rate exceeds 5% or if a Critical severity bug
     is discovered in telemetry."
   - Always include at least one quantitative threshold (e.g., error %, latency
     spike) and one qualitative trigger (e.g., critical bug, customer complaint
     pattern).

**Content lineage**: Every element of the Delivery Strategy must derive from:
- The spec's stated requirements (what the feature does, why it matters, what
  users it affects).
- Any rollout parameters already clarified in the marker from Feature 005
  (phases, audience, percentages, telemetry gates, rollback conditions).

Do not invent rollout details unconnected to the spec or the marker. Where a
parameter is still missing, propose a reasonable, grounded draft value rather
than omitting it — but the proposal must fit the spec's context.

**Optional template reference**: If a file named `templates/rollout-section.md`
exists in this extension package, you may consult it for structural examples
of how to format the six elements. However, do not assume this file exists and
do not require its presence to produce a complete Delivery Strategy section.

---

## Appendix: Edge Cases and Exceptions

**What if the feature directory cannot be resolved?**

The gate script returns exit code 2 and `hasFlags=false`. Treat this as Branch
B (no marker) and proceed to the sniff; if the sniff also finds no signals,
emit the one-line no-op as in Branch B2.

**What if the marker exists AND the `/plan` arguments contain rollout language?**

The marker takes precedence. Do not re-run the sniff or back-fill. Proceed
directly to Step 3 (Delivery Strategy) using the existing marker as the flag
name source.

**What if I am re-running `/speckit.plan` on a feature that already had a plan
produced in a prior run?**

The marker check and sniff logic are identical every time. If the marker was
present before, it is still present, and you generate the Delivery Strategy
again (regenerated fresh from the (possibly further-clarified) marker and
spec). There is no distinction between a "first" and "subsequent" plan run —
the doctrine treats each invocation identically.

**What if the feature's `spec.md` is underspecified or missing required details
that inform the Delivery Strategy?**

Propose the most reasonable interpretation grounded in what the spec *does*
say. If you must make assumptions, state them briefly in a comment or inline
remark so a reviewer can verify them. Do not refuse to produce the Delivery
Strategy; the purpose of this briefing is to ensure *something* coherent
appears in `plan.md` even if parameters are sparse.

**What if `templates/rollout-section.md` does not exist?**

Your instructions do not require it. Produce the Delivery Strategy directly
from the six elements (flag name, provider, phased rollout, targeting, gates,
rollback). The template is optional reference only.

---

## Summary

1. **Run the gate script** to check for an existing marker.
2. **If marker present** (hasFlags=true): Proceed to produce Delivery Strategy
   (Step 3).
3. **If no marker** (hasFlags=false): **Sniff** the `/plan` arguments.
   - If sniff finds signals: **Back-fill** marker into spec.md (Branch B1),
     then proceed to Step 3.
   - If sniff finds no signals: **Emit one-line no-op** (Branch B2), add no
     Delivery Strategy.
4. **Deliver** a complete Delivery Strategy section (all six elements) when a
   marker is present or just back-filled.

This logic ensures that already-flagged features produce a clean Delivery
Strategy, non-rollout features remain untouched, and features gaining rollout
intent mid-planning are caught and handled gracefully in the same run.
