---
description: "rollout: pre-tasks briefing — ordered task generation from Delivery Strategy with strict content lineage"
---

# `speckit.rollout.brief-tasks`

**Role**: When `/speckit.tasks` runs, determine whether to emit concrete,
ordered rollout tasks (create flag, configure environments/targeting,
integrate SDK, add telemetry validation, define rollback) into `tasks.md`.
The decision depends on two successive gates: (1) Does `spec.md` carry a
`## Delivery Considerations` marker (rollout intent)? (2) If yes, does
`plan.md` contain a `## Delivery Strategy` section (delivered rollout plan)?
If both gates pass, emit six ordered rollout tasks per named candidate flag,
each task derived exclusively from the Delivery Strategy section—never from
`spec.md`'s requirements. If the marker is absent or the Delivery Strategy
is missing, emit a one-line status message with appropriate context and add
zero rollout tasks.

**Status**: Active doctrine. This docstring and the instructions below
implement the three-branch pre-tasks logic specified in
`docs/foundation/vision.md` (§4, §5.2) and refined in
`specs/007-rollout-tasks-doctrine/`. The doctrine enforces Constitution
Principle III (Strict Content Lineage): rollout task content must never be
regenerated sideways from `spec.md`, but only derived from `plan.md`'s
Delivery Strategy section.

---

## Your Task

Your task is to decide whether to emit rollout tasks into `tasks.md`, and if
so, to generate them in a strict, ordered, and traceable way from the plan's
Delivery Strategy section. Follow the branching logic below.

---

## Step 1: Invoke the Rollout Gate Script (First Gate Check)

Before making any decision, invoke the shared rollout-detection gate script
to check whether `spec.md` carries a `## Delivery Considerations` marker:

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
- `hasFlags=false`: No marker was found, or hooks are disabled.
- `flags`: If marker exists, the comma-separated list of candidate flag names.
- `source`: Which file the marker was found in (typically `spec.md` for this
  briefing).
- `hooksEnabled`: Whether the rollout extension's hooks are enabled in config
  (informational; does not affect your branching decision).

**Important**: The gate script is the source of truth for marker presence. Use
its `hasFlags` output to branch your logic.

---

## Step 2: Decision Branches

### Branch A: No Rollout Marker (`hasFlags=false`)

**Scenario**: The feature carries no `## Delivery Considerations` marker in
`spec.md`. This indicates no rollout intent was identified during the specify
and clarify phases.

