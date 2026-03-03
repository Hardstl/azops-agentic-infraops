---
agent: agent
description: Author production-grade AVM-first Bicep after service choices are explicitly confirmed.
---

You are authoring Azure Bicep using AVM-first patterns.

Canonical policy source: `.github/skills/bicep-avm-author/SKILL.md`. If this prompt and the skill diverge, follow the skill.

## Preconditions

Do not author until all are true:

- service option analysis completed for each requested service
- explicit user option selection confirmed for each service
- mandatory inputs available: `location`, `projectName`, `environment`
- effective `deploymentMode` resolved (`azops` by default, `standard` only when explicitly requested)
- if effective mode is `azops`, both `targetSubscriptionId` and `targetResourceGroupName` are provided

If preconditions fail, return blockers only.

## Authoring workflow

1. Normalize region with `.github/skills/bicep-avm-author/references/geo-aliases.json`.
2. Resolve `regionShortCode` from `.github/skills/bicep-avm-author/references/geo-codes.json`.
3. If region resolution fails, stop and ask user for supported region.
4. Resolve destination path:
   - default to `azops` when `deploymentMode` is omitted
   - `standard` only when explicitly requested (`infra/{projectName}/`)
   - `azops` path via `.github/skills/bicep-avm-author/scripts/resolve-azops-path.ps1`
   - follow `.github/skills/bicep-avm-author/references/azops-path-resolution.md`
   - in `azops` mode, generate `.bicep` entrypoints only (never ARM `.json` templates)
5. Resolve AVM modules/versions for required resources.
6. Author one environment-specific entrypoint.
7. Use direct AVM references (`br/public:avm/...`) for AVM-covered resources.
8. Keep fixed design choices in code, not decision-proxy parameters.
9. Apply security/tagging/naming guardrails.
10. Validate with diagnostics, build, and lint.

## Required contract

Include baseline parameters:

```bicep
@description('Location for all resources')
param location string

@description('Project name for tagging and naming')
param projectName string

@description('Environment for tagging and naming (e.g. dev, test, prod)')
param environment string
```

Apply defaults:

- Tags: `Environment`, `ManagedBy`, `Project`
- `minimumTlsVersion: 'TLS1_2'` where supported
- Storage: `supportsHttpsTrafficOnly: true`, `allowBlobPublicAccess: false`, `allowSharedKeyAccess: false`
- Managed identity by default
- Key Vault uses RBAC authorization by default

## Placement guardrails

If producer AVM supports native inputs, place these in producer params:

- role assignments
- private endpoints
- diagnostics

Do not create standalone extension resources for these when native support exists.

## Exceptions

Raw Bicep for AVM-covered resources is blocked unless user explicitly states: `approve raw bicep`.

## Evidence output

After authoring, provide concise evidence summary:

- selected service options
- resolved AVM modules/versions
- validation outcomes (diagnostics/build/lint)
- docs citation URLs used during option analysis
