# Phase 1 Data Model: Rollout Implement Doctrine

This feature authors doctrine content, not application data. The "entities"
below are the conceptual objects the doctrine in `commands/brief-implement.md`
instructs the acting agent to recognize and operate on at runtime. There is no
new persisted schema; each entity's canonical shape is defined elsewhere and
only referenced here.

## Entity: Provider-Neutral Intent

One of exactly seven named actions the doctrine defines in natural language,
which the agent binds to a real MCP tool discovered via introspection.

| Field | Description |
|---|---|
| `name` | One of: discover environments, discover segments, create flag, set targeting, set percentage rollout, read flag status, archive flag |
| `bound_tool` | The MCP tool name(s) actually advertised by the configured server that the agent selects to satisfy this intent, determined at runtime — never hardcoded in the doctrine |
| `bindable` | Whether the currently-introspected MCP server advertises at least one tool the agent judges suitable for this intent; if false, the intent is skipped (FR-013) and execution continues for the rest |

**Source of truth**: vision.md §6.1 and §4 define the seven intents;
Constitution Principle IV requires binding only via runtime introspection,
never a maintained capability contract.

**Lifecycle**: re-resolved on every `/speckit.implement` run (no caching of
`bound_tool` across runs, since the MCP server's advertised catalogue may
change between runs).

## Entity: Pinned MCP Server Reference

The canonical, non-secret configuration identifying which MCP server process
to launch/connect to.

| Field | Description |
|---|---|
| `command` | Launcher command for the MCP server process |
| `args` | Launch arguments |
| `version` | Version constraint for the pinned server |
| `repository` | Source repository URL for the official server |
| `token_env_var` | Name only (e.g., `LAUNCHDARKLY_API_TOKEN`) of the environment variable the MCP server process reads at launch — never a token value |

**Source of truth**: `rollout-config.template.yml`'s `mcp.*` block (Feature
002's schema). This feature assumes the block is resolvable at
`/speckit.implement` time; populating real values into it is Feature 011's
responsibility (spec.md Assumptions).

**Constraint**: The doctrine MUST instruct using this reference exactly as
resolved, never substituting an alternative server (FR-005, Constitution
Principle IV).

## Entity: Rollout Task

An entry in `tasks.md` (Feature 007's doctrine) describing one concrete
provider action to perform.

| Field | Description |
|---|---|
| `category` | One of Feature 007's six categories: create flag, configure environments, configure targeting, integrate SDK, add telemetry validation, define rollback conditions |
| `flag_name` | The candidate flag this task instance is scoped to (Feature 007 emits the six-task pattern once per named flag) |
| `source_fields` | The specific Delivery Strategy field(s) (Feature 006) the task's description traces back to |

**Source of truth**: `commands/brief-tasks.md` (Feature 007) defines
generation; this feature only consumes existing entries, never regenerates
or re-derives them from `spec.md` or `plan.md` directly (FR-008, Constitution
Principle III).

**Consumption rule**: This feature's doctrine executes only the
"create flag," "configure environments," and "configure targeting"
categories via MCP tool calls (spec.md User Story 1); "integrate SDK,"
"add telemetry validation," and "define rollback conditions" are non-provider
implementation work handled by the rest of `/speckit.implement`'s normal
flow, unaffected by this doctrine.

## Entity: Plan-Only-Mode Task

The single remediation task the doctrine instructs recording when no MCP
server is reachable at runtime.

| Field | Description |
|---|---|
| `trigger` | MCP not configured, not reachable, or introspection failed at runtime (determined by a connection attempt, not a static config-presence check — spec.md Assumptions) |
| `remediation_reference` | Names `speckit.rollout.connect` (Feature 011) as the command to run; contains no inline MCP setup steps of its own (FR-012) |
| `cardinality` | Exactly one per `/speckit.implement` run in this state, regardless of how many rollout tasks or candidate flags exist (FR-011, SC-002) |

**Source of truth**: vision.md §6.3 (graceful degradation); Constitution
Principle VI's degrade-gracefully clause.

## Relationships

```text
spec.md `## Delivery Considerations` marker (Feature 004/005)
   │  (gate script, default mode — FR-001/FR-002)
   ▼
tasks.md rollout tasks present? (Feature 007 categories — FR-003/FR-004)
   │
   ├─ absent ──► distinct status message, stop (no MCP introspection)
   │
   └─ present
        │
        ▼
Pinned MCP Server Reference (rollout-config.template.yml `mcp.*`)
        │  (runtime introspection: tools/list, resources/list, prompts/list — FR-006)
        ▼
Provider-Neutral Intents (×7) bound to advertised tools (FR-007)
        │  (parameters sourced from plan.md Delivery Strategy + tasks.md rollout tasks — FR-008)
        ▼
Execute rollout tasks via bound tools, subject to:
   - production-exposure guardrail (FR-009, Constitution Principle VI)
   - token non-disclosure guardrail (FR-010, Constitution Principle V)

If MCP unreachable at any point in the above ──► Plan-Only-Mode Task (FR-011)
```

## State Transitions

This feature introduces no persisted state machine. The only "state" is the
per-run decision path above, re-evaluated fresh on every `/speckit.implement`
invocation (no state is cached between runs, consistent with Feature 008's
"re-check every time" treatment of the rollout chain).
