---
description: "rollout: pre-analyze briefing — Rollout-chain consistency validation and false-positive suppression"
---

# `speckit.rollout.brief-analyze`

**Role**: Validate rollout-chain consistency (spec marker ↔ plan strategy ↔
tasks) during `/speckit.analyze`, without flagging rollout content as
orphaned requirements. This briefing runs before the standard analyze logic
and gives the agent the instructions to (1) suppress false-positive
orphan/coverage-gap/duplication/ambiguity findings for intentional rollout
content, and (2) detect and report genuine breaks in the rollout chain with
distinct, high-severity findings.

**Status**: Active doctrine. This docstring and the instructions below
replace the placeholder body, implementing the four-user-story pre-analyze
logic specified in `docs/foundation/vision.md` (§5.1, Decision D6) and
refined in `specs/008-rollout-analyze-doctrine/`.

---

## Your Task

Your task is to decide whether to perform rollout-chain consistency checks,
and if so, to report any breaks in the chain as distinct findings. The
decision depends on whether the feature carries a rollout marker in
`spec.md`. Follow the branching logic below:

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
  analyze).
- `hooksEnabled`: Whether the rollout extension's hooks are enabled in config
  (informational; does not affect your branching decision).

**Important**: The gate script is the source of truth for marker presence. Use
its `hasFlags` output to branch your logic. Treat `hasFlags=false` (including
diagnostic exit code 2) identically: proceed to **Branch A** (below).

---

## Step 2: Decision Branches

### Branch A: No Marker (`hasFlags=false`) → One-Line No-Op, No Further Checks

**Scenario**: The feature was not marked for rollout in `spec.md`, and no
gate-script diagnostic failure occurred. This is a non-rollout feature; the
standard analyze logic applies unchanged.

**Your action**:

1. Emit exactly one line of output to signal that rollout checks are being
   skipped:
   ```
   (Rollout analysis: No marker detected in spec.md; standard analysis proceeding.)
   ```

2. Stop here. Do NOT perform any further rollout-chain checks. Do NOT inspect
   `plan.md` or `tasks.md` for rollout content. Do NOT emit any rollout-chain
   finding.

3. Proceed to the standard `/speckit.analyze` logic without modification.

**Result**: Non-rollout features see zero overhead — no rollout-specific
findings, no rollout-content inspection, rest of the analyze report identical
to what it would be without the extension installed.

---

### Branch B: Marker Present (`hasFlags=true`) → Perform Rollout-Chain Validation

**Scenario**: The feature carries a `## Delivery Considerations` marker in
`spec.md`. It may have rollout-strategy and rollout-task content in
`plan.md` and `tasks.md`, or those may be incomplete or missing.

**Your action**: Perform three steps in sequence:

1. **Step B1: Suppress false-positive findings for rollout content** (see
   below)
2. **Step B2: Check for plan.md break** (missing `## Delivery Strategy`
   heading)
3. **Step B3: Check for tasks.md break** (missing rollout tasks)

---

### Step B1: Suppress False-Positive Findings for Rollout Content

When the marker is present, treat the following three categories of content as
intentional, already-cross-referenced material — **never report any of them
as orphaned requirements, unmapped tasks, duplication, or ambiguity findings**:

1. **The marker itself** — the `## Delivery Considerations` heading and the
   `Candidate flag(s):` line in `spec.md`.
2. **The Delivery Strategy section** (if present) — the entire `## Delivery
   Strategy` section in `plan.md`, including all subsections (flag name,
   provider, phased rollout, targeting, telemetry, rollback).
3. **Rollout tasks** (if present) — any task in `tasks.md` that is tagged or
   described using the six rollout task categories:
   - Create flag
   - Configure environments
   - Configure targeting rules
   - Integrate SDK
   - Add telemetry validation
   - Define rollback conditions

**Suppression scope**: This suppression applies to `/speckit.analyze`'s
standard detection passes (the Coverage Summary section, Unmapped Tasks
section, duplication/ambiguity checks). These content items are excluded from
being flagged as gaps, orphans, or mapping failures because they are
intentional rollout-chain links, not oversight.

**Important distinction**: Suppression is about preventing false-positive
findings for content that *is* already present. It does NOT suppress findings
for content that is *absent* — see **Step B2** and **Step B3** for break
detection.

---

### Step B2: Check for Spec-to-Plan Break (Missing Delivery Strategy)

After suppressing false positives, check whether `plan.md` contains a
`## Delivery Strategy` heading.

**How to check**: Search `plan.md` for the heading `## Delivery Strategy`
(case-insensitive match, leading `##` with optional whitespace).

