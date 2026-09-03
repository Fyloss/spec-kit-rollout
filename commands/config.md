---
description: "rollout: re-runnable guided setup wizard — discovers the developer's own registered LaunchDarkly MCP server, determines hosted vs. local, and writes a modular provider config block to rollout-config.yml"
visibility: "public"
mode: "user-invoked"
---

# `speckit.rollout.config`

**Role**: A re-runnable, interactive setup wizard that replaces the former
`speckit.rollout.connect` command. It never registers, writes, or modifies
any Spec Kit client's native MCP configuration file — the developer
registers their own official LaunchDarkly MCP server themselves, in their
own client's own MCP settings, before running this wizard. Instead, this
command discovers whichever MCP server(s) the developer has already
registered, determines (automatically, never by asking) whether the
selected server is LaunchDarkly's **hosted** server or a **local** one,
walks the developer through project/environment selection appropriate to
that server type, verifies read access, and — only after an explicit final
confirmation — writes exactly one modular `provider: launchdarkly` +
`launchdarkly:` config block to `rollout-config.yml`. No `mcp.command`,
`mcp.args`, `mcp.version`, `mcp.repository`, or `mcp.token_env_var` field is
ever written by this command; that concept has been permanently removed
(FR-001, FR-002, FR-017).

**User Stories Implemented**: US1 (hosted happy path), US2 (zero candidates
detected), US3 (multiple candidates require disambiguation), US4 (read
verification failure), US5 (safe re-run), US6 (provider selection UI), US7
(local branch: manual entry or opt-out).

The wizard always runs the same seven steps, in order, on every invocation
(including re-runs — see "Re-Run Behavior" below): **(1)** provider
selection, **(2)** MCP server discovery & candidate resolution, **(3)**
automatic server-type determination, **(4)** project selection (branches
hosted/local), **(5)** environment selection (branches hosted/local), **(6)**
read verification, **(7)** final confirmation, write, and report.

---

## Step 1: Provider Selection

Present a list of providers to the developer. In V1:

- **LaunchDarkly** — selectable.
- Any other provider name shown in this list (roadmap items such as
  Unleash, GrowthBook) MUST be displayed **visibly disabled**, with a
  "coming soon" label, and MUST NOT be selectable (FR-003; spec US6 AC1).

Selecting LaunchDarkly does not write anything yet — it only determines
which provider's block the rest of this run will populate. The actual
write of `provider: launchdarkly` to `rollout-config.yml` happens at Step 7,
alongside the rest of the `launchdarkly:` block (FR-003; spec US6 AC2).

---

## Step 2: MCP Server Discovery & Candidate Resolution

**Discovery**: Introspect the developer's already-configured MCP servers in
the agent's current client context (e.g. via the client's MCP tool/resource
listing capability). This step is **read-only** — it MUST NOT write, launch,
or register any MCP server; registering a server remains entirely the
developer's own responsibility, unchanged from the prior `connect` command's
non-goal (FR-002, FR-004).

Identify which of the discovered servers appear LaunchDarkly-capable, using
introspection-based signals (server name/key, advertised tool namespace, or
similar) — never a hardcoded or pinned server reference (FR-004).

**Candidate resolution** branches on how many LaunchDarkly-capable
candidates were found:

- **Zero candidates** (US2, FR-005): Explain clearly that no
  LaunchDarkly-capable MCP server was detected, instruct the developer to
  add the official LaunchDarkly MCP server themselves in their client's own
  MCP settings, and **stop the wizard immediately**. No configuration is
  saved from this run, and no further step (including Step 3's server-type
  probe) executes. This same stop-and-explain behavior also applies if the
  agent's MCP context cannot be introspected at all (treated identically to
  zero detected servers).
- **Exactly one candidate** (US1, FR-006): Report which server was found and
  proceed automatically to Step 3 — do not ask for an extra confirmation.
- **More than one candidate** (US3, FR-007): List every candidate and ask
  the developer to pick exactly one before proceeding to Step 3. Persist
  only the chosen server's name/key — never a command, arguments, version,
  repository, or credential value, for the chosen server or for any other
  candidate. The unselected candidate(s) are never probed.

---

## Step 3: Server-Type Determination (Automatic — Never Asked)