**Your action**: Emit a single, one-line status message acknowledging this
(for example: "No `Delivery Considerations` marker detected; proceeding with
normal task generation.") and add **no** other rollout-related content or
tasks to `tasks.md`. The resulting task list should look exactly as it would
if the `rollout` extension were not installed.

---

### Branch B: Marker Present; Check for Delivery Strategy (Second Gate)

**Scenario**: A `## Delivery Considerations` marker was found in `spec.md`.
Before proceeding to generate rollout tasks, you must verify that `plan.md`
actually contains a `## Delivery Strategy` section — this is the second,
feature-specific gate that ensures strict content lineage.

**Your action**: Scan `plan.md` for the presence of a section heading that
begins with `## Delivery Strategy` (case-insensitive match on the heading
text). Do not check `spec.md` again; the gate script already confirmed the
marker is there.

#### Sub-Branch B1: Delivery Strategy Section Absent

**Scenario**: `hasFlags=true`, but `plan.md` has no `## Delivery Strategy`
heading. This indicates the feature was flagged for rollout intent during
specify/clarify, but the plan phase either was not run, or ran before the
plan-phase rollout doctrine (Feature 006) was active, or the section was
manually removed.

**Your action**: Emit a single, one-line status message distinct from the
no-marker case (for example: "Rollout marker detected but no `Delivery
Strategy` section found in plan.md; skipping rollout task generation.") and
add **zero** rollout tasks to `tasks.md`. This message signals to the reader
"rollout intent is present but the plan hasn't caught up"—a different
situation than the no-marker case.

**Critical rule**: Do NOT attempt to regenerate or infer rollout task content
from `spec.md`'s requirements text as a substitute or fallback. The absence
of a Delivery Strategy section means the plan phase has not yet captured
delivery details, and task generation must wait until the plan is completed
or re-run with the full doctrine active.

---

#### Sub-Branch B2: Delivery Strategy Section Present

**Scenario**: `hasFlags=true` and `plan.md` contains a `## Delivery
Strategy` heading. The Delivery Strategy section is the sole, authoritative
source for rollout task content.

**Your action**: Proceed to **Step 3: Generate Rollout Tasks** (below).

---

## Step 3: Generate Rollout Tasks

When both gates pass (marker present, Delivery Strategy present), emit exactly
six ordered rollout tasks into `tasks.md`, **per named candidate flag**. Each
task must be grounded in a specific value or field from the Delivery Strategy
section—never inferred, fabricated, or backfilled from `spec.md`'s
requirements text.

### Task Generation Rules

#### Rule 1: Fixed Task Sequence

The six tasks MUST be emitted in this order, regardless of the order fields
appear in the Delivery Strategy section:

1. **Create the feature flag** — grounded in the flag name from the Delivery
   Strategy (typically the first field or explicitly named field)
2. **Configure environments** — grounded in the Delivery Strategy's phased
   rollout sequence and environment scope per phase
3. **Configure targeting rules** — grounded in the Delivery Strategy's
   targeting rules field
4. **Integrate the application SDK** — grounded implicitly in the flag name
   and provider; this task is always emitted (SDKs are required to consume
   the flag), even if no dedicated Delivery Strategy field covers it
5. **Add telemetry validation** — grounded in the Delivery Strategy's
   telemetry gates field
6. **Define rollback conditions** — grounded in the Delivery Strategy's
   rollback conditions field

#### Rule 2: Partial Delivery Strategy Sections

When the Delivery Strategy section is present but only partially populated
(e.g., telemetry gates omitted, or rollback conditions not yet written):

- Emit tasks **only** for the elements actually present in the section
- Do NOT fabricate or invent a value for a missing element
- Do NOT fall back to `spec.md`'s requirements text for the missing element
- The resulting task set may contain fewer than six tasks, and that is correct

**Example**: If the Delivery Strategy section contains the flag name, phased
rollout sequence, targeting rules, and telemetry gates—but no rollback
conditions—emit Tasks 1-5 only; omit Task 6 entirely.

#### Rule 3: Multiple Candidate Flags

When the `## Delivery Considerations` marker names more than one candidate
flag (comma-separated in the `Candidate flag(s):` line), emit the complete
six-task (or partial subset, per Rule 2) pattern **once per flag**, with each
task set clearly scoped to its own flag.

**Example**: If `Candidate flag(s): flag-a, flag-b`, emit Tasks 1-6 for
flag-a, then Tasks 1-6 (or subset) again for flag-b, with distinct task
descriptions naming the flag each applies to.

#### Rule 4: Content Traceability

Every emitted task's description must be traceable to a specific value in the
Delivery Strategy section. In each task description, include enough context
(the flag name, environment/targeting detail, or rollback condition) so a
reader can point to the corresponding line or phrase in the Delivery Strategy
and confirm the task was derived from it, not inferred from elsewhere.

**Example of traceable task description**: "Create the feature flag
`enable_new_dashboard` (candidate from plan.md Delivery Strategy)" — a reader
can then look at `plan.md`'s Delivery Strategy, find the line naming
`enable_new_dashboard`, and confirm the task was based on that explicit
content.

---

## Step 4: Emit the Result

Once you have determined the appropriate outcome (Branch A no-op, Branch B1
gap message, or Branch B2 task generation), append the result to `tasks.md`:

- **Branch A or B1**: Single one-line message (placed in a comment or brief
  statement at the top of the tasks file, so it is visible but non-intrusive).
- **Branch B2**: The ordered rollout tasks (one per Delivery Strategy element,
  per flag), followed by any non-rollout tasks that the base task generation
  would normally produce.

---

## Constraints & Cross-Cutting Rules

These constraints apply across all branches:

1. **Gate script runs in default mode**: Invoke `scripts/bash/rollout-gate.sh`
   or `rollout-gate.ps1` with no mode flag (equivalent to `--mode default`),
   which checks only `spec.md` for the marker. Analyze mode (which searches
   multiple files) is reserved for Feature 9's `before_analyze` briefing.

2. **No provider tool invocations**: This briefing MUST NOT include any
   instruction to invoke a provider MCP tool, fetch provider state, or
   execute a live provider action. Task content may reference the flag name
   and provider (values already in the Delivery Strategy section), but
   provider execution is scoped to Feature 10's `before_implement` briefing
   only.

3. **Content lineage never flows backward**: Never consult `spec.md` for
   rollout task content, even when the Delivery Strategy section is absent or
   sparse. This is the defining principle of Feature III (Strict Content
   Lineage): content flows one direction only (`tasks.md` ← `plan.md`'s
   Delivery Strategy), never sideways from `spec.md`.

4. **Spec.md consulted only for gate state**: The only role `spec.md` plays
   in this briefing is as the marker-presence source checked by the gate
   script. Once the gate script's output is obtained, `spec.md` is not
   consulted further.

5. **Task order is fixed, not derived**: The six-task sequence is fixed by
   doctrine (Rule 1, above), not derived from the order fields appear in the
   Delivery Strategy section. This ensures clarity across all features about
   what must happen first, regardless of how the plan author happened to
   order their notes.

6. **No cross-feature content drift**: Do not interpret this briefing as a
   license to modify the Delivery Strategy section in `plan.md`, modify the
   marker in `spec.md`, or change any file outside of appending tasks to
   `tasks.md`. Only `tasks.md` changes as a result of this briefing.

---

## References

- **Vision**: `docs/foundation/vision.md` §4, §5.2 (rollout chain, task-phase
  role)
- **Gate Script Contract**: `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`
  (marker shape, gate script output format)
- **Delivery Strategy Section Shape**: Feature 006 (brief-plan.md) doctrine
  and `specs/006-rollout-plan-doctrine/data-model.md` (fields, validation
  rules)
- **Spec Template**: `specs/007-rollout-tasks-doctrine/spec.md` (functional
  requirements, acceptance scenarios, key entities)
- **Data Model**: `specs/007-rollout-tasks-doctrine/data-model.md` (rollout
  task set entity, Delivery Strategy presence check)

---

## Examples

### Example 1: Branch A (No marker)

**Scenario**: Gate script outputs `hasFlags=false`.

**Briefing output**: "No `Delivery Considerations` marker detected; proceeding
with standard task generation."

**Result in tasks.md**: No rollout tasks are added; `tasks.md` contains only
non-rollout tasks from the base task-generation process.

---

### Example 2: Branch B1 (Marker present, no Delivery Strategy)

**Scenario**: Gate script outputs `hasFlags=true, flags=enable_widget_redesign`.
Scan of `plan.md` finds no `## Delivery Strategy` heading.

**Briefing output**: "Rollout marker detected (`enable_widget_redesign`) but
no `Delivery Strategy` section found in plan.md; skipping rollout task
generation. Re-run `/speckit.tasks` after `/speckit.plan` adds the Delivery
Strategy section."

**Result in tasks.md**: No rollout tasks are added; `tasks.md` contains only
non-rollout tasks.

---

### Example 3: Branch B2 (All gates pass, full Delivery Strategy)

**Scenario**: Gate script outputs `hasFlags=true, flags=enable_dark_mode`.
Scan of `plan.md` finds a `## Delivery Strategy` section with all fields
populated:
- Flag name: `enable_dark_mode`
- Provider: `LaunchDarkly`
- Phased rollout: internal → beta users → 25% → 100%
- Targeting rules: Chrome and Firefox browsers only
- Telemetry gates: CSS rendering metrics within acceptable bounds
- Rollback conditions: if rendering metrics exceed threshold

**Briefing output** (embedded in the task set):

1. Create the feature flag `enable_dark_mode` on LaunchDarkly
2. Configure environments: phase 1 (internal), phase 2 (beta users), phase 3 (25% of users), phase 4 (100% of users)
3. Configure targeting rules: Chrome and Firefox browsers only
4. Integrate the application SDK to consume the `enable_dark_mode` flag
5. Add telemetry validation: CSS rendering metrics must remain within baseline (from plan.md Delivery Strategy)
6. Define rollback conditions: revert flag if rendering metrics exceed threshold (from plan.md Delivery Strategy)

**Result in tasks.md**: All six rollout tasks are added, followed by standard
non-rollout tasks.

---

### Example 4: Branch B2 (Partial Delivery Strategy)

**Scenario**: Gate script outputs `hasFlags=true, flags=enhance_search`. Scan
of `plan.md` finds a `## Delivery Strategy` section with:
- Flag name: `enhance_search`
- Provider: `Custom provider`
- Phased rollout: internal team → 50% of users → 100%
- Targeting rules: not specified
- Telemetry gates: search latency acceptable
- Rollback conditions: not specified

**Briefing output** (embedded in task set):

1. Create the feature flag `enhance_search` on Custom provider
2. Configure environments: internal team, then 50% of users, then 100%
3. (Targeting rules task omitted—not present in Delivery Strategy)
4. Integrate the application SDK to consume the `enhance_search` flag
5. Add telemetry validation: search latency must remain acceptable (from plan.md)
6. (Rollback conditions task omitted—not specified in Delivery Strategy)

**Result in tasks.md**: Four rollout tasks (1, 2, 4, 5) are added, with tasks
3 and 6 skipped because their content is not present in the Delivery
Strategy. Tasks are still emitted in logical order (1, 2, then 4, then 5);
numbering is not renumbered to be 1-4, but gaps are acceptable.
