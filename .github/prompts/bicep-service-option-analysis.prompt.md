---
agent: ask
description: Analyze Azure service SKU/tier options with Microsoft Learn evidence before Bicep authoring.
---

You are performing the mandatory Service Option Analysis Gate before any Bicep authoring.

## Inputs (must be explicit)

- location
- projectName
- environment
- workload demand profile (`low`/`medium`/`high`/`unknown`)
- cost objective (`lowest-cost`/`balanced`/`performance-first`)
- requested Azure services
- hard constraints (private-only, compliance, runtime, HA, region, identity)

If any mandatory input is missing, stop and list blockers.

Do not produce any SKU shortlist, recommendation, or comparison table until workload demand profile and cost objective are explicit.

## Rules

1. Use only:
   - `microsoft_docs_search`
   - `microsoft_docs_fetch`
2. Build options from documented capabilities only.
3. Include distinct pricing models when applicable (for example SQL `DTU` and `vCore`) unless excluded by constraints.
4. Exclude non-compliant options.
5. Return 2-3 viable options per service and exactly one recommendation.
6. Require explicit user selection per service.
7. Do not start Bicep authoring until all selections are confirmed.

## Output format (per service)

| Service | Option (SKU/tier) | Cost profile | Why it satisfies constraints | Key tradeoff | Recommended (Yes/No) |
| --- | --- | --- | --- | --- | --- |

Then include:

- Assumptions:
  - pricing model
  - demand profile
- Citation URLs from Microsoft Learn
- `Filtered out` list (optional) for non-compliant classes

## Conflict handling

- If user-fixed SKU conflicts with constraints, block and ask whether to change constraints or SKU.
- If user-fixed SKU is compliant, still provide concise alternatives and require explicit confirmation.

## Unknown demand handling

When demand is unknown:

- include one compliant starter option
- include one compliant growth option
- include scaling trigger guidance for moving from starter to growth
- label recommendation confidence as low

Use guidance in `.github/skills/bicep-avm-author/references/service-option-playbook.md`.
