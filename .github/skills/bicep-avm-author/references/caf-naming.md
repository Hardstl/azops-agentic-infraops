# CAF Naming Reference (Bicep AVM Author)

## Purpose

Use this document as the full naming reference for this skill.
It combines:

- Microsoft Cloud Adoption Framework (CAF) naming guidance
- CAF abbreviation recommendations
- Azure Resource Manager naming limits for commonly used resource types
- This skill's enforced region short-code pattern (`geo-aliases.json` + `geo-codes.json`)

## Source of truth

Primary Microsoft sources:

1. Define your naming convention:
   - https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
2. Abbreviation recommendations for Azure resources:
   - https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
3. Naming rules and restrictions for Azure resources:
   - https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules

Skill-local region references:

1. [geo-aliases.json](./geo-aliases.json)
2. [geo-codes.json](./geo-codes.json)
3. [service-option-playbook.md](./service-option-playbook.md) (for pre-authoring service/SKU option decisions)

## Naming components (CAF)

CAF recommends composing names from relevant components:

- Resource type abbreviation
- Workload/application/project identifier
- Environment (`dev`, `test`, `prod`, etc.)
- Region
- Instance/suffix (when needed for uniqueness)

Not every resource should include every component. Pick only stable and useful components.

## Skill-standard naming contract

This skill uses a deterministic, region-aware convention:

- Always collect `location` from user input
- Normalize input via `geo-aliases.json` to canonical Azure region
- Resolve `regionShortCode` from `geo-codes.json`
- Include `regionShortCode` in generated resource names
- Use `uniqueString(resourceGroup().id)` for global-uniqueness resources

If region alias or short code lookup fails, stop and ask for a supported Azure region.

## Recommended component order

For hyphen-allowed resource types:

- `{abbr}-{workloadOrProject}-{regionCode}-{env}-{instanceOrSuffix}`

For resources that disallow hyphens (for example Storage Account):

- `{abbr}{workloadOrProject}{regionCode}{env}{instanceOrSuffix}`

## Standard abbreviations (CAF aligned)

The official CAF list is large. This table includes the common resources used by this skill and related AVM scenarios.

| Resource | Provider type | CAF abbreviation | Recommended pattern |
| --- | --- | --- | --- |
| Resource Group | `Microsoft.Resources/resourceGroups` | `rg` | `rg-{project}-{env}` |
| Virtual Network | `Microsoft.Network/virtualNetworks` | `vnet` | `vnet-{project}-{regionCode}-{env}` |
| Subnet | `Microsoft.Network/virtualNetworks/subnets` | `snet` | `snet-{purpose}-{env}` |
| Network Security Group | `Microsoft.Network/networkSecurityGroups` | `nsg` | `nsg-{workload}-{env}` |
| Key Vault | `Microsoft.KeyVault/vaults` | `kv` | `kv-{project}-{regionCode}-{env}-{suffix}` |
| Storage Account | `Microsoft.Storage/storageAccounts` | `st` | `st{project}{regionCode}{env}{suffix}` |
| App Service Plan | `Microsoft.Web/serverFarms` | `asp` | `asp-{project}-{regionCode}-{env}` |
| Web App | `Microsoft.Web/sites` | `app` | `app-{project}-{regionCode}-{env}` |
| Function App | `Microsoft.Web/sites` | `func` | `func-{project}-{regionCode}-{env}` |
| SQL Server | `Microsoft.Sql/servers` | `sql` | `sql-{project}-{regionCode}-{env}` |
| SQL Database | `Microsoft.Sql/servers/databases` | `sqldb` | `sqldb-{project}-{env}` |
| Static Web App | `Microsoft.Web/staticSites` | `stapp` | `stapp-{project}-{regionCode}-{env}` |
| Front Door profile | `Microsoft.Cdn/profiles` | `afd` | `afd-{project}-{env}` |
| Front Door endpoint | `Microsoft.Cdn/profiles/afdEndpoints` | `fde` | `fde-{project}-{env}` |
| Log Analytics Workspace | `Microsoft.OperationalInsights/workspaces` | `log` | `log-{project}-{regionCode}-{env}` |
| Application Insights | `Microsoft.Insights/components` | `appi` | `appi-{project}-{regionCode}-{env}` |
| Container App | `Microsoft.App/containerApps` | `ca` | `ca-{project}-{regionCode}-{env}` |
| Container App Environment | `Microsoft.App/managedEnvironments` | `cae` | `cae-{project}-{regionCode}-{env}` |
| Cosmos DB (SQL/NoSQL account family) | `Microsoft.DocumentDB/databaseAccounts` | `cosmos` (common CAF example) | `cosmos-{project}-{regionCode}-{env}` |
| Service Bus Namespace | `Microsoft.ServiceBus/namespaces` | `sbns` | `sbns-{project}-{regionCode}-{env}` |
| Service Bus Queue | `Microsoft.ServiceBus/namespaces/queues` | `sbq` | `sbq-{project}-{env}` |
| Service Bus Topic | `Microsoft.ServiceBus/namespaces/topics` | `sbt` | `sbt-{project}-{env}` |

Note:
- CAF abbreviations are recommendations, not hard protocol requirements.
- For full and latest catalog, always refer to CAF abbreviations page.

## Resource naming limits and rules (common set)

These are the constraints that usually break deployments when ignored.

