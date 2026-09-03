# Spec Kit "rollout" Extension — Vision

## 1. Purpose

`rollout` is a Spec Kit extension that gives AI coding agents native fluency in
**progressive delivery**. When a user runs the standard Spec-Driven Development
(SDD) workflow, the agent gains the knowledge and tools to recognize when a
feature warrants feature-flagged / canary delivery and to fold a concrete rollout
strategy into its own specifications, plans, and tasks — and to execute the
required provider operations during implementation.

The extension delivers **instructional capability, not template surgery**. It
never rewrites Spec Kit core templates or generated markdown. It supplies
conditional, self-gating guidance (via hooks), provider tool access (via MCP),
and a single setup command.

**Provider scope (V1): LaunchDarkly only.** Unleash and GrowthBook are future
roadmap items; the design keeps a provider-neutral seam so they can be added
later without core changes.

## 2. Problem Statement

Today, when a user requests a feature that needs feature flags or progressive
delivery, an agent tends to emit manual, low-value tasks such as "Configure
LaunchDarkly" or "Create a feature flag in the dashboard." The agent has no
awareness that progressive-delivery capabilities exist or that it can act on them.

`rollout` removes this behavior. The agent learns to:

- identify the available feature-flag provider;
- understand existing provider configuration;
- discover environments and segments/audiences;
- create required feature flags;
- configure targeting rules;
- design canary / progressive rollout strategies;
- execute provider actions during implementation.

## 3. Personas

| Persona | Need | How `rollout` helps |
|---|---|---|
| Feature developer | Ship risky features safely without learning a flag workflow | Agent proposes flags + phased rollout inside normal SDD |
| Tech lead / architect | Consistent, reviewable delivery strategy | Rollout strategy appears as first-class content in `plan.md` |
| Platform / DevOps engineer | Governance over flag creation and provider access | Config-driven provider + scoped credentials |
| Release manager / on-call | Post-deploy control | Provider actions executed via the provider MCP (dashboard remains authoritative for day-2 ops) |
| Security engineer | No secret sprawl | Token consumed only by the MCP server process; never in the repo or the model context |

## 4. Expected Agent Behavior (by phase)

- **specify** — Capture delivery-risk / rollout intent as part of requirements
  when signals are present. Write a clearly labeled, greppable
  **`## Delivery Considerations`** marker (candidate flag + rollout intent) into
  `spec.md`. This marker is both natural spec content and the state signal used
  to gate later phases. Do **not** name a provider at this stage.
- **plan** — Introduce a **`## Delivery Strategy`** section: flag name, provider,
  phased rollout, targeting, telemetry gates, rollback conditions. Ground values
  in reality via provider discovery.
- **tasks** — Emit concrete, ordered rollout tasks (create flag, configure
  environments/targeting, integrate SDK, add telemetry validation, define
  rollback). **Derived from the plan's `Delivery Strategy`**, not regenerated
  from the spec.
- **implement** — Introspect the provider MCP and execute provider actions.
  **Derived from tasks + plan.** Guardrail: never auto-advance production exposure
  unless explicitly instructed.

### Rollout requirement detection (heuristics)

The agent treats a feature as a progressive-delivery candidate when it sees:
high-risk / irreversible changes (payments, auth, data migration); major UX
changes; progressive migrations; explicit cohort language (beta, internal,
canary, percentage, country/region); performance- or infra-sensitive changes.

Detection is advisory: on match the agent proposes a strategy and explains why;
on ambiguity it asks a single clarifying question; the user can always decline.

## 5. Spec Kit Integration Model

### 5.1 Mechanism: hooks + self-gating briefing commands

Spec Kit extensions can `provide` commands, config, templates, and **hooks**. A
hook binds a lifecycle event to a command that runs automatically
(`optional: false` = no user prompt). Spec Kit templates are **replace-not-merge**
(first-match-wins), so editing core templates would require forking them; hooks
are the only **additive**, composition-safe injection point. This is why the
extension uses hooks rather than a preset (see Decision D1).

The extension registers `before_*` hooks on **seven** lifecycle events. Each hook
runs a lightweight command whose markdown body carries the phase-appropriate
doctrine. Because the hook fires *before* the phase, the doctrine is in the
agent's context at the moment it produces the artifact — with no template edits
and no activation command.

