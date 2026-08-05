---
description: "rollout: pre-implement briefing — MCP introspection, provider-neutral intent binding, and guardrailed task execution"
---

# `speckit.rollout.brief-implement`

**Role**: When `/speckit.implement` runs, determine whether the feature's `spec.md` carries a `## Delivery Considerations` marker (rollout flag intent); if marked, detect rollout tasks in `tasks.md`, then instruct the agent to introspect the pinned LaunchDarkly MCP server at runtime, bind seven provider-neutral intents to its advertised tools, execute rollout provider actions (create flag, configure environments, configure targeting) using parameters from `plan.md`'s Delivery Strategy and `tasks.md`'s rollout tasks, and enforce two non-negotiable guardrails (never auto-advance production exposure, never leak the API token). If the marker is absent, no MCP introspection. If the marker is present but rollout tasks are missing, emit a distinct status and recommend `/speckit.tasks`. If no MCP server is reachable, continue in plan-only mode and record a setup task referencing `speckit.rollout.connect`.

**Status**: Active doctrine. This docstring and the instructions below replace the placeholder body, implementing the full pre-implement logic specified in `docs/foundation/vision.md` (§4, §6, §8) and refined in `specs/010-rollout-implement-doctrine/`.

---

## Your Task

Your task is to decide whether to inject rollout provider actions into the `/speckit.implement` flow, and if so, to instruct the agent on how to perform them safely, bound to actual MCP capabilities, with parameters sourced from the plan and tasks. Follow the branching logic below.

---

## Step 1: Invoke the Rollout Gate Script (First Gate Check)

Before making any decision, invoke the shared rollout-detection gate script to check whether `spec.md` carries a `## Delivery Considerations` marker:

```bash
scripts/bash/rollout-gate.sh
```

(If you are on Windows or PowerShell, use `scripts/powershell/rollout-gate.ps1` instead. The output format is identical.)

The script will output four lines:

```
hasFlags=<true|false>
flags=<comma-separated names>
source=<spec.md|plan.md|tasks.md|(empty)>
hooksEnabled=<true|false>
```

**What the output means**:
- `hasFlags=true`: A `## Delivery Considerations` marker (with flag names) was found in `spec.md`.
- `hasFlags=false`: No marker was found, or hooks are disabled.
- `flags`: If marker exists, the comma-separated list of candidate flag names.
- `source`: Which file the marker was found in (typically `spec.md` for this briefing).
- `hooksEnabled`: Whether the rollout extension's hooks are enabled in config (informational; does not affect your branching decision).

**Important**: The gate script is the source of truth for marker presence. Use its `hasFlags` output to branch your logic.

---

## Step 2: Decision Branches

### Branch A: No Rollout Marker (`hasFlags=false`)

**Scenario**: The feature carries no `## Delivery Considerations` marker in `spec.md`. This indicates no rollout intent.

**Your action**: Emit a single, one-line status message (for example: "No rollout marker detected; proceeding with standard implementation.") and proceed with the rest of `/speckit.implement` exactly as if the `rollout` extension were not installed. **Zero MCP introspection, zero provider actions, zero rollout-related tasks.**

---

### Branch B: Marker Present (`hasFlags=true`); Check for Rollout Tasks (Second Gate)

**Scenario**: A `## Delivery Considerations` marker was found in `spec.md`. Before proceeding to MCP introspection and provider execution, you must verify that `tasks.md` actually contains rollout tasks (Feature 007 categories: create flag, configure environments, configure targeting, integrate SDK, add telemetry validation, define rollback conditions) — this is the second, feature-specific gate that ensures strict content lineage.

**Your action**: Scan `tasks.md` for the presence of one or more lines matching the rollout task categories established by Feature 007's doctrine. Look for task descriptions that contain phrases like "create flag", "configure environments", "configure targeting", "integrate SDK", "add telemetry validation", or "define rollback conditions".

#### Sub-Branch B1: Rollout Tasks Absent (Marker Present, No Tasks)

**Scenario**: `hasFlags=true`, but `tasks.md` contains none of Feature 007's six rollout task categories. This indicates the feature was flagged for rollout intent during specify/clarify, but the tasks phase either was not run, or ran before the tasks-phase rollout doctrine was active, or no rollout tasks were generated.

