# Delivery Strategy Template

> **Note**: This template is an **optional structural reference** for a human reader or coding agent. It is not a required artifact, not a validation schema, and not parsed programmatically by any tool. If this file is absent, the plan phase continues without error or modification.

This template shows the structure and field order recommended for the `## Delivery Strategy` section of a rollout-intent feature's `plan.md` document. Use it as a reference guide when filling in Delivery Strategy content. All six elements below are expected in a complete Delivery Strategy block; you may add org-specific fields *below* these required elements without breaking structural consistency.

---

## Delivery Strategy Template

Use this template to structure your feature's Delivery Strategy block. Replace the placeholders (in `CAPITAL_PLACEHOLDERS`) with values appropriate to your feature.

### Feature flag
```
Feature flag: FEATURE_FLAG_NAME
```

**Guidance**: Enter the name of the feature flag that controls this feature's rollout (e.g., `enable_ai_assistant_v2`). This is typically the identifier used in your feature flag provider's dashboard.

---

### Provider
```
Provider: LaunchDarkly
```

**Guidance**: Specify the feature flag provider used for this rollout. This feature's standard provider is LaunchDarkly. If you are using a different provider, document it here and ensure it is supported by your organization's rollout doctrine.

---

### Rollout (phased)
```
Rollout:
  - Phase 1: PHASE_1_DESCRIPTION (target: AUDIENCE_1, duration: TIME_PERIOD_1)
  - Phase 2: PHASE_2_DESCRIPTION (target: AUDIENCE_2, duration: TIME_PERIOD_2)
  - Phase 3: PHASE_3_DESCRIPTION (target: AUDIENCE_3, duration: TIME_PERIOD_3)
```

**Guidance**: Describe each stage of your rollout plan in sequence. Use ordered phases (Phase 1, Phase 2, etc.) and include the target audience and expected duration for each phase. At minimum, phases should move from internal testing → canary users → broader rollout → general availability. Adjust the number of phases to match your rollout strategy.

---

### Targeting
```
Targeting:
  - Rule 1: TARGETING_RULE_1_DESCRIPTION
  - Rule 2: TARGETING_RULE_2_DESCRIPTION
```

**Guidance**: List the specific audience segments, user groups, or criteria used to determine who sees this feature in each phase. Examples: "internal team only," "beta users matching segment 'enterprise'," "users in region US-East," "accounts with feature subscription enabled." Each phase typically has its own targeting rules.

---

### Telemetry gates
```
Telemetry gates:
  - Gate 1: METRIC_1_NAME (threshold: VALUE_1)
  - Gate 2: METRIC_2_NAME (threshold: VALUE_2)
```

**Guidance**: Define the quantitative and qualitative health metrics that indicate whether the rollout is proceeding safely. Examples: "error rate < 0.1%," "API p99 latency < 500ms," "user satisfaction score > 4.0 / 5.0," "no critical bug reports in first 48 hours." Telemetry gates help determine whether to proceed to the next phase or trigger a rollback.

---

### Rollback conditions
```
Rollback conditions:
  - Condition 1: ROLLBACK_TRIGGER_1_DESCRIPTION
  - Condition 2: ROLLBACK_TRIGGER_2_DESCRIPTION
```

**Guidance**: Specify the automatic or manual rollback trigger conditions. When one or more of these conditions is met, the feature flag is disabled and the rollout is halted. Examples: "if any telemetry gate threshold is exceeded for > 10 minutes," "if critical customer reports escalate," "if automated smoke tests fail," "manual override by on-call engineer." Include both automatic (gate-based) and manual (human-decision) rollback paths.

---

## Customization Note

This template provides the six required structural elements for every Delivery Strategy block. You may add additional org-specific or feature-specific fields *below* these six sections without disrupting consistency. For example, you might add:

- **Owner/DRI**: Name and contact of the person responsible for the rollout
- **Communication Plan**: Channels and timing for notifying stakeholders
- **Success Criteria**: Business or product goals achieved upon full rollout
- **Dependencies**: Other features or systems that must be ready first
- **Risk Assessment**: Known risks and mitigation strategies

Keep the six core elements (flag, provider, rollout phases, targeting, telemetry, rollback) in their documented order at the start of your Delivery Strategy, and place any custom extensions after them.

---

## Example: Complete Delivery Strategy Using This Template

```
## Delivery Strategy

Feature flag: `enable_ai_summary_v2`

Provider: LaunchDarkly

Rollout:
  - Phase 1: Internal testing (target: internal team, duration: 1 week)
  - Phase 2: Beta user rollout (target: opt-in beta users, duration: 2 weeks)
  - Phase 3: General availability (target: all users, duration: ongoing)

Targeting:
  - Phase 1: Internal team only (organization internal)
  - Phase 2: Accounts with feature flag enabled in LaunchDarkly `beta_ai_summary` segment
  - Phase 3: All accounts (flag set to 100% rollout)

Telemetry gates:
  - Error rate < 0.05% (measured per phase, checked every 1 hour)
  - API p99 latency < 300ms (measured per phase, checked every 1 hour)
  - User satisfaction score > 4.2 / 5.0 (measured at end of Phase 2)
  - No unresolved critical bugs reported in user feedback

Rollback conditions:
  - Automatic: Error rate exceeds 0.1% for more than 15 minutes → disable flag and revert to Phase 0
  - Automatic: p99 latency exceeds 500ms for more than 15 minutes → disable flag and trigger incident response
  - Manual: On-call engineer determines feature behavior unacceptable or unsafe → disable flag immediately
  - Manual: Executive decision to delay due to business priority change → disable flag and reschedule rollout
```

---

## Integration with the Plan Phase

When you use `commands/brief-plan.md` to generate a `plan.md` for a rollout-intent feature, the briefing command may consult this template as a reference to ensure your Delivery Strategy block covers all six required elements. The `brief-plan` command does not require this file to exist — if it is absent, the plan phase produces complete Delivery Strategy content from its own doctrine. The presence of this template simply makes it easier for you to ensure consistency across your feature's rollout documentation.