| Hook | Role |
|---|---|
| `before_specify` | Inject detection doctrine; agent writes the `Delivery Considerations` marker when signals exist |
| `before_clarify` | Preserve the marker (never treat rollout as underspecified noise); elicit missing rollout parameters (phases, audience, %, telemetry, rollback) |
| `before_plan` | Produce the `Delivery Strategy` section |
| `before_tasks` | Emit rollout tasks derived from the plan |
| `before_analyze` | Validate rollout chain consistency (spec marker ↔ plan strategy ↔ tasks); do not flag rollout content as orphans |
| `before_checklist` | Add rollout-quality checklist items (flag naming, targeting, telemetry gates, rollback defined, phase ordering) |
| `before_implement` | Introspect provider MCP; execute provider actions; enforce guardrails |

### 5.2 Self-gating (conditional injection)

The manifest `condition` field is not yet implemented, so gating happens **inside**
each hook command via a cross-platform gate script (`sh` + `ps`):

1. The gate script greps the current feature's `spec.md` (and `plan.md` / `tasks.md`
   where relevant for `analyze`) for the `Delivery Considerations` marker.
2. **Marker absent** → the command emits a one-line no-op and stops → near-zero
   context pollution.
3. **Marker present** → it injects the full phase-appropriate doctrine.

Refinements:

- **Per-feature scoping.** State lives in the feature's own `spec.md`
  (`specs/<feature>/`), so it never leaks across features.
- **Late-introduced intent.** The "no-marker" branch keeps a minimal, cheap
  detection sniff of the phase arguments, so rollout intent introduced later
  (e.g., "release to 5% first" at `/plan`) is still caught and back-fills the
  marker.
- **Content lineage.** `spec.md` is consulted by the gate **only for flag / no-flag
  state**, never as the content source for later phases. Content follows the
  normal SDD chain: `plan ← spec`, `tasks ← plan`, `implement ← tasks + plan`.

### 5.3 Team toggle

Hooks are non-optional and lightweight, but can be **disabled via extension
config** for teams that never want the behavior. Uninstalling the extension is
also a valid off switch.

## 6. Provider Interaction Model

### 6.1 No wrapper, no capability contract — use the official MCP + introspection

The extension does **not** build an API wrapper or maintain a per-provider
capability contract. It relies on the **official LaunchDarkly MCP server** and on
MCP's built-in discovery (`tools/list`, `resources/list`, `prompts/list`), which
returns each tool's name, description, and JSON input schema. This is a standard,
self-describing, always-fresh source of truth aligned with real capabilities.

The doctrine describes only **provider-neutral intents** in natural language
(discover environments, discover segments, create flag, set targeting, set
percentage rollout, read flag status, archive flag). The agent introspects the
configured MCP at runtime and binds each intent to the real advertised tools.
Adding a new provider later is near-zero maintenance: the generic doctrine works
against any MCP; at most an optional advisory per-provider note is added.

### 6.2 Config reference or live discovery (supply-chain safety)

As of Feature 013, the extension no longer stores a pinned launcher
command/args/version/repository/token-env-var reference for the provider
MCP server. Instead, the developer registers the **official** LaunchDarkly
MCP server themselves, of their own choosing, directly in their own Spec
Kit client's native MCP settings (e.g. `.vscode/mcp.json`) — `rollout` never
writes, creates, or modifies that file. The `speckit.rollout.config` wizard
discovers whichever MCP server(s) the developer has already registered,
read-only, and the doctrine instructs the agent to use exactly the
developer's selected, already-registered server — never to search for or
substitute an alternative, forked, or typosquatted implementation.
Constitution Principle IV (v2.0.0) permits binding to an official provider
MCP server via **either** a single pinned config reference **or** this live
introspection-based discovery of the developer's own already-registered
server, re-verified fresh on every invocation (never cached) — this
extension uses the latter mode. Only the selected server's name/key (never
its launch command, arguments, version, repository, or a credential) is
saved, under the literal, flat key `mcp_server`, in `local-config.yml` (§8).

### 6.3 Graceful degradation

If no MCP is available, the agent runs in **plan-only mode**: it still documents
the Delivery Strategy and emits a "configure MCP / run setup" task, so the
workflow never hard-fails.

## 7. Setup Command (`speckit.rollout.config` / `speckit.rollout.provider`)

MCP registration is client-specific and is now the developer's own
responsibility, done once in their own client's native MCP settings, before
running any `rollout` command — `rollout` itself never writes, creates, or
modifies a client's MCP configuration file (superseding Feature 011's
`connect` command, which is permanently removed, not deprecated-alongside).

`speckit.rollout.config` is a **re-runnable, interactive setup wizard**
(distinct from day-2 operational commands, which remain intentionally
excluded — see Decision D2) that:

1. Discovers, read-only, whichever MCP server(s) the developer has already
   registered in their own client, and resolves to exactly one (stopping
   safely with guidance if zero are found, or asking the developer to
   disambiguate if more than one is found).
