---
description: "rollout: switch the active provider — reuse a saved config block or trigger that provider's config preset"
visibility: "public"
mode: "user-invoked"
---

# `speckit.rollout.provider`

**Role**: A lightweight companion to `speckit.rollout.config` that lets a
developer switch which provider is active — or add a new provider — without
re-running the whole guided wizard when a saved config block already
exists. Takes one required argument: the target provider name (e.g.
`launchdarkly`).

**User Story Implemented**: US6 (provider selection and switching signals
future multi-provider intent).

---

## Invocation

```
speckit.rollout.provider <provider_name>
```

`<provider_name>` is required. In V1, `launchdarkly` is the only recognized
provider name with a real config preset.

---

## Behavior

### 1. Parse the argument

Read `<provider_name>` from the invocation. If it is missing, report that a
provider name is required and stop.

### 2. Validate the provider name

If `<provider_name>` is not a recognized provider name at all (not
`launchdarkly`, and not any other provider this extension actually
supports), report clearly that the name is unrecognized and **create no
malformed or empty block** for it. Do not modify `rollout-config.yml` at
all in this case.

### 3. Check for an existing saved block

Read `rollout-config.yml` and check whether a top-level block already
exists for `<provider_name>` (e.g. a pre-existing `launchdarkly:` block).

#### 3a. Existing block found

- Set `provider: <provider_name>` as the active provider.
- Reuse the existing block **exactly as-is** — zero re-prompting for any
  field already present in it.
- Do not modify the reused block's contents, and do not modify any other
  provider's existing block.

#### 3b. No existing block found

- Trigger that provider's own config preset. In V1, only `launchdarkly` has
  a real preset: this reuses `speckit.rollout.config`'s own
  provider-selection-through-write steps (Steps 1-7), scoped to
  `<provider_name>`. A future provider adds its own sibling preset — this
  command's own control-flow (argument parsing, existing-block check,
  `provider:` update) MUST NOT change to accommodate it (FR-025).
- The preset flow's own explicit-confirmation gate (`speckit.rollout.config`
  Step 7) applies unchanged — no separate, weaker confirmation path is
  introduced here. Only set `provider: <provider_name>` once that preset
  run actually completes and confirms a write.
- If the preset run is cancelled at any point, leave the prior `provider:`
  value active — do not partially switch.

### 4. Report

State which provider is now active, and whether an existing block was
reused or a new preset was run.

---

## Prohibited Actions

- MUST NOT modify any other provider's existing config block, in either
  branch above.
- MUST NOT request, read, prompt for, log, or store a credential/token
  value at any point (FR-023, same guarantee as `speckit.rollout.config`).
- MUST NOT write to `rollout-config.yml` before the same explicit-
  confirmation gate the underlying preset flow requires, when a preset run
  is triggered (3b).
- MUST NOT create a malformed or empty block for an unrecognized provider
  name.
