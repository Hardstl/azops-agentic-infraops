targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string

@description('Project name used for naming and tags.')
param projectName string

@description('Environment name (for example: prod, dev).')
param environment string

var normalizedProjectName = toLower(replace(projectName, '-', ''))
var normalizedEnvironment = toLower(environment)
var regionShortCode = 'sdc'
var uniqueSuffix = uniqueString(resourceGroup().id, projectName, environment)

var tags = {
  Environment: environment
  ManagedBy: 'AzOps'
  Project: projectName
}

var appServicePlanName = 'asp-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var functionAppName = 'func-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var keyVaultName = 'kv-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var storageName = 'st${take(normalizedProjectName, 8)}${regionShortCode}${take(normalizedEnvironment, 3)}${take(uniqueSuffix, 7)}'

module appServicePlan 'br/public:avm/res/web/serverfarm:0.7.0' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    skuName: 'Y1'
    skuCapacity: 1
    tags: tags
    enableTelemetry: false
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.31.2' = {
  name: 'storageAccount'
  params: {
    name: storageName
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    roleAssignments: [
      {
        principalId: functionApp.outputs.systemAssignedMIPrincipalId!
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
      {
        principalId: functionApp.outputs.systemAssignedMIPrincipalId!
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Queue Data Contributor'
      }
      {
        principalId: functionApp.outputs.systemAssignedMIPrincipalId!
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }
    ]
    tags: tags
    enableTelemetry: false
  }
}

module functionApp 'br/public:avm/res/web/site:0.22.0' = {
  name: 'functionApp'
  params: {
    name: functionAppName
    location: location
    kind: 'functionapp'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      scmMinTlsVersion: '1.2'
      http20Enabled: true
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          FUNCTIONS_EXTENSION_VERSION: '~4'
          FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
          WEBSITE_RUN_FROM_PACKAGE: '1'
          AzureWebJobsStorage__accountName: storageName
          AzureWebJobsStorage__credential: 'managedidentity'
          AzureWebJobsStorage__blobServiceUri: 'https://${storageName}.blob.${az.environment().suffixes.storage}'
          AzureWebJobsStorage__queueServiceUri: 'https://${storageName}.queue.${az.environment().suffixes.storage}'
          AzureWebJobsStorage__tableServiceUri: 'https://${storageName}.table.${az.environment().suffixes.storage}'
          KEY_VAULT_URI: 'https://${keyVaultName}.${az.environment().suffixes.keyvaultDns}/'
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
}

module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: 'keyVault'
  params: {
    name: keyVaultName
    location: location
    sku: 'standard'
    enablePurgeProtection: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    roleAssignments: [
      {
        principalId: functionApp.outputs.systemAssignedMIPrincipalId!
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
    ]
    tags: tags
    enableTelemetry: false
  }
}

output appServicePlanResourceId string = appServicePlan.outputs.resourceId
output storageAccountResourceId string = storageAccount.outputs.resourceId
output functionAppResourceId string = functionApp.outputs.resourceId
output functionAppName string = functionAppName
output keyVaultResourceId string = keyVault.outputs.resourceId
output keyVaultName string = keyVaultName
