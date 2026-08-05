---
description: "rollout: pre-checklist briefing — Rollout-quality checklist items based on marker presence"
---

# `speckit.rollout.brief-checklist`

**Role**: Add rollout-quality checklist items (flag naming, targeting,
telemetry gates, rollback defined, phase ordering) during
`/speckit.checklist` when the feature has rollout content. This briefing
detects whether the feature's `spec.md` carries a `## Delivery Considerations`
marker; if marked, instruct the checklist generation to add a dedicated
rollout-quality category containing five baseline items. If no marker is
present, emit a one-line no-op and add no rollout content.

**Status**: Active doctrine. This docstring and the instructions below
replace the placeholder body, implementing the three-user-story pre-checklist
logic specified in `docs/foundation/vision.md` (§5.1, Decision D6) and
refined in `specs/009-rollout-checklist-doctrine/`.

---

## Your Task

Your task is to decide whether to add a rollout-quality checklist category,
and if so, to populate it with the five baseline items that verify rollout
content completeness. The decision depends on whether the feature carries a
rollout marker in `spec.md`. Follow the branching logic below:

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
  found in `spec.md`.
- `hasFlags=false`: No marker was found (or the gate script encountered a
  diagnostic error and exited with code 2).
- `flags`: If marker exists, the comma-separated list of candidate flag names.
- `source`: Which file the marker was found in (typically `spec.md` for
  checklist).
- `hooksEnabled`: Whether the rollout extension's hooks are enabled in config
  (informational; does not affect your branching decision).

**Important**: The gate script is the source of truth for marker presence. Use
its `hasFlags` output to branch your logic. Treat `hasFlags=false` (including
diagnostic exit code 2) identically: proceed to **Branch A** (below).

---

## Step 2: Decision Branches

### Branch A: No Marker (`hasFlags=false`) → One-Line No-Op, No Rollout Items

**Scenario**: The feature was not marked for rollout in `spec.md`, or the gate
script encountered a diagnostic error. This is a non-rollout feature; no
rollout-quality checklist items are added.

**Your action**:

1. Emit exactly one line of output to signal that rollout checks are being
   skipped:
   ```
   (Rollout quality: No marker detected in spec.md; skipping rollout-quality items.)
   ```

2. Stop here. Do NOT add any rollout-quality category, items, or other
   rollout-related content to the checklist.

3. Proceed to the standard `/speckit.checklist` logic without modification.

**Result**: Non-rollout features see zero overhead — no rollout-quality
category, rest of the checklist identical to what it would be without the
extension installed.

---

### Branch B: Marker Present (`hasFlags=true`) → Add Rollout-Quality Category

**Scenario**: The feature carries a `## Delivery Considerations` marker in
`spec.md`. It may have a `## Delivery Strategy` section in `plan.md`, or that
section may be incomplete or missing.

**Your action**: Proceed to **Step 3: Add the Rollout-Quality Category** (below),
treating the marker's presence as the signal to add the category.

---

## Step 3: Add the Rollout-Quality Category

**Trigger**: This step runs after Branch B (marker is present).

**Your task**: Add a dedicated `## Rollout Quality` category to the checklist
file you are generating, positioned after any other categories the user's
checklist request already produces. The category must contain five baseline
items, phrased as requirements-quality questions (not implementation-verification
statements), that together verify the completeness of the feature's rollout
content.

### Category Heading

Insert a new section heading:

```
## Rollout Quality
```

This category is additive to whatever other category or categories the user
requested (e.g., if they asked for a UX checklist, the UX category comes first,
then the Rollout Quality category). Never remove, replace, or reorder any
category the user originally requested.

### The Five Baseline Items

Add these five items in sequence, continuing the checklist's existing CHK ID
sequence (e.g., if the previous item was CHK015, start the rollout items at
CHK016). Each item is phrased as a requirements-quality question—a check to
perform to verify whether the rollout content is complete and unambiguous.

**Item 1: Flag naming**
```
- [ ] CHKnnn Is the feature flag name specific and unambiguous?
```

Checks the spec's `## Delivery Considerations` marker (line `Candidate flag(s):`)
and/or the plan's `## Delivery Strategy` section for a clear, specific name. The
item is phrased as a question to verify completeness, not as a status assertion.

**Item 2: Environments and targeting**
```
- [ ] CHKnnn Are target environments and targeting rules clearly specified?
```

Checks the plan's `## Delivery Strategy` section (or a note in the spec marker)
for completeness and clarity around which environments (staging, production) and
which user segments or targeting rules the rollout applies to. The item is a
question about whether the requirements exist and are clear.

