---
name: bicep-avm-author
description: Author production-grade Azure Bicep templates with AVM-first modules and policy-aligned defaults. Use when Codex needs to create or update Azure infrastructure-as-code in Bicep, resolve AVM module/version metadata via MCP, enforce producer-owned RBAC/private endpoint/diagnostics patterns, apply secure defaults, avoid dependency cycles, and produce build/lint plus authoring evidence for validation.
---

# Azure Bicep AVM Author

Single source of truth for authoring Azure Bicep using Azure Verified Modules (AVM) first.

## Scope

Includes:
- AVM-first authoring workflow and module/version resolution
- Service option analysis gate with docs-cited recommendations and explicit user selection lock
- Placement and dependency guardrails
- Secure defaults for naming, tags, network exposure, and identity
- Validation and authoring evidence requirements

Excludes:
- Broad requirements elicitation beyond mandatory inputs
- Stakeholder sign-off collection
- Post-deployment operations

## Mandatory Tool Chain

Run these before and during authoring:

1. Call Azure best-practices guidance first:
   - `mcp__azure__get_azure_bestpractices` with Azure authoring intent
2. Call Bicep authoring guidance:
   - `mcp__bicep__get_bicep_best_practices`
3. Run service option analysis research for each requested Azure service:
   - `mcp__microsoft_learn__microsoft_docs_search`
   - `mcp__microsoft_learn__microsoft_docs_fetch`
   - For this gate, use Microsoft Learn MCP tools only; do not substitute `mcp__azure__documentation`
4. Resolve AVM modules and versions after option selection is locked:
   - `mcp__bicep__list_avm_metadata`
5. Validate authored files:
   - `mcp__bicep__get_bicep_file_diagnostics`
   - `bicep build <entrypoint.bicep>`
   - `bicep lint <entrypoint.bicep>`

Fail closed if required tooling cannot provide enough evidence to safely author.

## Mandatory Inputs Before Authoring

Do not author until all inputs below are available:

- `location` is explicitly provided (for example `westeurope`)
- `projectName` is explicitly provided
- `environment` is explicitly provided (for example `dev`, `test`, `prod`)
- `deploymentMode` defaults to `azops` when omitted; use `standard` only when explicitly requested
- If effective `deploymentMode` is `azops`, `targetSubscriptionId` is explicitly provided
- If effective `deploymentMode` is `azops`, `targetResourceGroupName` is explicitly provided
- Workload demand profile is defined (`low`/`medium`/`high`) or explicitly marked `unknown`
- Cost objective is defined (`lowest-cost`, `balanced`, or `performance-first`)
- Required fixed design choices are concrete enough to implement directly

If any input is missing, stop and return blockers.
If `location`, `projectName`, and/or `environment` are missing, ask for them before any other work.
If effective `deploymentMode` is `azops` and `targetSubscriptionId` and/or `targetResourceGroupName` is missing, stop and return blockers before any authoring.
If workload demand profile and/or cost objective is missing, ask before final service recommendation.

## Service Option Analysis Gate (Mandatory Before Authoring)

Run this gate for each requested Azure service before writing or editing Bicep.
Use reusable prompts and scoring guidance in `references/service-option-playbook.md`.

Required sequence:

1. Identify each requested Azure service.
2. Extract hard constraints from request (private-only, availability, runtime, region, identity, compliance).
3. Extract cost signals (budget guidance, expected load, burstiness, always-on vs intermittent, growth expectation).
4. Classify demand profile (`low`/`medium`/`high` or `unknown`).
5. If demand is `unknown`, build recommendations for three envelopes (`low`, `medium`, `high`) and mark uncertainty.
6. Search Microsoft Learn docs for each service with `mcp__microsoft_learn__microsoft_docs_search`.
7. Fetch the most relevant pages with `mcp__microsoft_learn__microsoft_docs_fetch`.
8. Build candidate options from documented capabilities only.
9. Include distinct pricing/consumption models where service supports them (for example SQL `DTU` and `vCore`) unless a hard constraint excludes one model.
10. Exclude non-compliant options.
11. Return 2-3 viable options with one clear recommendation.
12. Require explicit user choice.
13. Block authoring until choice is confirmed for every requested service.

Non-compliant option classes may be shown as `filtered out`, but never as selectable options.

### Option Comparison Output Contract

Use this table structure for every requested service:

| Service | Option (SKU/tier) | Cost profile | Why it satisfies constraints | Key tradeoff | Recommended (Yes/No) |
| --- | --- | --- | --- | --- | --- |

Below the table, include a short assumptions block:

- Pricing model (for example `DTU`, `vCore`, `consumption`, `provisioned`)
- Demand profile assumption (`low`/`medium`/`high`/`unknown`)

Cost profile must be explicit even when exact prices are unavailable:

- `Lower`, `Medium`, `Higher` relative operating cost versus other options in the same service comparison
- `Cost risk` statement (for example under-provisioning risk, always-on billing risk, burst penalty risk)
- Recommended right-sizing path (how to move up/down later)