| Resource | Scope | Length | Character rules (summary) |
| --- | --- | --- | --- |
| Resource Group (`Microsoft.Resources/resourceGroups`) | Subscription | `1-90` | Unicode letters/digits plus `_ . - ( )`; cannot end with `.` |
| VNet (`Microsoft.Network/virtualNetworks`) | Resource group | `2-64` | Alphanumeric, `_ . -`; start alphanumeric; end alphanumeric or `_` |
| Subnet (`Microsoft.Network/virtualNetworks/subnets`) | VNet | `1-80` | Alphanumeric, `_ . -`; start alphanumeric; end alphanumeric or `_` |
| NSG (`Microsoft.Network/networkSecurityGroups`) | Resource group | `1-80` | Alphanumeric, `_ . -`; start alphanumeric; end alphanumeric or `_` |
| Key Vault (`Microsoft.KeyVault/vaults`) | Global | `3-24` | Alphanumeric and `-`; start letter; end letter/number; no consecutive hyphens |
| Storage Account (`Microsoft.Storage/storageAccounts`) | Global | `3-24` | Lowercase letters and numbers only |
| App Service Plan (`Microsoft.Web/serverFarms`) | Resource group | `1-60` | Alphanumeric, `-`, Unicode mapped to punycode |
| Web App / Function App (`Microsoft.Web/sites`) | Global or ASE domain scope | `2-60` | Alphanumeric and `-`; cannot start/end with `-` |
| SQL Server (`Microsoft.Sql/servers`) | Global | `1-63` | Lowercase letters, numbers, hyphens; cannot start/end with `-` |
| SQL Database (`Microsoft.Sql/servers/databases`) | SQL Server | `1-128` | Disallows certain special characters; cannot end with `.` or space |
| Log Analytics (`Microsoft.OperationalInsights/workspaces`) | Resource group | `4-63` | Alphanumeric and `-`; start/end alphanumeric |
| Application Insights (`Microsoft.Insights/components`) | Resource group | `1-260` | Disallows `% & \\ ? /` and control chars; cannot end with space or `.` |
| Service Bus Namespace (`Microsoft.ServiceBus/namespaces`) | Global | `6-50` | Alphanumeric and `-`; start letter; end letter/number |
| Container App (`Microsoft.App/containerApps`) | Resource group | `2-32` | Lowercase letters, numbers, hyphens; start letter; end alphanumeric |
| Front Door (`Microsoft.Cdn/profiles/afdEndpoints`) | Global | `1-50` | Alphanumeric and `-`; start/end alphanumeric |

## Length-constrained formulas (region-aware)

Use these formulas to preserve readability and stay safely below hard limits.

```bicep
// Required inputs
param location string
param projectName string
param environment string

// Deterministic normalization
var normalizedProjectName = toLower(replace(projectName, '-', ''))
var normalizedEnvironment = toLower(environment)
var uniqueSuffix = uniqueString(resourceGroup().id)

// Resolve externally (skill flow) from references/geo-codes.json after alias normalization
var regionShortCode = 'sdc'

// kv max 24:
// kv-{8}-{3}-{3}-{3} = 23 max
var kvName = 'kv-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'

// st max 24, lowercase alphanumeric only:
// st + 8 + 3 + 3 + 7 = 23 max
var storageAccountName = 'st${take(normalizedProjectName, 8)}${regionShortCode}${take(normalizedEnvironment, 3)}${take(uniqueSuffix, 7)}'

// sql server max 63
var sqlServerName = 'sql-${take(normalizedProjectName, 20)}-${regionShortCode}-${take(normalizedEnvironment, 4)}-${take(uniqueSuffix, 8)}'

// function app (global dns namespace, 2-60)
var functionAppName = 'func-${take(normalizedProjectName, 20)}-${regionShortCode}-${take(normalizedEnvironment, 4)}-${take(uniqueSuffix, 8)}'
```

## Region normalization and short-code resolution

Required workflow:

1. Accept user region input (`location`)
2. Convert to lowercase and trim
3. Resolve canonical region key using `geo-aliases.json`
4. Resolve short code from `geo-codes.json`
5. If either lookup fails, block and request a valid Azure region

Pseudo-flow:

```text
userInput -> normalize -> alias lookup -> canonicalRegion -> code lookup -> regionShortCode
```

## Do / Don't

Do:

- Use CAF abbreviations for resource type prefixes
- Include environment and region code where meaningful
- Use deterministic truncation with `take(...)`
- Include deterministic uniqueness suffix for globally unique names
- Validate against Azure resource-specific rules before deployment

Don't:

- Assume one naming pattern fits all resource types
- Use hyphens in storage account names
- Hardcode random suffixes
- Exceed max lengths (deployment fails late)
- Skip region alias/code resolution when this skill requires region short code

## Validation checklist

Before finalizing names:

1. Region provided by user and resolved to `regionShortCode`
2. Resource abbreviation aligns to CAF recommendation
3. Name length within resource-specific limit
4. Character set valid for resource
5. Global uniqueness included where required
6. Consistent env + region representation across resources

## Keeping this reference current

CAF abbreviations and Azure naming rules evolve.

When updating:

1. Re-check all three source pages in this document
2. Keep this file aligned with `SKILL.md` naming formulas
3. Keep `geo-codes.json` and `geo-aliases.json` synchronized with desired region coverage
