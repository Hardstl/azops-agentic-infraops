# AzOps Path Resolution

## Purpose
- Route generated Bicep files to the correct AzOps resource group folder when AzOps mode is enabled.
- Keep generation deterministic and block on ambiguity.

## Mode Behavior
- Default `deploymentMode` to `azops` when omitted.
- Use `standard` only when explicitly requested.

## Required Inputs (effective AzOps mode)
- `deploymentMode` effectively equals `azops`
- `targetSubscriptionId`
- `targetResourceGroupName`

## Configuration Source
- `references/azops-config.json`
  - `azopsRoot`
  - `privateDnsManagedByPolicy`
  - `discovery.maxDepth`

## Resolution Algorithm
1. Read `references/azops-config.json`.
2. Validate `azopsRoot` exists.
3. Perform targeted subscription lookup under `azopsRoot` up to `maxDepth` using `targetSubscriptionId`.
4. Resolve candidate subscription folders by matching exact GUID in parentheses in subscription folder name (for example `... (dffdf7f7-dd2a-45ca-9f79-9da717b99dee)`).
5. Resolve candidate resource group folder as a direct child of the subscription folder:
   - `<subscription>/<resourceGroupName>` (case-insensitive match).
6. If exactly one path matches, set `resolvedAzopsPath`.
7. If no matches, block and ask user (do not create folders automatically).
8. If multiple matches, block and present candidate paths for disambiguation.

Optional helper script:
- `scripts/resolve-azops-path.ps1 -SubscriptionId <id> -ResourceGroupName <name>`

## Enforcement Rules
- If effective mode is `azops` and `targetSubscriptionId` or `targetResourceGroupName` is missing, block and ask user before any authoring.
- In AzOps mode, write generated Bicep only to `resolvedAzopsPath`.
- In AzOps mode, generate `.bicep` entrypoint files only; do not generate ARM template `.json` files.
- Do not write generated solution code to `infra/bicep/{project}/` in AzOps mode.
- Do not auto-create AzOps subscription/resource group folders.
- In AzOps mode, do not generate `deploy.ps1`; deployment is owned by AzOps/GitOps pipeline.
- Resolver supports only AzOps folder structure:
  - `<subscription>/<resourceGroupName>`

## Evidence Requirements (Lean Mode)
- Summarize in conversation:
  - `deploymentMode = azops`
  - `targetSubscriptionId`
  - `targetResourceGroupName`
  - `resolvedAzopsPath`
  - path resolution result (`unique|none|multiple`)