2. Automatically determines — never asking the developer directly — whether
   the selected server is LaunchDarkly's **hosted** server or a **local**
   one, via a live, read-only, never-cached probe re-verified on every run.
3. Walks the developer through project/environment selection appropriate to
   that server type (live introspected selection for hosted; manual entry
   or explicit opt-out, with no fabricated placeholders, for local).
4. Performs a read-only read-verification check, then requires an explicit
   final confirmation before writing anything.
5. Writes exactly one modular `provider: launchdarkly` + `launchdarkly:`
   config block to `rollout-config.yml` — never an MCP command/args/
   version/repository/token-env-var field, since that concept no longer
   exists (§6.2, §8).

It is safely re-runnable any number of times, changing only the selections
the developer chooses to change, and it never writes a credential value.

The sibling `speckit.rollout.provider <provider_name>` command lets a
developer switch the active `provider:` value — reusing an already-saved
config block with zero re-prompting, or triggering that provider's own
config preset (LaunchDarkly is the only real preset in V1) if none exists
yet — without re-running the whole wizard.

Client-agnostic core = one canonical server spec; client-specific = a small
per-integration adapter table (the same pattern Spec Kit uses for integrations).

## 8. Credential Security

- **V1 approach: a global OS environment variable** (e.g., `bashrc` / `zshrc`),
  consumed by the **MCP server process** at launch. The agent/LLM never sees the
  token, so it never enters the model context or reaches any cloud model. This is
  simultaneously the simplest and the most secure option, and it is fully
  client-agnostic (every Spec Kit client spawns MCP servers with inherited env).
- Committed config (`rollout-config.yml`) holds **non-secret pointers only**
  (provider id, project key, environment names, and the informational,
  never-cached `server_type` determination) — never a token, and, as of
  Feature 013, no MCP launcher field of any kind (`mcp.command`/`args`/
  `version`/`repository`/`token_env_var` no longer exist in this schema at
  all). The developer's chosen MCP server's name/key (never its launch
  details or a credential) is saved separately, under the literal, flat key
  `mcp_server`, in `.specify/extensions/rollout/local-config.yml`.
- The doctrine forbids the agent from reading, echoing, or inlining the token —
  reinforced by having no token-related field left in this project's own config
  to even inadvertently reference.
- Recommend a **scoped, least-privilege** LaunchDarkly token.
- **Rejected for V1:** editor secret stores (e.g., VS Code `SecretStorage`) — not
  client-agnostic, and risk exposing the secret if read into context; encrypted
  local file — requires an extra unlock/setup step.
- **Enterprise / future:** external secret managers (Vault, cloud) inject the env
  var into the MCP server process (`vault exec`, direnv, CI secrets) with no
  change to the model and no code in the extension.

## 9. Delivery Strategy in the Technical Plan

The `Delivery Strategy` block appears naturally inside `plan.md`, e.g.:

```
## Delivery Strategy
Feature flag: checkout_v2
Provider: LaunchDarkly
Rollout:
  Phase 1: Internal users
  Phase 2: 5% production
  Phase 3: 25%
  Phase 4: 100%
Targeting: EU segment first; internal group by email domain
Telemetry gates: checkout_error_rate < 0.5%, p95 latency < 400ms
Rollback: auto-disable flag if error_rate > 2% over 10 min
```

Corresponding `tasks.md` entries: create flag, configure environments, configure
targeting, integrate SDK, add telemetry validation, define rollback conditions.

**No mandatory `rollout.md` in V1** — the strategy lives in `plan.md` to avoid a
separate artifact/workflow. An optional structural template
(`templates/rollout-section.md`) may be provided for consistency but is never
required. A standalone `rollout.md` is a future consideration behind a config flag.

## 10. V1 Scope Boundaries

**In scope**

- LaunchDarkly only.
- Seven `before_*` self-gating hooks + briefing/doctrine command bodies.
- Provider access via the official LaunchDarkly MCP + runtime introspection
  (no wrapper, no capability contract).
- `speckit.rollout.config` guided setup wizard (re-runnable) and
  `speckit.rollout.provider` switch/preset command; no per-client adapter
  table, no client MCP configuration file is ever written (Feature 013).
- `Delivery Considerations` marker (spec) and `Delivery Strategy` section (plan),
  embedded in standard artifacts.
- Credential resolution via a global OS env var consumed by the MCP server.
- Cross-platform gate scripts (`sh` + `ps`).
- Team-level enable/disable via config.

**Out of scope (V1)**

- Unleash, GrowthBook.
- Operational / day-2 commands (flag-enable, flag-status, etc.).
- Custom LaunchDarkly API wrapper or maintained capability contract.
- Mandatory `rollout.md`.
- Automated production percentage advancement without explicit user action.
- CI/CD automated promotion.