**Your action**: Emit a single, one-line status message distinct from the no-marker case (for example: "Rollout marker detected but no rollout tasks found in tasks.md; run `/speckit.tasks` to generate them.") and **do not proceed with MCP introspection or provider action**. Continue with the rest of `/speckit.implement`'s normal flow (non-rollout implementation work).

**Critical rule**: Do NOT attempt to regenerate, infer, or fabricate rollout task content from `spec.md`'s requirements text or `plan.md`'s Delivery Strategy section as a substitute or fallback. The absence of rollout tasks means the tasks phase has not yet captured the concrete actions to perform.

---

#### Sub-Branch B2: Rollout Tasks Present (Both Gates Pass)

**Scenario**: `hasFlags=true` and `tasks.md` contains one or more rollout tasks from Feature 007's categories. Both gates pass; proceed to MCP introspection and provider execution.

**Your action**: Proceed to **Step 3: Prepare for MCP Introspection and Provider Execution** (below).

---

## Step 3: Prepare for MCP Introspection and Provider Execution

You are about to instruct the agent to perform actual provider actions via the LaunchDarkly MCP server. This section establishes the foundation: where to find the MCP server configuration, how to introspect it safely, and the provider-neutral vocabulary you will bind to its tools.

### Step 3.1: Locate and Load the Pinned MCP Server Configuration

Instruct the agent to:

1. **Load the project's rollout configuration** from the resolved location (typically `rollout-config.yml` or equivalent, containing the `mcp.*` block with the MCP server's launch command, args, version constraint, repository URL, and the token environment variable name).

2. **Use exactly that pinned configuration**. Do NOT search for or substitute an alternative LaunchDarkly MCP server implementation. Do NOT fall back to a different version or repository. The pinned reference is the source of truth. (FR-005, Constitution Principle IV)

3. **Extract the following details from the pinned configuration**:
   - **MCP launcher command** (e.g., `mcp run`, `npx`, docker command, or custom launcher)
   - **MCP launcher args** (typically including `--model`, version constraints, or server-specific flags)
   - **Token environment variable name** (e.g., `LAUNCHDARKLY_API_TOKEN`) — use this name only; do NOT ask for, read, or echo the actual token value

### Step 3.2: Instruct Runtime MCP Introspection

Instruct the agent to:

1. **Establish a connection to the configured MCP server** using the pinned launcher command and args from Step 3.1.

2. **Introspect the server at runtime** by invoking the following standard MCP discovery operations (in any order, potentially in parallel):
   - `mcp tools list` (or `tools/list`) — retrieves the list of available tools the server advertises
   - `mcp resources list` (or `resources/list`) — retrieves available resources the server exposes
   - `mcp prompts list` (or `prompts/list`) — retrieves available prompts the server provides

3. **Capture the introspection results** in a structured form. Each tool's name, description, and input schema will be used in the next step to bind provider-neutral intents.

**Why introspection is mandatory**: The LaunchDarkly MCP server's advertised tool catalogue may change between releases, and the MCP protocol itself is designed for dynamic discovery. Hardcoding tool names or assuming a fixed API contract violates Constitution Principle IV (provider-neutral, runtime-bound doctrine). Always introspect.

### Step 3.3: Define the Seven Provider-Neutral Intents

You will now instruct the agent to bind each of the following **provider-neutral intents** (named actions, expressed in natural language) to the real tools the MCP server actually advertised in Step 3.2. These intents are the bridge between the rollout feature's doctrine and the specific LaunchDarkly API.

**Provider-Neutral Intent 1: Discover Environments**
- *Purpose*: Retrieve the list of all deployment environments (e.g., staging, production, canary) available for flag targeting within the LaunchDarkly project.
- *Binding rule*: Select the tool from the introspection results (Step 3.2) that best matches this capability. Typical tool name: something like `list_environments`, `getEnvironments`, or similar.
- *Fallback*: If the MCP server does not advertise a tool for this intent, note the gap and skip this action (but continue with other intents). (FR-013)

**Provider-Neutral Intent 2: Discover Segments**
- *Purpose*: Retrieve the list of user segments or audience definitions available for targeting within the project (e.g., "beta users", "internal team", "high-value customers").
- *Binding rule*: Select the tool that best matches this capability. Typical tool name: something like `list_segments`, `getSegments`, or similar.
- *Fallback*: If unavailable, skip this action and continue.