When demand is `unknown`, include one recommended `starter` option and one `growth` option, both compliant.

### Constraint Conflict Rule

- If user specifies an exact SKU/tier that conflicts with hard constraints, block and ask the user to resolve the conflict.
- If user specifies an exact SKU/tier and it is compatible, still present a concise comparison and require explicit confirmation before authoring.
- Do not silently override fixed SKU/tier requests.
- Do not proceed with a non-compliant SKU/tier.

### Evidence Requirements for Option Decisions

Capture and preserve:

- Requested service list and extracted hard constraints
- Demand profile and cost objective used for ranking
- Option comparison output for each service
- Explicit selected option for each service
- Recommendation rationale with Microsoft Learn citation URLs

If docs lookup fails or evidence is insufficient, fail closed with blockers and do not author Bicep.

### Example Rule: Private Function App

- Filter out non-compliant plans for private-access constraints.
- Provide 2-3 compliant alternatives.
- Recommend one option with rationale and citations.
- Require explicit user confirmation of the chosen plan before authoring.
- If user requests a conflicting fixed SKU/tier, stop and ask whether to change constraints or change SKU/tier.

## Deterministic Workflow

1. Validate gates:
   - Collect `location`, `projectName`, and `environment`
   - Normalize user region input with `references/geo-aliases.json`
   - Resolve `regionShortCode` from `references/geo-codes.json`
   - If alias/code lookup fails, stop and ask the user for a supported Azure region
   - Confirm mandatory inputs
2. Run service option analysis gate:
   - Analyze each requested service using Microsoft Learn docs tools
   - Lock explicit user service option choices before any authoring
3. Resolve deployment mode and destination path:
   - Default to `azops` when `deploymentMode` is omitted
   - `standard` is allowed only when explicitly requested; destination is `infra/{projectName}/`
   - `azops` requires `targetSubscriptionId` and `targetResourceGroupName`; resolve with `scripts/resolve-azops-path.ps1` and `references/azops-path-resolution.md`
   - If `azops` inputs are missing or path resolution is ambiguous, stop and return blockers
   - In `azops` mode, generate entrypoints as `.bicep` files only; do not generate ARM template `.json` files
4. Resolve AVM modules:
   - Use `mcp__bicep__list_avm_metadata` for each required resource type
   - Select resolved module/version before writing module blocks
5. Author one environment-specific entrypoint:
   - Use direct AVM references (`br/public:avm/...`)
   - Keep fixed decisions in code (not decision-proxy parameters)
6. Apply baseline defaults:
   - Regions, tags, security, naming conventions in this skill
7. Enforce placement and dependency guardrails:
   - Producer AVM owns RBAC/private endpoints/diagnostics when supported
8. Handle exceptions:
   - Use raw Bicep only with explicit `approve raw bicep`
9. Validate:
   - Run diagnostics, build, and lint

## Entrypoint Contract

Minimum entrypoint contract:

- Single env-specific entrypoint for the requested scope
- Direct AVM registry references for AVM-covered resources
- No same-file `existing` declaration for resources created in that file
- Runtime parameters only for true runtime, secret, or operational values
- Managed identity by default; prefer system-assigned identity first
- Use user-assigned identity only when deterministic cycle-breaking patterns cannot resolve dependency ordering

Baseline parameters:

```bicep
param location string
param projectName string
param environment string
```

## Baseline Defaults

### Tags

Required tags:
- `Environment`
- `ManagedBy`
- `Project`

Baseline pattern:

```bicep
param environment string
param projectName string

var tags = {
  Environment: environment
  ManagedBy: 'AzOps'
  Project: projectName
}
```

### Security

- Set `minimumTlsVersion: 'TLS1_2'` where supported
- Storage must set:
  - `supportsHttpsTrafficOnly: true`
  - `allowBlobPublicAccess: false`
- Production data services should set `publicNetworkAccess: 'Disabled'` unless exception is explicitly approved
- Prefer managed identity over secrets, keys, and connection strings
- Key Vault defaults to RBAC:
  - `enableRbacAuthorization: true`

### Naming and Uniqueness

Generate uniqueness once and reuse:

```bicep
var uniqueSuffix = uniqueString(resourceGroup().id)
```

Resolve region short code before naming:

- Canonicalize user-provided region with `references/geo-aliases.json`
- Lookup short code from canonical region in `references/geo-codes.json`
- Use resolved `regionShortCode` in all resource names
- Fail closed if the region cannot be resolved to a short code
- For full naming standards and constraints, load `references/caf-naming.md`

Length-aware examples:

```bicep
var normalizedProjectName = toLower(replace(projectName, '-', ''))
var normalizedEnvironment = toLower(environment)
var regionShortCode = 'sdc' // resolved from references/geo-codes.json using location

var kvName = 'kv-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var storageName = 'st${take(normalizedProjectName, 8)}${regionShortCode}${take(normalizedEnvironment, 3)}${take(uniqueSuffix, 7)}'
```

