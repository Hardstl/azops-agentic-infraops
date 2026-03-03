# Copilot Instructions (AVM Bicep Authoring)

These instructions use the canonical skill in `.github/skills/bicep-avm-author`.

## Scope

Use this repository guidance when creating or editing Azure Bicep infrastructure templates.

- Prefer Azure Verified Modules (AVM) first.
- Preserve secure defaults and policy-aligned patterns.
- Fail closed when required inputs or evidence are missing.

## Mandatory Inputs Before Authoring

Do not author or modify Bicep until these are explicit:

- `location`
- `projectName`
- `environment`
- `deploymentMode` (defaults to `azops` when omitted; `standard` only by explicit request)
- if effective mode is `azops`: `targetSubscriptionId`
- if effective mode is `azops`: `targetResourceGroupName`
- workload demand profile (`low`, `medium`, `high`, or `unknown`)
- cost objective (`lowest-cost`, `balanced`, `performance-first`)
- fixed design choices concrete enough to implement directly

If `location`, `projectName`, or `environment` are missing, request them first.
If effective mode is `azops` and target subscription/resource group identifiers are missing, return blockers before any authoring.

## Mandatory Service Option Analysis Gate

Before any Bicep authoring, run option analysis per requested service and require explicit user choice.

Required sequence:

1. Identify requested services.
2. Extract hard constraints and cost signals.
3. Classify demand profile.
4. Confirm cost objective before producing any SKU shortlist, recommendation, or comparison table.
5. If demand is `unknown`, provide `low`/`medium`/`high` envelopes.
6. Use only Microsoft Learn tools for this gate:
   - `microsoft_docs_search`
   - `microsoft_docs_fetch`
7. Build candidate options from documented capabilities only.
8. Include distinct pricing models where applicable (for example SQL `DTU` and `vCore`) unless excluded by constraints.
9. Exclude non-compliant options.
10. Return 2-3 viable options with one recommendation.
11. Require explicit user confirmation for each service.
12. Block authoring until all service choices are confirmed.

If evidence is insufficient, return blockers and do not author.

## Option Output Contract

Use this table for each service:

| Service | Option (SKU/tier) | Cost profile | Why it satisfies constraints | Key tradeoff | Recommended (Yes/No) |
| --- | --- | --- | --- | --- | --- |

Also include assumptions:

- pricing model (`DTU`, `vCore`, `consumption`, `provisioned`, etc.)
- demand profile assumption (`low`, `medium`, `high`, `unknown`)

Cost profile must include relative cost (`Lower`, `Medium`, `Higher`) and one risk note.

## Constraint Conflicts

- If fixed SKU conflicts with hard constraints, stop and ask the user to resolve constraints vs SKU.
- If fixed SKU is compatible, still provide concise comparison and ask for explicit confirmation.
- Never silently override fixed SKU/tier requests.

## AVM and Authoring Rules

- Resolve deployment mode and destination path before authoring:
  - default to `azops` when omitted
  - use `standard` only when explicitly requested (`infra/{projectName}/`)
  - in `azops` mode, resolve path with `.github/skills/bicep-avm-author/scripts/resolve-azops-path.ps1`
  - follow `.github/skills/bicep-avm-author/references/azops-path-resolution.md`
  - fail closed if AzOps path resolution is missing, ambiguous, or blocked
  - in `azops` mode, generate entrypoints as `.bicep` files only; do not generate ARM template `.json` files
- Resolve required AVM modules before writing module blocks.
- Use direct AVM references (`br/public:avm/...`) for AVM-covered resources.
- Prefer stable versions unless a required capability is preview-only.
- Keep fixed decisions in code; do not create decision-proxy parameters.

## Baseline Bicep Contract

Entrypoints must include at minimum:

```bicep
@description('Location for all resources')
param location string

@description('Project name for tagging and naming')
param projectName string

@description('Environment for tagging and naming (e.g. dev, test, prod)')
param environment string
```

Apply defaults and guardrails:

- Required tags: `Environment`, `ManagedBy`, `Project`
- `minimumTlsVersion: 'TLS1_2'` where supported
- Storage: `supportsHttpsTrafficOnly: true`, `allowBlobPublicAccess: false`, `allowSharedKeyAccess: false`
- Prefer managed identity over secrets/keys/connection strings
- Key Vault defaults to `enableRbacAuthorization: true`

## Naming and Region Resolution

- Canonicalize region using `.github/skills/bicep-avm-author/references/geo-aliases.json`.
- Resolve `regionShortCode` using `.github/skills/bicep-avm-author/references/geo-codes.json`.
- Fail closed if region cannot be resolved.
- Follow naming constraints in `.github/skills/bicep-avm-author/references/caf-naming.md`.

## Placement Guardrails

When producer AVM supports native inputs, keep these inside producer module params:

- `roleAssignments`
- `privateEndpoints`
- diagnostics (`diagnosticSettings` or `diagnostics`)

Use standalone extension resources only when producer AVM lacks native support.

## Validation and Evidence

After authoring:

- Run diagnostics, build, and lint.
- Preserve evidence of service constraints, option comparisons, selected options, and citation URLs.

Do not proceed when required evidence is missing.