**Provider-Neutral Intent 3: Create Flag**
- *Purpose*: Create a new feature flag in the LaunchDarkly project with the flag name and initial configuration specified in the rollout tasks.
- *Binding rule*: Select the tool that best matches this capability. Typical tool name: something like `create_flag`, `createFeature`, or similar.
- *Input sources*: The flag name MUST be sourced from `tasks.md`'s rollout tasks (Feature 007), which in turn traces back to the `Candidate flag(s):` line in `spec.md`'s marker. Do NOT invent the flag name; do NOT derive it directly from `spec.md`'s requirements text without the tasks linkage. (FR-008, Constitution Principle III)
- *Fallback*: If unavailable, skip and note; continue with other intents.

**Provider-Neutral Intent 4: Set Targeting**
- *Purpose*: Configure which environments or segments (if any) should receive the flag, and any prerequisites or attribute-based targeting rules needed.
- *Binding rule*: Select the tool that targets/rules are usually configured with. Typical tool name: something like `update_targeting`, `setRules`, or similar.
- *Input sources*: The targeting rules MUST be sourced from `plan.md`'s `## Delivery Strategy` section and `tasks.md`'s "configure targeting" rollout task. Do NOT invent rules; do NOT source them directly from the spec. (FR-008, Constitution Principle III)
- *Fallback*: If unavailable, skip and note; continue.

**Provider-Neutral Intent 5: Set Percentage Rollout**
- *Purpose*: Configure the percentage of traffic (0–100%) that should receive the flag in one or more environments, as specified in the plan's rollout phases.
- *Binding rule*: Select the tool that manages percentage-based gradual rollout. Typical tool name: something like `set_rollout_percentage`, `setTraffic`, or similar.
- *Input sources*: The percentages MUST be sourced from `plan.md`'s `## Delivery Strategy` section (e.g., "Phase 1: 5% production", "Phase 2: 25% production") and `tasks.md`'s "configure targeting" or "set percentage rollout" rollout tasks. Do NOT use different percentages or phases not mentioned in the plan. (FR-008, Constitution Principle III)
- *Guardrail*: **NEVER advance production exposure beyond what the current task or plan explicitly specifies, unless the user has explicitly instructed that specific advance in the current session.** For example, if the plan specifies "Phase 2: 5% production" and you are currently executing Phase 1, do NOT call a tool to set production to 25% — only 5%. If the user explicitly says "roll it out to 25% now", that is a current-session explicit instruction and you may do so, but only for that specific request. (FR-009, Constitution Principle VI)
- *Fallback*: If unavailable, skip and note; continue.

**Provider-Neutral Intent 6: Read Flag Status**
- *Purpose*: Retrieve the current state of the flag (enabled/disabled, percentage rollout per environment, segment targeting) for verification or logging purposes.
- *Binding rule*: Select the tool that retrieves flag state. Typical tool name: something like `get_flag`, `describeFlagStatus`, or similar.
- *Input sources*: The flag name MUST match the flag being created/configured in Intents 3–5.
- *Fallback*: If unavailable, skip and note; continue.

**Provider-Neutral Intent 7: Archive Flag**
- *Purpose*: Archive or remove the flag if rollback conditions are met (e.g., if rollout failed or the feature is no longer needed) — performed only when explicitly specified in the tasks.
- *Binding rule*: Select the tool that archives or deletes flags. Typical tool name: something like `archive_flag`, `deleteFeature`, or similar.
- *Input sources*: Only invoke this intent if `tasks.md` explicitly includes a "define rollback conditions" rollout task that specifies archiving the flag.
- *Fallback*: If unavailable and a rollback condition is met, note the gap and proceed without archiving.

---

## Step 4: Execute Rollout Provider Actions via Bound Intents

With the seven intents bound to the MCP server's real tools (from Step 3.3), instruct the agent to:

1. **For each candidate flag named in `tasks.md`'s rollout tasks** (Feature 007), and **in the order of the six task categories** (create, configure environments, configure targeting, integrate SDK, add telemetry validation, define rollback conditions), proceed as follows:

2. **Create Flag** (If "create flag" task exists):
   - Invoke the tool bound to Intent 3 (Create Flag).
   - Pass the flag name from the task.
   - Use any initial configuration (feature family, description, default rules) if specified in the Delivery Strategy or task.
   - Log or report the flag creation result. (Do NOT log or echo the API token; see Guardrail 2 in Step 5 below.)

