# Authoring Evidence

## Inputs and Locked Decisions
- location: `swedencentral`
- regionShortCode: `sdc`
- projectName: `hejsan01`
- environment: `prod`
- demand profile: `low`
- cost objective: `balanced`
- hard constraints: Function App and Key Vault with public access enabled exception in prod.

## Service Option Analysis (Microsoft Learn)

| Service | Option (SKU/tier) | Cost profile | Why it satisfies constraints | Key tradeoff | Recommended (Yes/No) |
| --- | --- | --- | --- | --- | --- |
| Function App | Consumption `Y1` | Lower. Cost risk: cold-start latency and scaling variance. | Meets low-demand balanced objective with pay-per-execution model and supports public endpoint. | Less predictable latency than Premium/Dedicated plans. | Yes |
| Function App | Elastic Premium `EP1` | Higher. Cost risk: always-ready baseline cost at low load. | Better predictable performance while still supporting serverless scale. | Higher baseline spend. | No |
| Function App | Dedicated `B1/S1` | Medium. Cost risk: always-on billing when idle. | Predictable fixed hosting model with public endpoint support. | Manual capacity right-sizing required. | No |

Assumptions:
- pricing model: `consumption` / `elastic premium` / `provisioned dedicated`
- demand profile assumption: `low`

| Service | Option (SKU/tier) | Cost profile | Why it satisfies constraints | Key tradeoff | Recommended (Yes/No) |
| --- | --- | --- | --- | --- | --- |
| Key Vault | `standard` | Lower. Cost risk: no HSM-backed key capability. | Supports required secret store and public network access configuration. | No premium HSM features. | Yes |
| Key Vault | `premium` | Higher. Cost risk: unnecessary spend if HSM not required. | Adds HSM-backed key support for stricter crypto requirements. | Higher transaction cost and baseline spend. | No |

Assumptions:
- pricing model: `standard` / `premium`
- demand profile assumption: `low`

## User-Selected Service Options (Confirmed)
- Function App plan: `Y1` (Consumption)
- Key Vault SKU: `standard`
- Approved exception: public network access enabled for Function App and Key Vault in `prod`

## AVM Modules Resolved
- `br/public:avm/res/web/serverfarm:0.7.0`
- `br/public:avm/res/web/site:0.22.0`
- `br/public:avm/res/storage/storage-account:0.31.2`
- `br/public:avm/res/key-vault/vault:0.13.3`

## Security Baseline Applied
- Required tags: `Environment`, `ManagedBy`, `Project`
- Storage account: `supportsHttpsTrafficOnly: true`, `allowBlobPublicAccess: false`, `minimumTlsVersion: TLS1_2`
- Key Vault defaults to RBAC (`enableRbacAuthorization: true`) and purge protection enabled
- Function App uses system-assigned managed identity
- Key Vault data-plane role assignment granted to Function App identity (`Key Vault Secrets User`)
- Storage data-plane roles granted to Function App identity for identity-based host storage access
- Intentional exception: `publicNetworkAccess: 'Enabled'` for Function App and Key Vault

## Microsoft Learn References
- Azure Functions hosting options and scale: https://learn.microsoft.com/azure/azure-functions/functions-scale
- Azure Functions networking options: https://learn.microsoft.com/azure/azure-functions/functions-networking-options
- Function App managed identity: https://learn.microsoft.com/azure/app-service/overview-managed-identity
- Key Vault overview and SKU guidance: https://learn.microsoft.com/azure/key-vault/general/overview
- Key Vault network security: https://learn.microsoft.com/azure/key-vault/general/network-security
- Key Vault pricing: https://learn.microsoft.com/azure/key-vault/general/about-pricing