Immediately after Step 2 resolves to exactly one selected server, determine
whether it is LaunchDarkly's **hosted** MCP server or a **local** one. This
determination is **always** made automatically by this step — it is never
asked of the developer directly, at this step or any other (FR-008).

**Probe**: Attempt a live, read-only call to whichever introspected tool on
the selected server lists the developer's LaunchDarkly projects.

- **Clear success, with project results returned** → classify **hosted**.
  Proceed to Step 4a.
- **Clear failure / the tool is absent from the server's advertised tool
  list ("capability not found")** → classify **local**. Proceed to Step 4b.
- **Any ambiguous outcome** — a timeout, or an error that cannot be cleanly
  classified as either of the above — **also** classify **local**, so the
  wizard never stalls waiting for a clean signal (spec Edge Cases; US7).

**Cache policy**: This probe is **never cached and never skipped** — it
runs fresh on every single wizard invocation, including re-runs against a
project with an existing saved configuration, even if a prior run already
recorded a `server_type` value for this same server. A previously stored
`server_type` is informational-only (see Step 7) and is never trusted as a
substitute for re-running this probe (FR-008, FR-016).

---

## Step 4a / 5a: Hosted Branch — Project & Environment Selection

Using the confirmed project-listing capability from Step 3:

1. Present the real, live list of the developer's LaunchDarkly projects.
   Let the developer pick exactly one.
2. Present that project's real, live list of environments. Let the
   developer pick one or more.

Every value presented here comes from the live result set — this branch
never invents or defaults a project or environment value (FR-009, FR-010).

Once a project and one or more environments are selected, proceed to Step 6
(Read Verification).

---

## Step 4b / 5b: Local Branch — Manual Entry or Explicit Opt-Out

The local branch applies whenever Step 3 classifies the selected server as
`local` — whether via a clean "capability not found" result or via an
ambiguous/timeout outcome (FR-008; spec Edge Cases). Because this branch
cannot introspect real projects/environments, ask the developer to choose
between two paths:

### Manual Entry

The developer types the project ID directly, then one or more environment
keys directly. Save these values **exactly as typed** to
`launchdarkly.project_key` and `launchdarkly.environments` — never
fabricated, never defaulted, never guessed (FR-011).

When the developer supplies typed values (the non-opt-out sub-case),
proceed into Step 6 (Read Verification) against those typed values, exactly
as the hosted branch does with its live selections (FR-013; quickstart.md
Scenario 4).

### Explicit Opt-Out

The developer may instead explicitly decline to enter project/environment
values now. In this sub-case:

- Do **not** set `launchdarkly.project_key` or `launchdarkly.environments`
  at all — leave them absent. Never write a placeholder or fabricated value
  in their place (FR-012).
- Skip Step 6 (Read Verification) entirely — do not attempt it and do not
  treat it as having passed.
- Proceed directly to Step 7's final summary, which must explicitly state
  that project, environment, and read verification are **not yet
  configured** and must be completed manually (by hand-editing
  `rollout-config.yml`) or via a future run of this wizard (FR-012, FR-015;
  spec US7 AC3).

---

## Step 6: Read Verification