3. **Configure Environments** (If "configure environments" task exists):
   - Invoke the tool bound to Intent 1 (Discover Environments) to list available deployment environments.
   - For each environment named in the Delivery Strategy section, invoke the tool bound to Intent 4 (Set Targeting) to enable or configure the flag in that environment.
   - Report any environment that could not be configured.

4. **Configure Targeting & Percentage Rollout** (If "configure targeting" task exists):
   - Invoke the tool bound to Intent 2 (Discover Segments) if segment-based targeting is specified.
   - Invoke the tool bound to Intent 4 (Set Targeting) to apply segment rules, user attribute rules, or other targeting logic from the Delivery Strategy.
   - Invoke the tool bound to Intent 5 (Set Percentage Rollout) to set the initial percentage rollout according to the plan's first phase. For example, if the plan specifies "Phase 1: 2% production", invoke the tool with 2% (not 5%, not 100%).
   - **Guardrail reminder**: Do NOT exceed the percentages specified in the plan's current phase without explicit user instruction. (FR-009)
   - Report results.

5. **Verify Flag Status** (Optional; if "read flag status" verification is specified):
   - Invoke the tool bound to Intent 6 (Read Flag Status) to confirm the flag's current configuration matches what was just set.
   - Log the results for audit purposes.

6. **Non-Provider Rollout Tasks** (Remaining categories: Integrate SDK, Add Telemetry Validation, Define Rollback Conditions):
   - These task categories do NOT involve MCP tool invocation; they are implementation work handled by the rest of `/speckit.implement`'s normal flow.
   - Include them in the task execution plan normally; this doctrine simply does not inject provider-specific actions for them.

---

## Step 5: Enforce Non-Negotiable Guardrails

### Guardrail 1: Production Exposure (NON-NEGOTIABLE)

**Rule**: NEVER invoke any MCP tool that would advance a flag's live production exposure (e.g., increasing the production percentage rollout already serving live traffic, or enabling a flag in a production environment) beyond what the current task or plan explicitly specifies, unless the user has explicitly instructed that specific advance in the current `/speckit.implement` session.

**Examples of forbidden actions without explicit current instruction**:
- Plan specifies "Phase 1: 2% production"; you call a tool to set it to 5% production.
- Plan specifies staging/canary only; you call a tool to enable the flag in production without current user instruction.
- Current task targets "internal team segment"; you call a tool to add "all users" targeting.

**Example of allowed action**:
- User explicitly says in the current session: "Update the rollout percentage to 10% in production now."
- You then invoke the tool to set production to 10% (and only 10%, no further).

**Principle**: This rule directly enforces Constitution Principle VI — guardrailed provider execution. Production exposure changes are the highest-risk aspect of rollout automation, and they require explicit, current authorization.

### Guardrail 2: Token Handling (NON-NEGOTIABLE)

**Rule**: NEVER read, echo, log, or inline the provider API token under any circumstance. The token belongs to the MCP server process and is handled via environment variable by that process, not by this briefing or the implementing agent.

**Examples of forbidden actions**:
- Reading the token from the configuration and echoing it in logs.
- Requesting the token from the user or printing it in any output.
- Embedding a token value or placeholder in tool invocation arguments (the MCP client handles this; you do NOT).
- Logging tool call arguments if they contain sensitive fields (redact as needed).

**Credential handling boundary**: The `LAUNCHDARKLY_API_TOKEN` environment variable (or whatever name is specified in the pinned config) is read by the MCP server process at launch, not by you. Your role is to pass the correct environment variable name to the MCP launcher, not to handle the token value itself.

---

## Step 6: Handle MCP Reachability and Graceful Degradation

### Scenario: MCP Not Configured, Not Reachable, or Introspection Failed

If at any point during Steps 3–4 (introspection, tool binding, or execution) the MCP server is determined to be unavailable (not configured in the resolved rollout configuration, connection fails, introspection times out, or returns an error), **do NOT fail the overall `/speckit.implement` run**. Instead:

1. **Continue implementation in plan-only mode**: Proceed with all non-rollout work normally (entity generation, non-rollout task execution, standard output).

