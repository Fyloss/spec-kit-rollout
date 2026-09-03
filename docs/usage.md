# Using `rollout`

This page is for **users** of the extension: how it fits into the Spec Kit
workflow you already run, day to day. For the underlying design rationale, see
[foundation/vision.md](foundation/vision.md). For provider configuration, see
[providers.md](providers.md).

## The one rule to remember

> You never call a `rollout` command to "turn on" rollout behavior for a
> feature. You just describe the feature normally, and `rollout` decides —
> transparently, via a marker in `spec.md` — whether to get involved.

The only commands you ever type yourself are the setup wizard,
`speckit.rollout.config`, and its companion switch command,
`speckit.rollout.provider`. Everything else is standard Spec Kit:

```mermaid
sequenceDiagram
    participant You
    participant SpecKit as Spec Kit
    participant Rollout as rollout hooks (silent)

    Note over You,Rollout: One-time, per project (you register the MCP server yourself first)
    You->>SpecKit: /speckit.rollout.config
    SpecKit->>Rollout: discovers your registered LaunchDarkly MCP server,\ndetermines hosted/local, saves project/environment selection

    Note over You,Rollout: Normal, repeated per feature
    You->>SpecKit: /speckit.specify "add payment refunds"
    SpecKit->>Rollout: before_specify hook
    Rollout-->>SpecKit: proposes Delivery Considerations (or stays silent)
    SpecKit-->>You: spec.md

    You->>SpecKit: /speckit.plan
    SpecKit->>Rollout: before_plan hook
    Rollout-->>SpecKit: adds Delivery Strategy (only if marker present)
    SpecKit-->>You: plan.md

    You->>SpecKit: /speckit.tasks
    SpecKit->>Rollout: before_tasks hook
    Rollout-->>SpecKit: adds rollout tasks (only if Delivery Strategy present)
    SpecKit-->>You: tasks.md

    You->>SpecKit: /speckit.implement
    SpecKit->>Rollout: before_implement hook
    Rollout-->>SpecKit: creates/configures the flag via MCP (only if rollout tasks present)
```

## Step-by-step

### 1. Register your MCP server, then run the wizard once per project

```bash
specify extension add <path-or-url-to-rollout> --dev
```