**If the heading is present**: Proceed to **Step B3** (check for tasks
break).

**If the heading is absent**: A chain break has been detected. Emit the
following finding (use the exact format shown):

| Field | Value |
|---|---|
| ID | `ROLLOUT-CHAIN-01` |
| Category | `Coverage Gap` |
| Severity | `HIGH` |
| Location(s) | `spec.md` (Delivery Considerations marker) / `plan.md` (missing section) |
| Summary | `Delivery Considerations marker present in spec.md but no Delivery Strategy section found in plan.md — rollout plan coverage is incomplete.` |
| Recommendation | Add a `## Delivery Strategy` section to `plan.md` to document the feature's progressive-delivery approach, flag name(s), provider, phased rollout plan, targeting rules, telemetry validation gates, and rollback conditions. Refer to `docs/foundation/vision.md` section 4 for guidance. |

**After emitting the finding**: Stop rollout-chain checks here. Do NOT
proceed to **Step B3**. Return to the standard `/speckit.analyze` logic.

(Reason: If the Delivery Strategy section is missing, we cannot reliably
check for corresponding rollout tasks; checking anyway would risk a cascading
false-positive or ambiguous finding.)

---

### Step B3: Check for Plan-to-Tasks Break (Missing Rollout Tasks)

This step runs only if **Step B2** found the `## Delivery Strategy` heading
present (i.e., no spec-to-plan break was detected).

Check whether `tasks.md` contains at least one task from the six rollout task
categories:
- Create flag
- Configure environments
- Configure targeting rules
- Integrate SDK
- Add telemetry validation
- Define rollback conditions

**How to check**: Search `tasks.md` for presence of any of these categories
by keyword matching (case-insensitive). Look for task descriptions or titles
containing the category names, or closely related keywords (e.g., "flag",
"targeting", "environment", "telemetry", "rollback"). A partial task set is
valid (e.g., only "Create flag" and "Add telemetry validation" is sufficient
for a plan that prioritizes those aspects over all six categories).

**If at least one rollout task category is present**: The chain is consistent
end-to-end. Proceed to the standard `/speckit.analyze` logic without emitting
any break finding. The three rollout artifacts (marker, Delivery Strategy,
rollout tasks) are all in place and intentionally cross-referenced —
**no gap/orphan findings should be emitted for any of them** (already
suppressed by **Step B1**).

**If no rollout task category is detected**: A chain break has been detected.
Emit the following finding (use the exact format shown):

| Field | Value |
|---|---|
| ID | `ROLLOUT-CHAIN-02` |
| Category | `Coverage Gap` |
| Severity | `HIGH` |
| Location(s) | `plan.md` (Delivery Strategy section) / `tasks.md` (missing tasks) |
| Summary | `Delivery Strategy section present in plan.md but no rollout tasks found in tasks.md — rollout implementation coverage is missing.` |
| Recommendation | Add rollout-related tasks to `tasks.md` to implement the progressive-delivery plan documented in `plan.md`. Create tasks for the key phases and categories: flag creation, environment configuration, targeting rules, SDK integration, telemetry validation, and rollback conditions. Refer to `commands/brief-tasks.md` for the rollout task doctrine and examples. |

**After emitting the finding**: Return to the standard `/speckit.analyze`
logic.

---

## Finding Format Specification

Both chain-break findings (`ROLLOUT-CHAIN-01` and `ROLLOUT-CHAIN-02`) MUST be
reported using the standard `/speckit.analyze` findings table format:

```
ID | Category | Severity | Location(s) | Summary | Recommendation
```

**Important constraints**:

- **Category must be exactly `Coverage Gap`** (not "Missing Content",
  "Incomplete Plan", or any synonym) — the exact wording preserves
  determinism and consistency with analyze's existing rubric.
- **Severity must be exactly `HIGH`** (not "CRITICAL" or "MEDIUM") — HIGH is
  the standard severity for rollout-chain lineage concerns per the analyze
  agent's rubric (`.github/agents/speckit.analyze.agent.md`).
- **Location(s) must distinguish the two breaks clearly**: `spec.md` /
  `plan.md` for the marker-to-plan break, and `plan.md` / `tasks.md` for
  the plan-to-tasks break.
- **Summary wording must be distinct between the two findings** so a reader
  can immediately tell which link in the chain is broken without re-reading
  locations. The two wordings above (`...marker present...` vs
  `...Delivery Strategy...`) achieve this distinction.
- **MUST NOT instruct editing any artifact** to repair the gap — the
  Recommendation field guides the user to add content, not to re-generate or
  modify existing sections.