2. **Record exactly one setup task** (not multiple, not zero) that directs the user to configure the MCP connection:

   ```
   [ ] Setup: Configure LaunchDarkly MCP server (run `speckit.rollout.connect` to set up the provider connection)
   ```

   - Reference `speckit.rollout.connect` as the command to run; do NOT include inline MCP registration, installation, or authentication steps (those are Feature 011's responsibility, currently a placeholder).
   - Include a brief note that the provider actions (create flag, configure environments, configure targeting) could not be performed until the MCP is connected.

3. **Do NOT simulate or fabricate provider actions**: Do NOT invent tool calls, fake API responses, or pretend actions were performed. The task simply records "this could not be done; run this command to fix it."

4. **MCP Partial Capability Fallback** (FR-013): If the MCP server is reachable but does not advertise a tool for one of the seven provider-neutral intents, skip only that specific intent's actions, note that they could not be performed (e.g., "Could not discover segments; tool not available"), and continue with the intents you could bind. Do NOT fail the entire run.

---

## Step 7: Token Guardrail Final Check

Before completing the briefing, **confirm that no token value or placeholder appears anywhere in your output or instructions to the agent**. Check:

- No direct token value is printed or logged.
- No placeholder like `YOUR_TOKEN_HERE` or `<api-key>` appears in any example or instruction.
- Any mention of the token is strictly instructional (e.g., "the MCP server reads the token from the `LAUNCHDARKLY_API_TOKEN` environment variable; do not echo it in logs").

If you find any token-like value in your output, **remove it immediately**. This is a non-negotiable guardrail.

---

## Summary of Decision Logic (Visual Tree)

```
Gate Script (spec.md marker check)
    │
    ├─ hasFlags=false ──► [Branch A]
    │   └─► One-line no-op
    │   └─► STOP: Zero MCP introspection, zero provider actions, zero rollout tasks
    │
    └─ hasFlags=true
        │
        ├─ tasks.md has rollout tasks? ──► YES ──► [Branch B2]
        │   │
        │   └─► [Step 3] MCP Introspection
        │   └─► [Step 4] Execute rollout tasks (create/config/targeting) via bound tools
        │   └─► [Step 5] Enforce guardrails
        │   └─► [Step 6] Handle degradation if needed
        │   └─► Continue with rest of /speckit.implement
        │
        └─ NO ──► [Branch B1]
            └─► Distinct status message: "Rollout tasks not found; run /speckit.tasks"
            └─► STOP: Zero MCP introspection, zero provider actions
            └─► Continue with rest of /speckit.implement
```

---

## Implementation Checklist

Use this checklist to verify you have addressed all functional requirements:

- [ ] **FR-001**: Invoked the rollout gate script against `spec.md` in default mode before any rollout behavior
- [ ] **FR-002**: If `hasFlags=false`, emitted a one-line no-op with zero MCP introspection or provider action
- [ ] **FR-003**: If `hasFlags=true`, scanned `tasks.md` for rollout task presence (Feature 007 categories)
- [ ] **FR-004**: If rollout tasks absent, emitted a distinct status message recommending `/speckit.tasks`, with zero MCP introspection
- [ ] **FR-005**: Instructed using exactly the pinned LaunchDarkly MCP server reference, never a substitute
- [ ] **FR-006**: Instructed runtime introspection via `tools/list`, `resources/list`, `prompts/list` before binding any tool
- [ ] **FR-007**: Defined all seven provider-neutral intents (discover environments, discover segments, create flag, set targeting, set percentage rollout, read flag status, archive flag)
- [ ] **FR-008**: Instructed executing rollout tasks using parameters from `plan.md`'s Delivery Strategy and `tasks.md`'s rollout tasks, never invented or re-derived from `spec.md` alone
- [ ] **FR-009**: Instructed never advancing production exposure beyond current task/plan scope without explicit user instruction (production-exposure guardrail, NON-NEGOTIABLE)
- [ ] **FR-010**: Instructed never reading/echoing/logging/inlining the provider token; confirmed no token value appears in this briefing (token-handling guardrail, NON-NEGOTIABLE)
- [ ] **FR-011**: Instructed plan-only mode (continue without failing) when MCP is unreachable, with graceful degradation
- [ ] **FR-012**: Did NOT include MCP registration/setup instructions beyond naming `speckit.rollout.connect` (Feature 011 scope)
- [ ] **FR-013**: Instructed skipping only affected actions when MCP doesn't advertise a tool for one of the seven intents, continuing with the rest
- [ ] **FR-014**: This briefing body (replacing the placeholder in `commands/brief-implement.md`) contains the full pre-implement doctrine

---

## End of Pre-Implement Briefing

The doctrine above is complete. Proceed with the remainder of `/speckit.implement`, applying the rollout provider actions as instructed (if applicable) and continuing with standard implementation work for all other aspects of the feature.