## 11. Future Roadmap & Extension Points

**Roadmap:** Unleash, GrowthBook; optional standalone `rollout.md`; automated
telemetry-gated promotion; CI integration; optional companion preset for teams
that want the structure hard-baked into templates (installable together via a
Spec Kit **bundle**, one command).

**Extension points to preserve now:**

1. Provider-neutral intent vocabulary in the doctrine — a new provider is a doctrine
   note + MCP pin, no core changes.
2. `provider` config key with pluggable resolution (validated against a registry).
3. Modular doctrine: provider-neutral rollout content vs. provider-specific notes.
4. Credential chain is provider-agnostic; only the token env-var name varies.
5. `connect` adapter table extends per new client automatically from Spec Kit
   integrations.

   > **Superseded by Feature 013**: the `connect` command and its
   > per-client adapter table were permanently removed. Client coverage is
   > now automatic and adapter-free — `speckit.rollout.config` discovers
   > whichever MCP server the developer already registered in their own
   > client, regardless of which client that is, via generic MCP
   > introspection rather than a per-client mapping.

## 12. Proposed Extension Layout

```
spec-kit-rollout/
├── extension.yml                 # manifest: 7 before_* hooks, config + provider commands
├── README.md / LICENSE / CHANGELOG.md
├── commands/
│   ├── brief-specify.md          # detection doctrine + marker instructions
│   ├── brief-clarify.md          # preserve marker + elicit rollout parameters
│   ├── brief-plan.md             # Delivery Strategy doctrine
│   ├── brief-tasks.md            # rollout tasks (derived from plan)
│   ├── brief-analyze.md          # rollout-chain consistency checks
│   ├── brief-checklist.md        # rollout-quality checklist items
│   ├── brief-implement.md        # MCP introspection + provider actions + guardrails
│   ├── config.md                 # re-runnable guided setup wizard (Feature 013)
│   └── provider.md               # provider switch/preset command (Feature 013)
├── scripts/
│   ├── bash/rollout-gate.sh      # marker detection (state gate)
│   └── powershell/rollout-gate.ps1
├── templates/
│   └── rollout-section.md        # OPTIONAL Delivery Strategy structure
└── rollout-config.template.yml   # provider, modular per-provider project/env/server_type block (no MCP launcher fields, no secrets)
```

## 13. Decision Log (research conclusions & rationale)

- **D1 — Extension, not preset.** Spec Kit templates are replace-not-merge
  (first-match-wins), so a preset would require forking core templates, causing
  drift on Spec Kit updates and silent clobbering when a team runs another
  plan/tasks preset. Hooks are the only additive, composition-safe injection
  point, and only extensions provide hooks. The dominant work also spans both
  "integrate an external tool" and "shape artifact content," but the additive,
  conditional, tool-aware nature makes it capability territory.
- **D2 — No operational (day-2) commands.** Spec Kit is oriented around generating
  SDD artifacts, not runtime operations. Live flag control belongs to the provider
  (dashboard + MCP tools). Re-exposing it would duplicate provider capabilities
  and add drift. The agent can already perform provider actions during
  `/speckit.implement` via MCP. (`speckit.rollout.config`/`speckit.rollout.provider`
  are one-time-or-occasional setup/switch actions, not day-2 ops, and are
  retained on that same basis.)
- **D3 — Official MCP + introspection, no wrapper / no contract.** MCP's
  `tools/list` is a standard, always-fresh capability source; a maintained
  contract would go stale and cost maintenance per provider. Provider-neutral
  intents in the doctrine bind to introspected tools at runtime.
- **D4 — Global OS env var for credentials.** Consumed by the MCP server process,
  never by the LLM, so it never enters the model context; client-agnostic and
  low-friction. Editor secret stores (not agnostic, exposure risk) and encrypted
  files (extra step) were rejected for V1.
- **D5 — Self-gating hooks via marker.** Non-optional hooks avoid a pseudo
  activation prompt, and a script-based marker check keeps later-phase context
  clean when no flag is needed — deterministic, not LLM-re-decided.
- **D6 — Cover clarify / analyze / checklist.** These optional commands can
  otherwise strip the marker (`clarify`), flag rollout content as orphans
  (`analyze`), or miss rollout quality (`checklist`). Attaching the same
  self-gated hooks turns them into guardians of the rollout logic. Residual soft
  risk: with hooks disabled or on a client where they don't fire, content is not
  hard-protected (Spec Kit has no protected-region primitive); the clearly labeled
  marker and the multi-artifact SDD chain mitigate this.
```