**Item 3: Telemetry gates**
```
- [ ] CHKnnn Are telemetry gates defined with measurable thresholds?
```

Checks the plan's `## Delivery Strategy` section for defined telemetry gate
thresholds that must hold before advancing the rollout to the next phase. The
item asks whether these gates are defined and measurable, not whether they have
been implemented.

**Item 4: Rollback conditions**
```
- [ ] CHKnnn Are rollback conditions explicitly defined?
```

Checks the plan's `## Delivery Strategy` section for clear, explicit rollback
triggers and procedures (e.g., "rollback if error rate exceeds X%"). The item
asks whether these conditions are defined in the rollout plan.

**Item 5: Rollout phases**
```
- [ ] CHKnnn Are rollout phases ordered and complete?
```

Checks the plan's `## Delivery Strategy` section for a complete, logically
ordered sequence of rollout phases (e.g., internal → 5% → 25% → 100%). The item
asks whether all phases are present and sequenced correctly.

### Item Phrasing Conventions

Each item follows this pattern:

- **Phrased as a question**, not a command or assertion: "Are X defined?" not
  "Define X" and not "X is defined".
- **Focuses on requirements completeness**, not implementation status: The
  question is whether the Delivery Strategy section (or spec marker, if the plan
  doesn't yet exist) contains the information, not whether a feature flag has
  been created or deployed.
- **Can be asked at any time in the workflow**, including before `plan.md` has
  been written: Items check whether the needed information exists in whatever
  artifact is available (spec marker, plan, or tasks), and they are phrased to
  remain meaningful even if the target artifact is not yet complete.
- **Consistent with the existing `/speckit.checklist` item-phrasing conventions**:
  The format and tone match every other checklist category `/speckit.checklist`
  generates—they are "unit tests for requirements writing," questions about
  whether the requirements are complete, clear, and unambiguous.

**🚫 ABSOLUTELY PROHIBITED** (to maintain consistency with existing checklist
items):

- ❌ Items phrased as implementation-verification statements (e.g., "Verify the
  feature flag was created in LaunchDarkly", "Test that telemetry is emitted").
- ❌ Items phrased as status assertions or findings (e.g., "Flag naming is not
  defined", "Telemetry gates are missing").
- ❌ Items that assume `plan.md` already exists or is complete (e.g., "Does the
  plan specify telemetry gates?" — what if plan.md hasn't been written yet?).

**✅ REQUIRED PATTERNS**:

- ✅ "Are [rollout aspect] defined/specified in [target artifact or marker]?"
- ✅ "Is [vague term] quantified/clarified with specific [criteria]?"
- ✅ "Are [phases/conditions] logically ordered and complete?"
- ✅ Items work whether or not plan.md yet exists, phrased as checks to verify,
  not as findings about completeness of a not-yet-written section.

### Multi-Flag Handling

If the spec's `## Delivery Considerations` marker names multiple candidate flags
(e.g., `Candidate flag(s): checkout_v2, checkout_v3_beta`), add **one shared
rollout-quality category** containing these same five items. Do **not** duplicate
the category per flag. The items check the rollout content at the feature level,
not per-flag granularity.

### Category Placement and File Handling

- **Placement in file**: Insert the rollout-quality category after any other
  categories the user requested. Never remove or reorder other categories.
- **ID continuation**: Continue the checklist's existing CHK ID sequence. If the
  last item in the checklist before rollout items was CHK015, start rollout
  items at CHK016.
- **Append-only**: If the checklist file already exists, append the new
  rollout-quality category to it (and its items to the ID sequence). Never
  delete or replace existing content.
- **New file handling**: If the checklist file does not yet exist, create it with
  the new category and items.

---

## Step 4: Return to Standard Checklist Generation

After adding the rollout-quality category (or after emitting the no-op in
Branch A), proceed to the standard `/speckit.checklist` logic. Complete any
other checklist generation tasks as if the rollout briefing had not run.

---

## Summary

- **If marker present** (`hasFlags=true`): Add one rollout-quality category with
  five requirements-quality items, additive to whatever else the user requested.
- **If no marker** (`hasFlags=false`): Emit a one-line no-op; add no rollout
  items or categories.
- **Items are questions about rollout content completeness**, phrased as
  requirements-quality checks, never as implementation-verification or status
  assertions.
- **The category is feature-level, not per-flag**: One shared category even when
  the marker names multiple flags.
- **Items work regardless of plan.md status**: They check "are these defined?"
  not "does the plan contain these?" — so they're meaningful at any workflow
  stage.
