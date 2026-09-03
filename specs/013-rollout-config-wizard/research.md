# Research Notes: Hosted vs. Local LaunchDarkly MCP Server Detection

**Feature**: 013-rollout-config-wizard
**Date**: 2026-08-07 (specify-phase grounding); extended 2026-08-12 (plan-phase Phase 0 research)
**Purpose**: Ground the spec's FR-008 (automatic hosted-vs-local server-type
detection) in LaunchDarkly's actual documented MCP server behavior. This
doubles as this feature's Phase 0 research output — the Technical Context in
`plan.md` has no other NEEDS CLARIFICATION items requiring research (this is
a markdown-doctrine-only feature; see plan.md).

## Sources consulted

- This project's `.vscode/mcp.json` (already configured for testing).
- <https://launchdarkly.com/docs/home/getting-started/mcp-hosted>
- <https://launchdarkly.com/docs/home/getting-started/mcp-local>
- <https://launchdarkly.com/docs/home/getting-started/mcp> (tool-list overview)
- <https://mcp.launchdarkly.com/mcp/launchdarkly> (hosted server's own published tool catalogue, 120 tools)
- <https://github.com/launchdarkly/mcp-server> (the local/self-managed server's own README and operation catalogue)

## Finding 1: This project's configured server is the hosted server

`.vscode/mcp.json` registers:

```json
{
  "servers": {
    "launchdarkly/mcp-server": {
      "type": "http",
      "url": "https://mcp.launchdarkly.com/mcp/launchdarkly"
    }
  }
}
```

This is the hosted server's canonical URL (`mcp.launchdarkly.com/mcp/launchdarkly`),
confirmed against the hosted-server doc's manual-configuration examples for
Cursor/Claude Code/Windsurf/Copilot, all of which point at the same URL. This
is useful as a concrete, already-available hosted-branch test fixture for
this feature's future plan/implement phases.

## Finding 2: Hosted vs. local are structurally different transports, not just a flag

- **Hosted**: `type: "http"` / `url: "https://mcp.launchdarkly.com/mcp/launchdarkly"`,
  authenticated via OAuth to the developer's whole LaunchDarkly account.
  Explicitly documented as covering multiple product areas (feature
  management, AgentControl, observability) across the account, implying
  account-wide, multi-project awareness.
- **Local**: `command: "npx"` (or a local Node build), with a **single,
  project/environment-scoped API access token** passed directly as an
  `--api-key` argument or `LD_ACCESS_TOKEN`-style env var. The local server
  is documented specifically for **federal and EU environments**, where the
  hosted server is unavailable, and LaunchDarkly's own docs recommend the
  hosted server everywhere else.

This confirms the spec's premise: hosted and local are two distinct,
mutually exclusive server types the wizard must tell apart, not a
configuration toggle on one server.

## Finding 3: Concrete confirmation — `list-projects` exists on hosted, has no local counterpart

The hosted server's own published tool catalogue (`https://mcp.launchdarkly.com/mcp/launchdarkly`,
120 tools) includes an explicit **`list-projects`** tool: *"List LaunchDarkly
projects in the account. Use to discover project keys before calling
project-scoped tools."* This is a direct, account-wide project-listing
capability, exactly matching FR-008's premise.

The local server's own GitHub repository
(`https://github.com/launchdarkly/mcp-server` — confirmed by its own README
banner to be "the local Model Context Protocol (MCP) server for LaunchDarkly
federal and European Union (EU) environments," recommending the hosted
server instead where available) documents its available operations grouped
by resource category: `AiConfigs`, `AuditLog`, `CodeReferences`,
`Environments` (`listByProject` only — requires an already-known project
key), `FeatureFlags` (`getStatus`, `list`, `create`, `get`, `patch`,
`delete`). **There is no `Projects` resource category and no
project-listing operation anywhere in the local server's documented
operation set** — `Environments.listByProject` is the closest capability,
and it presupposes the project is already known, consistent with the local
server's single-API-key, single-project-scoped positioning.

**Conclusion / design implication**: This directly confirms FR-008's
detection premise with a concrete example (not just an inference from
transport/authentication differences): a `list-projects`-shaped tool is
real and hosted-only in practice today. FR-008 is nonetheless written
behaviorally ("whichever introspected tool lists the developer's
LaunchDarkly projects") rather than hardcoding the literal name
`list-projects`, consistent with this project's existing MCP-introspection
design principle (vision.md §6.1, Constitution Principle IV) — LaunchDarkly
could rename or restructure this tool without requiring a spec change, and
the wizard's behavioral test (success vs. failure/absence) remains valid
either way.


## Finding 4: Ambiguous failures must not block the wizard

Neither hosted nor local documentation describes a scenario where the same
probe could ambiguously return neither a clear success nor a clear
"tool not found" signal, but production MCP transports can still time out or
return a transport-level error uncorrelated with tool availability (e.g., a
network blip against the hosted server's HTTP endpoint). Since the spec's
job is to keep the wizard from stalling on transport noise, FR-008 treats
any non-clear-success outcome (including ambiguous errors and timeouts) as
local, letting the local branch's manual-entry-or-opt-out path (FR-011/
FR-012) absorb the uncertainty without blocking progress.

## Finding 5: MCP config transport shape alone is not a reliable hosted/local signal

The hosted server's own install page publishes a "raw configuration" fallback
for unlisted clients that registers it via a **stdio command**, not the
native `type: "http"`/`url` shape:

```json
{
  "command": "npx",
  "args": ["mcp-remote@0.1.25", "https://mcp.launchdarkly.com/mcp/launchdarkly"]
}
```

This is still the **hosted** server (proxied through the `mcp-remote` stdio
adapter) — it just happens to look, at the client-config level, exactly like
a `command`/`args`-shaped entry, the same shape the local server's own
install docs use (`npx ... @launchdarkly/mcp-server ... --api-key ...`).

**Conclusion / design implication**: A wizard heuristic based on the *shape*
of the saved MCP server entry (e.g., "has a `url` field → hosted; has a
`command` field → local") would misclassify an `mcp-remote`-proxied hosted
registration as local. This is an additional, concrete reason FR-008
requires a **live, behavioral** probe (attempt the project-listing call and
read the actual result) rather than any inference from the entry's
transport shape — reinforcing, not just Finding 3's tool-name point, why
detection must happen against the running server, not the saved
configuration.

