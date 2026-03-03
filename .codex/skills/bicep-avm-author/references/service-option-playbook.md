# Service Option Playbook (Bicep AVM Author)

## Purpose

Use this playbook during the mandatory `Service Option Analysis Gate` in `SKILL.md`.
It standardizes how to:

- Extract hard constraints from the request
- Research official Microsoft Learn documentation
- Produce 2-3 viable options with one recommendation
- Capture explicit user choice before Bicep authoring
- Produce cost-aware recommendations under uncertainty

## Documentation Source Policy

For service option analysis, use only:

- `mcp__microsoft_learn__microsoft_docs_search`
- `mcp__microsoft_learn__microsoft_docs_fetch`

Do not use `mcp__azure__documentation` for this gate.
If Microsoft Learn evidence cannot be retrieved, fail closed and block authoring.

## Constraint Extraction Checklist

Extract and record for each requested service:

- Service intent (what is being created and why)
- Network requirements (`private-only`, public allowed, private endpoints, VNet integration)
- Availability and resiliency requirements (zone/region strategy, SLA expectations)
- Runtime/engine constraints (language/runtime stack, managed engine requirements)
- Identity and auth requirements (system-assigned/user-assigned, RBAC model)
- Compliance constraints (data residency, encryption, policy requirements)
- Region constraints (`location`, paired-region or sovereign restrictions)
- Scale/performance expectations
- Cost preference (balanced, lowest cost, performance-priority)
- Demand profile (`low`, `medium`, `high`, or `unknown`)
- Usage shape (steady/always-on vs bursty/intermittent)
- Budget guardrail (if available)
- Fixed SKU/tier mandates from user

If demand profile is `unknown`, mark recommendation confidence as `low` and use scenario envelopes.

## Query Templates by Service Class

Use these as starting points and tailor with concrete service name, region, and constraints.

### Compute/Web

```text
{service} pricing tier private endpoint support vnet integration managed identity Microsoft Learn
{service} plan comparison {constraint} limitations Microsoft Learn
```

### Database

```text
{service} sku tiers private access high availability zone redundancy Microsoft Learn
{service} networking options private endpoint public network access Microsoft Learn
```

### Integration/Messaging

```text
{service} tier comparison private networking availability features Microsoft Learn
{service} premium vs standard limits and security capabilities Microsoft Learn
```

### Network

```text
Azure {service} sku comparison throughput zone support private connectivity Microsoft Learn
Azure {service} limits and design considerations Microsoft Learn
```

### Storage/Security Services

```text
Azure {service} sku redundancy networking private endpoint support Microsoft Learn
Azure {service} security baseline managed identity RBAC Microsoft Learn
```

## Recommendation Scoring Rubric

Apply this order strictly:

1. Hard-constraint compliance (`must pass`)
2. Security/networking fit
3. Reliability/operability fit
4. Scale/performance fit
5. Cost profile

Cost scoring rule:

- Compare cost within the same service option set (not cross-service).
- Use relative labels: `Lower`, `Medium`, `Higher`.
- Include a one-line cost risk note for each option.

Optional scoring model for viable candidates:

| Criterion | Rule |
| --- | --- |
| Hard constraints | Pass/Fail gate; fail means option is excluded |
| Security/networking fit | Score `1-5` |
| Reliability/operability fit | Score `1-5` |
| Scale/performance fit | Score `1-5` |
| Cost profile | Score `1-5` |

Recommendation rule:

- Recommend the highest-ranked compliant option.
- If two options tie, prefer the simpler operational model unless the user asked to optimize for lowest cost.
- Option count target is 2-3 viable options per service.
- If fewer than 2 compliant options remain, treat as blocker and ask user whether to relax constraints.

Unknown-demand fallback rule:

- Return one `starter` recommendation (cost-first, compliant, easy to scale).
- Return one `growth` recommendation (higher baseline cost, better sustained headroom).
- Explicitly state trigger signals to move from starter to growth.

Service model coverage rule:

- If a service has materially different pricing models, include both unless excluded by constraints.
- Example for Azure SQL Database: include both `DTU` and `vCore` options when both are compliant.

## Option Output Template

Use this table for each requested service:

| Service | Option (SKU/tier) | Cost profile | Why it satisfies constraints | Key tradeoff | Recommended (Yes/No) |
| --- | --- | --- | --- | --- | --- |

`Cost profile` format:

- Relative level: `Lower` / `Medium` / `Higher`
- Billing behavior summary (for example fixed provisioned, autoscale, pause/resume eligible)
- Cost risk note (for example overpay risk for low usage)

Below the table, include an `Assumptions` block:

- Pricing model used for each option (for example `DTU`, `vCore`, `consumption`, `provisioned`)
- Demand profile assumption (`low`/`medium`/`high`/`unknown`)

After the table, request explicit user selection:

```text
Please choose one option for {service}. I will not start Bicep authoring until your selection is confirmed.
```

If useful for transparency, add a short `Filtered out` list for non-compliant classes with one-line reasons.

If demand is unknown, append a `Sizing assumptions` block:

```text
Sizing assumptions:
- Low: up to X concurrent users / light transactions
- Medium: up to Y concurrent users / moderate transactions
- High: up to Z concurrent users / sustained heavy transactions
Recommendation confidence: Low (usage unknown)
```

## Constraint Conflict Handling

If the user specifies a fixed SKU/tier that conflicts with hard constraints:

1. Stop.
2. Explain the conflict with doc citations.
3. Ask user to choose:
   - Change/relax the hard constraint, or
   - Change the fixed SKU/tier
4. Do not silently override and do not author Bicep until resolved.

If the user specifies a fixed SKU/tier that is compatible:

1. Keep that SKU/tier as an option in the comparison.
2. Still present concise alternatives.
3. Require explicit confirmation before authoring.

## Fail-Closed Rule

Blocker conditions:

- Docs search/fetch unavailable for a required service decision
- Evidence does not substantiate capability claims
- No compliant options remain after filtering

In blocker cases, return blockers and do not generate architecture choices or Bicep.

## Cost-Aware Recommendation Guidance

When usage is unknown:

1. Avoid recommending premium/high-commit options as default unless required by hard constraints.
2. Prefer compliant options with lower entry cost and clear upgrade path.
3. Pair each recommendation with scale trigger guidance (CPU, DTU/vCore utilization, latency, queue depth).
4. Ask for one concrete sizing signal before finalizing if possible (expected peak users, transactions/sec, or monthly requests).

## Example Behavior: Private Function App

When request includes private-only access:

- Filter out non-compliant plan classes (for example, plans that cannot satisfy the required private model with documented support).
- Provide 2-3 compliant alternatives.
- Mark one recommendation with citations.
- Require explicit user choice before authoring.

## Example Behavior: SQL with Unknown Load

- Include both DTU and vCore compliant options when constraints allow both.
- Prefer a DTU starter (or equivalent lower-entry model) when cost objective is `lowest-cost` and usage is unknown.
- Include a vCore growth option with migration trigger signals.
- Do not recommend Business Critical or high baseline tiers by default unless a hard requirement justifies it.

## Validation Scenarios

1. Single service, no fixed SKU:
   - Input: `Create a private function app.`
   - Expected: 2-3 compliant options, one recommendation, explicit choice requested, no authoring before choice.
2. Fixed SKU compatible:
   - Input: `Use FC1 for private function app.`
   - Expected: compatibility validated, concise comparison still shown, proceed only after explicit confirmation.
3. Fixed SKU incompatible:
   - Input: `Use Y1 for private function app.`
   - Expected: blocked conflict response; require user to relax constraint or change SKU.
4. Multi-service request:
   - Input: `Private function app + storage + key vault.`
   - Expected: per-service option analysis completed for each service before any authoring.
5. Docs lookup failure:
   - Expected: fail closed with blockers and no generated architecture decision.
