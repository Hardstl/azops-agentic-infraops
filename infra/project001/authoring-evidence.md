# Authoring Evidence

## Inputs and Locked Decisions
- location: `swedencentral`
- regionShortCode: `sdc`
- projectName: `project001`
- environment: `dev`
- demand profile: `medium`
- cost objective: `lowest-cost`

## User-Selected Service Options
- App Service Plan: `P1v3`, zone-redundant, minimum capacity `2`
- Azure SQL Database: `General Purpose vCore (GP_Gen5_2)`, `zoneRedundant: true`
- Application Gateway: `WAF_v2`, autoscale (`min: 2`, `max: 10`), zone-redundant
- Storage Account: `Standard_ZRS`

## AVM Modules Resolved
- `br/public:avm/res/network/virtual-network:0.7.2`
- `br/public:avm/res/network/network-security-group:0.5.2`
- `br/public:avm/res/network/private-dns-zone:0.8.0`
- `br/public:avm/res/network/public-ip-address:0.12.0`
- `br/public:avm/res/network/application-gateway-web-application-firewall-policy:0.2.1`
- `br/public:avm/res/network/application-gateway:0.8.0`
- `br/public:avm/res/managed-identity/user-assigned-identity:0.5.0`
- `br/public:avm/res/web/serverfarm:0.7.0`
- `br/public:avm/res/web/site:0.22.0`
- `br/public:avm/res/key-vault/vault:0.13.3`
- `br/public:avm/res/sql/server:0.21.1`
- `br/public:avm/res/storage/storage-account:0.31.2`
- `br/public:avm/res/operational-insights/workspace:0.15.0`
- `br/public:avm/res/insights/component:0.7.1`

## Baseline Architecture Mapping
- Public ingress is Azure Application Gateway WAF_v2 with HTTPS and HTTP->HTTPS redirect.
- App Service ingress is private via App Service private endpoint (`privatelink.azurewebsites.net`).
- App Service uses VNet integration subnet for outbound private connectivity.
- SQL Server, Key Vault, and Storage use private endpoints with public network access disabled.
- Private DNS zones are linked to the VNet for App Service, SQL, Key Vault, and Blob endpoints.
- Zone redundancy enabled for App Service plan, Application Gateway deployment zones, SQL database, and storage replication (ZRS).

## Security Baseline Applied
- `publicNetworkAccess: 'Disabled'` for App Service, SQL Server, Key Vault, and Storage.
- `httpsOnly: true` for App Service.
- TLS minimums set (`App Service min TLS 1.2`, `SQL minimal TLS 1.2`, `Storage minimum TLS 1.2`).
- Key Vault uses RBAC authorization (`enableRbacAuthorization: true`) and purge protection enabled.
- Storage blocks blob public access and enforces HTTPS-only traffic.
- Dedicated NSGs assigned to all non-reserved subnets.

## Option Analysis References (Microsoft Learn)
- Baseline architecture: https://learn.microsoft.com/azure/architecture/web-apps/app-service/architectures/baseline-zone-redundant
- App Service zone redundancy requirements: https://learn.microsoft.com/azure/reliability/reliability-app-service#resilience-to-availability-zone-failures
- SQL zone redundancy support/tier constraints: https://learn.microsoft.com/azure/reliability/reliability-sql-database#resilience-to-availability-zone-failures
- SQL zone-redundant availability details: https://learn.microsoft.com/azure/azure-sql/database/high-availability-sla-local-zone-redundancy
- Application Gateway v2 zone redundancy: https://learn.microsoft.com/azure/reliability/reliability-application-gateway-v2#resilience-to-availability-zone-failures
- Storage ZRS recommendation: https://learn.microsoft.com/azure/storage/common/storage-redundancy#redundancy-in-the-primary-region

## Validation Commands Planned
- `mcp__bicep__get_bicep_file_diagnostics` on `infra/project001/main.dev.bicep`
- `bicep build infra/project001/main.dev.bicep`
- `bicep lint infra/project001/main.dev.bicep`
