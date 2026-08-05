# Providers

`rollout` talks to feature-flag providers through their **official MCP
server** plus MCP's built-in discovery (`tools/list`, `resources/list`,
`prompts/list`) — never through a hand-maintained API wrapper or capability
contract (see [foundation/vision.md](foundation/vision.md) §6, Decision D3).
That single design choice is what makes provider support cheap to add later.

**Today (V1): [LaunchDarkly](https://launchdarkly.com/) is the only supported
provider.** Unleash and GrowthBook are roadmap items (vision.md §11), not yet
implemented. This page has two audiences:

- [**Using the LaunchDarkly provider**](#using-the-launchdarkly-provider) — for
  anyone configuring `rollout` in a project today.
- [**Adding a new provider**](#adding-a-new-provider-extension-developer-guide)
  — for extension developers who want to extend `rollout` beyond LaunchDarkly.

```mermaid
flowchart TB
    Doctrine["Doctrine files\n(commands/brief-plan.md, brief-implement.md)"]
    Config["rollout-config.yml\nprovider: launchdarkly\nmcp: command/args/version/repository/token_env_var"]
    MCP["Official provider MCP server\n(spawned with the token in its own env)"]
    Introspect["Runtime introspection\ntools/list · resources/list · prompts/list"]
    Intents["7 provider-neutral intents\ndiscover envs · discover segments · create flag ·\nset targeting · set % rollout · read status · archive"]

    Config -->|pins the server| MCP
    Doctrine -->|reads config, connects| MCP
    MCP --> Introspect
    Introspect -->|bind at runtime| Intents
    Intents -->|execute| MCP
```

Nothing in the diagram above is provider-specific except the config block and
the MCP pin — the doctrine's seven intents and the introspection step are
already provider-neutral.

## Using the LaunchDarkly provider

Everything here is regular project configuration — no code changes. See the
[README's Configuration section](../README.md#configuration) for the full
four-layer precedence (`extension.yml` defaults → project config → local
override → env vars).

### 1. Set the provider and project pointers

`.specify/extensions/rollout/rollout-config.yml` (copy from
[rollout-config.template.yml](../rollout-config.template.yml)):

```yaml
provider: launchdarkly

launchdarkly:
  project_key: "my-ld-project"
  environments: ["staging", "production"]
```

These are **non-secret pointers only** — never a token value.

### 2. Pin the official MCP server

```yaml
mcp:
  command: "launchdarkly-mcp-server"
  args: []
  version: "~1.0.0"
  repository: "https://github.com/launchdarkly/mcp-server"
  token_env_var: "LAUNCHDARKLY_API_TOKEN"
```

`command`/`args`/`version`/`repository` describe *which* official server to
launch and how — `rollout` never substitutes an alternative implementation,
even if one advertises the same tools (vision.md §6.2). `token_env_var` is a
**name only**; the value is never written to config, never read by the agent,
and never enters the model context — only the spawned MCP server process
reads it from the OS environment. <a id="credentials"></a>

### 3. Export the token, once, outside of git

```bash
export LAUNCHDARKLY_API_TOKEN="..."   # in your shell profile, not in the repo
```

Use a scoped, least-privilege LaunchDarkly token. See vision.md §8 for the
full credential-security rationale (why this is the V1 approach vs. editor
secret stores or encrypted files).

### 4. Register the MCP server with your client

```
/speckit.rollout.connect
```

See [usage.md](usage.md#1-install-and-connect-once-per-project) for what this
does and does not do.

That's it — no other steps are required. `brief-plan`, `brief-tasks`, and
`brief-implement` pick up `provider`, `launchdarkly.*`, and `mcp.*` from
resolved config automatically once a feature has rollout signal.

## Adding a new provider (extension developer guide)

This section is for people modifying the `rollout` extension itself, not for
end users. It walks through what a new provider (e.g., Unleash, GrowthBook)
would require, following the extension points already reserved in
[foundation/vision.md](foundation/vision.md) §11.

> **Scope check**: as of this writing, only LaunchDarkly is implemented end to
> end (V1 scope, vision.md §10). The steps below describe the concrete diffs
> needed to add a second provider — most of the doctrine does **not** need to
> change, by design.

### What already generalizes for free

- **MCP introspection & the seven provider-neutral intents**
  ([commands/brief-implement.md](../commands/brief-implement.md), Step 3.3):
  discover environments, discover segments, create flag, set targeting, set
  percentage rollout, read flag status, archive flag. These are named in
  natural language and bound to whatever tools the configured MCP server
  actually advertises at runtime — no per-provider tool-name hardcoding to
  update.
- **The `mcp.*` config block shape** (`command`, `args`, `version`,
  `repository`, `token_env_var`) is already provider-agnostic — point it at
  the new provider's own official MCP server.
- **The credential chain** (global OS env var → MCP server process only) is
  provider-agnostic; only the env var *name* changes per provider.

### What you need to change

1. **Add a provider-specific config block.**
   In [rollout-config.template.yml](../rollout-config.template.yml) and the
   `config_schema` in [extension.yml](../extension.yml), add a new top-level
   block mirroring the shape of `launchdarkly:`, e.g.:

   ```yaml
   unleash:
     project_key: ""
     environments: []
   ```

   Keep it non-secret pointers only, matching the existing
   `launchdarkly.project_key` / `launchdarkly.environments` pattern.

2. **Validate `provider` against a registry.**
   Vision.md §11 calls for the `provider` config key to resolve against a
   known registry rather than being accepted as any free string. Add the new
   provider id (e.g., `unleash`) to that registry/validation wherever
   `provider` is read.

3. **Generalize the hardcoded `Provider: LaunchDarkly` line.**
   [commands/brief-plan.md](../commands/brief-plan.md) (Step 3, element 2)
   currently writes the literal text `Provider: LaunchDarkly` into every
   `## Delivery Strategy` section. Change this to emit
   `Provider: <resolved provider display name>`, sourced from the resolved
   `provider` config value.

4. **Generalize the hardcoded `"launchdarkly"` entry key in `connect`.**
   [commands/connect.md](../commands/connect.md) ("Locate or Create
   LaunchDarkly Entry") currently writes the MCP server entry under the
   literal key `"launchdarkly"` in the client's MCP config file. Generalize
   this to key off the resolved `provider` config value (e.g., `"unleash"`),
   so `connect` can register whichever provider is configured — including
   projects that might one day run more than one.

5. **Add an optional provider-specific advisory note, if truly needed.**
   Per vision.md §11 point 3 ("modular doctrine: provider-neutral rollout
   content vs. provider-specific notes"), only add a short advisory aside if
   the new provider's MCP genuinely requires one (e.g., a naming quirk). Do
   **not** re-introduce a maintained per-provider capability contract — that
   was explicitly rejected (Decision D3) because MCP's own `tools/list`
   discovery already stays fresh across provider releases.

6. **Update scope-boundary docs.**
   Update this file's provider list, the README's "Provider scope" line, and
   vision.md §1/§10/§11 once the new provider is actually implemented (not
   just planned) — keep the "V1 scope" language accurate rather than
   aspirational.

7. **Re-verify the quickstart fixtures.**
   Each `specs/0XX-*/quickstart.md` that exercises `brief-plan`/`brief-tasks`/
   `brief-implement` assumes the current single-provider wording. Re-run those
   scenarios (or add a provider-parameterized variant) to confirm the gate
   script and doctrine still behave correctly once `provider` can be more than
   `launchdarkly`.

### What you should *not* do

- Don't build a per-provider REST/API wrapper — the whole point of the MCP +
  introspection model (Decision D3) is to avoid maintaining one.
- Don't hardcode a new provider's tool names into the doctrine — bind to them
  via introspection at runtime, exactly like LaunchDarkly does today.
- Don't put a token value anywhere in config, doctrine text, or committed
  files — only the env var *name*, exactly like the existing
  `token_env_var` pattern.