Naming rules:
- Prefer lowercase and hyphenated names unless resource type forbids hyphens
- Storage account names must be lowercase alphanumeric only
- Do not hardcode unique values

## AVM Resolution Rules

- Resolve every required module via `mcp__bicep__list_avm_metadata`
- Do not hardcode module/version before metadata resolution
- Prefer stable versions unless required capability is preview-only
- Record selected module/version in authoring evidence

## Placement Guardrails (Mandatory)

When producer AVM module supports native inputs, keep these concerns in producer params:

- `roleAssignments`
- `privateEndpoints`
- diagnostics (`diagnosticSettings` or `diagnostics`)

Do not create standalone extension resources/modules for these concerns when producer-native support exists.

Fallback to standalone extension resources is allowed only when producer AVM lacks support.

### Dependency Access Guardrails

- Enforce least-privilege data-plane RBAC for workload access to Storage and Key Vault
- Function Apps must use identity-based storage configuration
- If Key Vault and workload compute are in-scope together, grant each workload identity Key Vault Secrets User at minimum unless a stricter explicit alternative is defined

### Network and Exposure Guardrails

- Associate NSG to all non-reserved subnets
- Set `privateEndpointNetworkPolicies: 'Enabled'` on non-reserved subnets
- Reserved subnet exemptions only:
  - `AzureFirewallSubnet`
  - `AzureFirewallManagementSubnet`
  - `GatewaySubnet`
  - `RouteServerSubnet`
- When private endpoints are used, set `publicNetworkAccess: 'Disabled'` on dependent services unless mixed-access exception is approved

### Service-Specific Guardrails

- Declare SQL databases via SQL Server AVM `databases` array
- Default Key Vault authorization mode to RBAC unless an explicit access-policy exception is approved
- Omit optional properties rather than setting them to explicit `null`

## Dependency Direction and Cycle Avoidance

Avoid `consumer -> producer -> consumer` cycles.

Preferred order:
- Allow producer to consume consumer outputs only when needed for extension wiring
- Keep consumer independent from producer outputs where possible by deriving names/IDs/URIs from conventions

If unavoidable, decouple in this order:
1. Replace `module.outputs.*` references with deterministic construction where possible:
   - Reuse already-constructed `var` names (for example storage account name) instead of `outputs.name`
   - Build resource IDs with `resourceId(...)` from deterministic names instead of `outputs.resourceId`
   - Build storage endpoints from deterministic names and environment suffixes when needed instead of `outputs.primaryBlobEndpoint`
2. Use phased deployment boundary only when deterministic construction cannot break the cycle
3. Use user-assigned managed identity only when steps 1-2 cannot satisfy required wiring

## Raw Bicep Fallback Rule

If AVM exists, use AVM.

Raw Bicep is allowed only when:
- No AVM exists for the required scenario, or
- Required capability is unavailable in AVM and no supported pattern can satisfy requirement

Raw Bicep requires explicit approval phrase:
- `approve raw bicep`

## Anti-Patterns

Do not:

- Start authoring before required inputs are complete
- Start authoring before explicit service option selection is confirmed
- Silently fall back from default `azops` mode to `standard` when required AzOps inputs are missing
- Present non-compliant service options as viable choices
- Recommend undocumented SKUs/features without Microsoft Learn evidence
- Use local wrapper modules for AVM-covered resources instead of direct AVM references
- Introduce decision-proxy parameters for fixed architecture decisions
- Add same-file `existing` resources for resources created in the same file
- Create standalone RBAC/private endpoint/diagnostic extensions when producer AVM supports native placement
- Default to user-assigned identity when the cycle can be broken by replacing producer outputs with deterministic values
- Continue when fixed SKU/tier conflicts with hard constraints; block and require conflict resolution
- Use raw Bicep without explicit `approve raw bicep`
- Generate ARM template `.json` files in `azops` mode; use `.bicep` entrypoints only
- Continue on unresolved blockers; fail closed and report blockers explicitly

## Authoring Checklist

- Gates and sign-off are complete
- Deployment region was explicitly provided by the user
- Region alias and short code were resolved from `references/geo-aliases.json` and `references/geo-codes.json`
- Service option analysis was performed for each requested service
- 2-3 compliant options were provided for each requested service
- Recommendation was documented with Microsoft Learn citations
- User-selected option was captured before authoring
- Deployment mode is resolved (`azops` by default; `standard` only when explicitly requested)
- In `azops` mode, `targetSubscriptionId` and `targetResourceGroupName` were provided and `resolvedAzopsPath` was uniquely resolved
- In `azops` mode, output files are `.bicep` entrypoints only (no generated ARM `.json` templates)
- AVM metadata was resolved via MCP
- Entrypoint is AVM-first and env-specific
- Producer-owned extension placement rules are respected
- No producer/consumer cycles introduced
- Security, naming, and tagging baselines are applied
- Build/lint/diagnostics completed
- Authoring evidence produced for handoff