First, register the **official** LaunchDarkly MCP server yourself, in your
own Spec Kit client's native MCP settings (e.g. `.vscode/mcp.json`) —
`rollout` never writes, creates, or modifies that file (vision.md §6.2).
Export the actual token yourself, once, in your shell profile (see
[providers.md](providers.md#credentials)):

```bash
export LAUNCHDARKLY_API_TOKEN="..."
```

Then, inside your Spec Kit client:

```
/speckit.rollout.config
```

`speckit.rollout.config`:
- discovers, read-only, whichever LaunchDarkly-capable MCP server(s) you've
  already registered (stopping safely with guidance if it finds none, or
  asking you to pick if it finds more than one),
- automatically determines — without asking — whether your selected server
  is LaunchDarkly's **hosted** server or a **local** one,
- walks you through project/environment selection (live selection for a
  hosted server; manual entry or explicit opt-out for a local one),
- verifies read access, shows a full summary, and — only once you
  explicitly confirm — writes a `provider: launchdarkly` +
  `launchdarkly:` block to `rollout-config.yml`,
- **never writes a credential value**, and **never touches your client's
  own MCP configuration file**.

Re-running `speckit.rollout.config` at any time is safe — it always shows
your current selections first and lets you change any of them.

Already configured a provider and want to switch or add another one
without re-running the whole wizard?

```
/speckit.rollout.provider <provider_name>
```

This reuses an existing saved block for `<provider_name>` with zero
re-prompting, or triggers that provider's own config preset if none exists
yet.

### 2. Work normally — `/speckit.specify`

Describe your feature as usual. Nothing about how you write the description
changes. Behind the scenes, `before_specify` runs the shared gate script
against the *new* feature's `spec.md`, finds no marker yet (it's a brand-new
feature), and falls back to its own detection heuristics on your description:

| Signal category | Example |
|---|---|
| High-risk / irreversible change | payments, auth, data migration |
| Major UX change | a significant redesign of a user flow |
| Progressive / staged migration | a multi-step replacement rollout |
| Explicit cohort / audience language | beta, internal, canary, a percentage, a region |
| Performance/infra-sensitive change | meaningful blast radius |

- **Clear match** → the agent proposes a `## Delivery Considerations` section
  and explains why; you can accept or decline.
- **Ambiguous** → the agent asks exactly **one** targeted clarifying question,
  then proceeds based on your answer.
- **No match** → nothing is added; `spec.md` looks exactly as it would without
  the extension installed.

### 3. `/speckit.clarify` — the marker survives

If `spec.md` carries the marker, `before_clarify` treats it as legitimate spec
content — never as underspecified noise to strip out — and instead elicits any
missing rollout parameters (phases, audience, percentages, telemetry gates,
rollback conditions) directly into the marker section.

### 4. `/speckit.plan` — Delivery Strategy

If the marker is present, `before_plan` adds a `## Delivery Strategy` section
to `plan.md`: flag name(s), `Provider: LaunchDarkly`, phased rollout,
targeting, telemetry gates, rollback conditions. If you introduce rollout
intent for the *first time* at this phase (e.g., "release to 5% first" in your
`/plan` arguments) rather than at specify time, `before_plan` back-fills the
marker into `spec.md` so every later phase still sees it.

### 5. `/speckit.tasks` — concrete rollout tasks

If `plan.md` has a `Delivery Strategy` section, `before_tasks` emits ordered
tasks derived **from the plan** (never re-mined from the spec): create flag,
configure environments, configure targeting, integrate SDK, add telemetry
validation, define rollback conditions.

### 6. `/speckit.analyze` and `/speckit.checklist`

- `before_analyze` cross-checks that the marker (spec) ↔ Delivery Strategy
  (plan) ↔ rollout tasks (tasks) chain is consistent, and suppresses
  false-positive orphan/duplication findings for rollout content.
- `before_checklist` adds rollout-quality checklist items (flag naming,
  targeting, telemetry gates, rollback, phase ordering) when the chain exists.

### 7. `/speckit.implement` — real provider actions

If rollout tasks exist, `before_implement` introspects the LaunchDarkly MCP
server you registered and selected via `speckit.rollout.config`
(`tools/list`, `resources/list`, `prompts/list`) and executes the
create-flag / configure-environments / configure-targeting actions using the
parameters from `plan.md` and `tasks.md`. Two guardrails are always enforced:

- it **never** advances live production exposure beyond what the task/plan
  explicitly specifies, unless you say so explicitly in that session;
- it **never** reads, echoes, or logs the API token value.

If no MCP server or no configured project/environment is available, it
falls back to plan-only mode and records a single task pointing at
`/speckit.rollout.config`.

## What "near-zero noise" looks like

Every hook self-gates on a single shared script before doing anything else:

```bash
scripts/bash/rollout-gate.sh
# hasFlags=<true|false>
# flags=<comma-separated candidate flag names>
# source=<spec.md|plan.md|tasks.md|(empty)>
# hooksEnabled=<true|false>
```

For a feature with no rollout signal, every phase's hook prints one line and
stops — the generated `spec.md`/`plan.md`/`tasks.md` are byte-for-byte what
you'd get without `rollout` installed at all.

## Turning it off

- **Per team**: set `hooks.enabled: false` in
  `.specify/extensions/rollout/rollout-config.yml` (see
  [providers.md](providers.md) for the full config layering).
  Also see [providers.md](providers.md#credentials) for token handling.
- **Per project, permanently**: uninstall the extension.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| No `Delivery Considerations` proposed for an obviously risky feature | Description didn't match any heuristic strongly enough | Mention the risk/cohort explicitly, or add the section by hand — the marker format is documented in [foundation/vision.md](foundation/vision.md) §5.1 |
| `brief-implement` says "no rollout tasks found" | `tasks.md` was generated before `Delivery Strategy` existed in `plan.md` | Re-run `/speckit.tasks` |
| `speckit.rollout.config` says no LaunchDarkly-capable MCP server was detected | You haven't registered the official LaunchDarkly MCP server in your client yet | Register it yourself in your client's own MCP settings (e.g. `.vscode/mcp.json`), then re-run `/speckit.rollout.config` |
| MCP actions skipped during `/speckit.implement` | No MCP server selection saved, or project/environment not yet configured (local-branch opt-out) | Run `/speckit.rollout.config` to select your MCP server and set a project/environment(s) |