Shared by both the hosted branch (Step 4a/5a's selections) and the local
branch's manual-entry sub-case (Step 4b/5b) — but **not** the local
branch's opt-out sub-case, which skips this step entirely (see above).

Perform a read-only flag-listing call against the resolved
project/environment(s) to confirm that access actually works, before
reaching the final confirmation gate (FR-013).

- **Success**: proceed to Step 7 with a passing read-verification result.
- **Failure** (permissions error, network error, invalid project/
  environment, or any other error) (US4, FR-014): Explain the error clearly
  and present the developer with **exactly two choices**:
  1. **Cancel** the whole run — discard any not-yet-saved selections from
     this run. Nothing is written.
  2. **Continue anyway** — proceed to Step 7 with an explicit, visible
     warning that read access could not be confirmed, and save what was
     gathered so far if the developer ultimately confirms the write.

  The wizard MUST NOT silently proceed as though verification passed —
  one of these two choices must always be made explicitly by the developer
  (FR-014; spec US4 AC1-2).

---

## Step 7: Final Confirmation, Write, and Report

### Final Confirmation

Show the developer a complete summary of everything that will be written:
provider, the selected MCP server's name/key, the hosted/local
determination, project, environment(s) (or the opt-out note if applicable),
and the read-verification outcome (pass / fail-but-continuing / skipped due
to opt-out). **Nothing is written until the developer explicitly confirms**
(FR-015; contract "Final confirmation").

When the developer chose to continue after a Step 6 read-verification
failure, this summary — and the final report below — MUST explicitly state
that read access could not be verified (FR-014, FR-015; spec US4 AC3).

### Write

Once confirmed, write exactly one modular provider config block to
`rollout-config.yml`:

```yaml
provider: launchdarkly

launchdarkly:
  project_key: <selected or typed project id, or absent if opted out>
  environments: [<selected or typed environment keys>]   # absent if opted out
  server_type: hosted   # or: local
```

- Zero `mcp.*` fields are ever written anywhere in this block or file
  (FR-017, FR-026).
- Save the selected MCP server's name/key under the literal, flat key
  `mcp_server` (e.g. `mcp_server: <selected server name/key>`) in
  `.specify/extensions/rollout/local-config.yml` — never a command,
  arguments, version, repository, or credential value, and never an
  alternate spelling or nested form of the key (FR-018).
- `launchdarkly.server_type` records the Step 3 determination for
  reporting/traceability only — it is never read back as a cache on a
  future run; Step 3 always re-probes fresh (FR-008, data-model.md
  "Provider Config Block").
- This write MUST NOT touch any other provider's existing top-level block
  in `rollout-config.yml` (see "Re-Run Behavior" below).

### Report

State, in the final output: provider, MCP server used, hosted/local
determination, project, environment(s) (or the opt-out note), and
read-verification status (FR-015).

---

## Re-Run Behavior (US5)

`speckit.rollout.config` is always safely re-runnable (FR-016):

- On invocation, read any existing `rollout-config.yml` /
  `local-config.yml` values first and show them as the current selections
  at the relevant step, so the developer can see what is already configured.
- The developer may change any previous selection — provider, MCP server,
  project, or environment(s) — simply by making a different choice at the
  relevant step.
- **Step 3 (server-type determination) always re-runs fresh** on every
  re-run; it never reuses a prior run's stored `server_type` value, even if
  the same MCP server is selected again (FR-016; spec US5 AC1).
- At Step 7's write, only the fields the developer actually changed in this
  run are updated in place within the existing `launchdarkly:` block — no
  duplicate block is ever created. Unrelated fields, any other provider's
  existing block, and the `local-config.yml` MCP-server-selection value
  (unless explicitly changed in this same run) are left untouched (FR-016;
  quickstart.md Scenario 8). The wizard never silently carries forward a
  stale value without presenting it for confirmation first — every field in
  the final write reflects a choice actually confirmed during this run.

---

## Prohibited Actions

The following apply across **every** step of this wizard, with no
exceptions:

- **Never touch a client's MCP configuration**: MUST NOT write, create, or
  modify any client's native MCP configuration file (e.g. `.vscode/mcp.json`,
  `.mcp.json`, `.cursor/mcp.json`, `.codex/config.toml`,
  `.gemini/settings.json`, or any other client-native MCP settings
  location), at any step (FR-002).
- **Never touch a credential**: MUST NOT request, read, store, or echo a
  credential/token value at any step, in any prompt, log, or output
  (FR-023). This wizard's schema carries no token-related field at all —
  that information lives entirely in the developer's own MCP client
  configuration, outside this project's reach.
- **Never fabricate a value**: MUST NEVER invent, default, or guess a
  project ID, environment key, or server-type value the developer has not
  actually supplied, selected, or confirmed (FR-011, FR-012).
- **No partial save**: A run that stops before Step 7's explicit
  confirmation MUST leave `rollout-config.yml` and `local-config.yml`
  completely unchanged from that run. This "no-partial-save" invariant
  covers all three paths that can end a run early:
  1. The Step 2 zero-candidates stop (US2).
  2. A Step 6 read-verification failure where the developer chooses to
     cancel (US4).
  3. Voluntary developer cancellation at any other step (e.g. Step 4 or
     Step 5), for any reason, without an error occurring.

  In every one of these cases, no provider, MCP server, project, or
  environment selection made earlier in that same run is saved (SC-003;
  spec US2 AC2, Edge Cases).