---

## Scope & Out-of-Scope

### In Scope

- Invoke the gate script in default (spec.md-only) mode to detect marker
  presence.
- Suppress false-positive orphan/coverage-gap findings for rollout content
  when the marker is present.
- Detect and report spec-to-plan breaks (marker present, Delivery Strategy
  absent).
- Detect and report plan-to-tasks breaks (Delivery Strategy present, rollout
  tasks absent).

### Out of Scope

- Modifying any artifact (`spec.md`, `plan.md`, `tasks.md`) to fix detected
  gaps — this briefing is report-only.
- Per-flag or per-task chain granularity — feature-level presence/absence
  suffices.
- New gate-script modes or contract extensions — reuse the default mode and
  the existing marker convention.
- Editing `extension.yml`, `scripts/`, or other `commands/brief-*.md` files
  — scope is limited to `commands/brief-analyze.md`.

---

## Examples

### Example 1: Consistent Chain (Marker + Strategy + Tasks Present)

```
$ scripts/bash/rollout-gate.sh
hasFlags=true
flags=feature-flag-alpha
source=spec.md
hooksEnabled=true

$ # Step B1: Suppress false positives for marker, Delivery Strategy, tasks
$ # Step B2: Check for Delivery Strategy section → FOUND
$ # Step B3: Check for rollout tasks → FOUND (at least one category present)
$ # Result: No chain-break findings emitted; standard analyze report proceeds
$ #         with marker, Delivery Strategy, and rollout tasks excluded from
$ #         being flagged as orphans/gaps
```

### Example 2: No Marker (Non-Rollout Feature)

```
$ scripts/bash/rollout-gate.sh
hasFlags=false
flags=
source=
hooksEnabled=true

$ # Step A: No marker detected
$ # Output: "(Rollout analysis: No marker detected in spec.md; standard analysis proceeding.)"
$ # Result: No rollout-chain checks performed; standard analyze report produced unchanged
```

### Example 3: Marker Present but No Delivery Strategy

```
$ scripts/bash/rollout-gate.sh
hasFlags=true
flags=feature-flag-beta
source=spec.md
hooksEnabled=true

$ # Step B1: Suppress false positives for marker
$ # Step B2: Check for Delivery Strategy section → NOT FOUND
$ # Result: Emit ROLLOUT-CHAIN-01 finding with HIGH severity, locations
$ #         (spec.md / plan.md), and distinct summary wording
$ # Return to standard analyze logic; do NOT check for tasks
```

### Example 4: Delivery Strategy Present but No Rollout Tasks

```
$ scripts/bash/rollout-gate.sh
hasFlags=true
flags=feature-flag-gamma
source=spec.md
hooksEnabled=true

$ # Step B1: Suppress false positives for marker
$ # Step B2: Check for Delivery Strategy section → FOUND
$ # Step B3: Check for rollout tasks → NOT FOUND
$ # Result: Emit ROLLOUT-CHAIN-02 finding with HIGH severity, locations
$ #         (plan.md / tasks.md), and distinct summary wording
$ # Return to standard analyze logic
```

---

## Summary: Four User Stories Implemented

1. **User Story 1 (Consistent chain, no false orphans)**: When marker, Delivery Strategy, and rollout tasks are all present, suppress false-positive orphan/gap findings via **Step B1** (no chain-break findings emitted, standard analyze proceeds cleanly).

2. **User Story 2 (Non-rollout feature, zero overhead)**: When no marker is found, emit one-line no-op via **Step A** and skip all rollout-chain checks (standard analyze report unaffected).

3. **User Story 3 (Detect spec-to-plan break)**: When marker is present but Delivery Strategy section is absent, emit `ROLLOUT-CHAIN-01` finding via **Step B2** (distinct wording, HIGH severity, locations spec.md/plan.md).

4. **User Story 4 (Detect plan-to-tasks break)**: When Delivery Strategy section is present but no rollout tasks are found, emit `ROLLOUT-CHAIN-02` finding via **Step B3** (distinct wording, HIGH severity, locations plan.md/tasks.md).

---

## Determinism & Idempotence

- Gate script behavior is deterministic (same marker → same `hasFlags` output).
- Heading detection regex is case-insensitive and pattern-matched consistently.
- Task category presence checking uses keyword matching (allowing partial
  task sets, consistent with Feature 007 doctrine).
- Finding wording (IDs, Category, Severity, Summary) is fixed and does not
  vary between runs or substitute synonyms — preserving SC-005 determinism
  requirement.
- Multiple runs on unchanged artifacts produce identical findings.
