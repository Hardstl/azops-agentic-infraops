targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string

@description('Project name used for naming and tags.')
param projectName string

@description('Environment name (for example: dev, prod).')
param environment string

@description('SQL administrator login name.')
param sqlAdministratorLogin string

@secure()
@description('SQL administrator login password.')
param sqlAdministratorPassword string

@secure()
@description('Key Vault certificate secret ID (versioned) used by Application Gateway HTTPS listener.')
param appGatewayTlsCertificateSecretId string

var normalizedProjectName = toLower(replace(projectName, '-', ''))
var normalizedEnvironment = toLower(environment)
var regionShortCode = 'sdc'
var uniqueSuffix = uniqueString(resourceGroup().id, projectName, environment)

var tags = {
  Environment: environment
  ManagedBy: 'AzOps'
  Project: projectName
}

var vnetName = 'vnet-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var appGatewayNsgName = 'nsg-agw-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'
var appServiceNsgName = 'nsg-app-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'
var privateEndpointNsgName = 'nsg-pe-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'

var appGatewayPublicIpName = 'pip-agw-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'
var wafPolicyName = 'wafp-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'
var appGatewayName = 'agw-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'

var appServicePlanName = 'asp-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var webAppName = 'app-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var keyVaultName = 'kv-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var sqlServerName = 'sql-${take(normalizedProjectName, 8)}-${regionShortCode}-${take(normalizedEnvironment, 3)}-${take(uniqueSuffix, 3)}'
var sqlDatabaseName = 'sqldb-${take(normalizedProjectName, 10)}-${take(normalizedEnvironment, 3)}'
var storageName = 'st${take(normalizedProjectName, 8)}${regionShortCode}${take(normalizedEnvironment, 3)}${take(uniqueSuffix, 7)}'

var logAnalyticsWorkspaceName = 'law-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'
var appInsightsName = 'appi-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'
var appGatewayIdentityName = 'uami-agw-${take(normalizedProjectName, 8)}-${take(uniqueSuffix, 3)}'

var appGatewaySubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'GatewaySubnet')
var appServiceSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AppServiceSubnet')
var privateEndpointSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'PrivateEndpointsSubnet')

var appGatewayPublicIpId = resourceId('Microsoft.Network/publicIPAddresses', appGatewayPublicIpName)
var wafPolicyId = resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', wafPolicyName)
var appGatewayId = resourceId('Microsoft.Network/applicationGateways', appGatewayName)

var appServicePrivateDnsZoneName = 'privatelink.azurewebsites.net'
var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'
var sqlPrivateDnsZoneName = 'privatelink.${az.environment().suffixes.sqlServerHostname}'
var storagePrivateDnsZoneName = 'privatelink.blob.${az.environment().suffixes.storage}'

var appServicePrivateDnsZoneId = resourceId('Microsoft.Network/privateDnsZones', appServicePrivateDnsZoneName)
var keyVaultPrivateDnsZoneId = resourceId('Microsoft.Network/privateDnsZones', keyVaultPrivateDnsZoneName)
var sqlPrivateDnsZoneId = resourceId('Microsoft.Network/privateDnsZones', sqlPrivateDnsZoneName)
var storagePrivateDnsZoneId = resourceId('Microsoft.Network/privateDnsZones', storagePrivateDnsZoneName)

var logAnalyticsWorkspaceId = resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName)

var webAppDefaultHostname = '${webAppName}.azurewebsites.net'

module appGatewaySubnetNsg 'br/public:avm/res/network/network-security-group:0.5.2' = {
  params: {
    name: appGatewayNsgName
    location: location
    securityRules: [
      {
        name: 'Allow-Internet-HTTPS'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-GatewayManager'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 120
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Allow-To-PrivateEndpoints-443'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 200
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.2.0/27'
          destinationPortRange: '443'
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
}

module appServiceSubnetNsg 'br/public:avm/res/network/network-security-group:0.5.2' = {
  params: {
    name: appServiceNsgName
    location: location
    securityRules: [
      {
        name: 'Allow-To-PrivateEndpoints-443'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.2.0/27'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-To-AzureMonitor'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureMonitor'
          destinationPortRange: '443'
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
}

module privateEndpointSubnetNsg 'br/public:avm/res/network/network-security-group:0.5.2' = {
  params: {
    name: privateEndpointNsgName
    location: location
    tags: tags
    enableTelemetry: false
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.2' = {
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.1.0/24'
        networkSecurityGroupResourceId: appGatewaySubnetNsg.outputs.resourceId
      }
      {
        name: 'AppServiceSubnet'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: appServiceSubnetNsg.outputs.resourceId
        delegation: 'Microsoft.Web/serverFarms'
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      {
        name: 'PrivateEndpointsSubnet'
        addressPrefix: '10.0.2.0/27'
        networkSecurityGroupResourceId: privateEndpointSubnetNsg.outputs.resourceId
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
    tags: tags
    enableTelemetry: false
  }
}

module appServicePrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  params: {
    name: appServicePrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: [
      {
        name: '${take(vnetName, 60)}-appsvc'
        location: 'global'
        registrationEnabled: false
        virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', vnetName)
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    virtualNetwork
  ]
}

module keyVaultPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  params: {
    name: keyVaultPrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: [
      {
        name: '${take(vnetName, 60)}-kv'
        location: 'global'
        registrationEnabled: false
        virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', vnetName)
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    virtualNetwork
  ]
}

module sqlPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  params: {
    name: sqlPrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: [
      {
        name: '${take(vnetName, 60)}-sql'
        location: 'global'
        registrationEnabled: false
        virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', vnetName)
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    virtualNetwork
  ]
}

module storagePrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  params: {
    name: storagePrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: [
      {
        name: '${take(vnetName, 60)}-blob'
        location: 'global'
        registrationEnabled: false
        virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', vnetName)
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    virtualNetwork
  ]
}

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    tags: tags
    enableTelemetry: false
  }
}

module appInsights 'br/public:avm/res/insights/component:0.7.1' = {
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalyticsWorkspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

module appGatewayIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.0' = {
  params: {
    name: appGatewayIdentityName
    location: location
    tags: tags
    enableTelemetry: false
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.7.0' = {
  params: {
    name: appServicePlanName
    location: location
    skuName: 'P1v3'
    skuCapacity: 2
    zoneRedundant: true
    tags: tags
    enableTelemetry: false
  }
}

module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  params: {
    name: keyVaultName
    location: location
    sku: 'standard'
    enablePurgeProtection: true
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        service: 'vault'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: keyVaultPrivateDnsZoneId
            }
          ]
        }
      }
    ]
    roleAssignments: [
      {
        principalId: appGatewayIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    keyVaultPrivateDnsZone
    virtualNetwork
  ]
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.31.2' = {
  params: {
    name: storageName
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_ZRS'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        service: 'blob'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: storagePrivateDnsZoneId
            }
          ]
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    storagePrivateDnsZone
    virtualNetwork
  ]
}

module sqlServer 'br/public:avm/res/sql/server:0.21.1' = {
  params: {
    name: sqlServerName
    location: location
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    databases: [
      {
        name: sqlDatabaseName
        availabilityZone: -1
        requestedBackupStorageRedundancy: 'Zone'
        sku: {
          name: 'GP_Gen5_2'
          tier: 'GeneralPurpose'
        }
        zoneRedundant: true
      }
    ]
    privateEndpoints: [
      {
        service: 'sqlServer'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: sqlPrivateDnsZoneId
            }
          ]
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    sqlPrivateDnsZone
    virtualNetwork
  ]
}

module webApp 'br/public:avm/res/web/site:0.22.0' = {
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    virtualNetworkSubnetResourceId: appServiceSubnetId
    managedIdentities: {
      systemAssigned: true
    }
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    siteConfig: {
      healthCheckPath: '/healthz'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      scmMinTlsVersion: '1.2'
      remoteDebuggingEnabled: false
      vnetRouteAllEnabled: false
      http20Enabled: true
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          APPINSIGHTS_CONNECTIONSTRING: appInsights.outputs.connectionString
          APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.outputs.connectionString
          KEY_VAULT_URI: 'https://${keyVaultName}.${az.environment().suffixes.keyvaultDns}/'
          WEBSITE_RUN_FROM_PACKAGE: '1'
        }
      }
      {
        name: 'connectionstrings'
        properties: {
          DefaultConnection: {
            type: 'SQLAzure'
            value: 'Server=tcp:${sqlServerName}.${az.environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDatabaseName};Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          }
        }
      }
    ]
    privateEndpoints: [
      {
        service: 'sites'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: appServicePrivateDnsZoneId
            }
          ]
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    appServicePrivateDnsZone
    virtualNetwork
  ]
}

module appGatewayPublicIp 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  params: {
    name: appGatewayPublicIpName
    location: location
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    availabilityZones: [
      1
      2
      3
    ]
    tags: tags
    enableTelemetry: false
  }
}

module appGatewayWafPolicy 'br/public:avm/res/network/application-gateway-web-application-firewall-policy:0.2.1' = {
  params: {
    name: wafPolicyName
    location: location
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
    policySettings: {
      mode: 'Prevention'
      state: 'Enabled'
      requestBodyCheck: true
      fileUploadLimitInMb: 100
      maxRequestBodySizeInKb: 128
    }
    tags: tags
    enableTelemetry: false
  }
}

module appGateway 'br/public:avm/res/network/application-gateway:0.8.0' = {
  params: {
    name: appGatewayName
    location: location
    sku: 'WAF_v2'
    firewallPolicyResourceId: wafPolicyId
    autoscaleMinCapacity: 2
    autoscaleMaxCapacity: 10
    availabilityZones: [
      1
      2
      3
    ]
    enableHttp2: true
    managedIdentities: {
      userAssignedResourceIds: [
        appGatewayIdentity.outputs.resourceId
      ]
    }
    gatewayIPConfigurations: [
      {
        name: 'gateway-ipconfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontend-public'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIpId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port-80'
        properties: {
          port: 80
        }
      }
    ]
    sslCertificates: [
      {
        name: 'tls-cert'
        properties: {
          keyVaultSecretId: appGatewayTlsCertificateSecretId
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServiceBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: webAppDefaultHostname
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: 'appServiceHealthProbe'
        properties: {
          protocol: 'Https'
          path: '/healthz'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceHttpsSettings'
        properties: {
          protocol: 'Https'
          port: 443
          requestTimeout: 30
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          probe: {
            id: '${appGatewayId}/probes/appServiceHealthProbe'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'listener-https'
        properties: {
          protocol: 'Https'
          frontendIPConfiguration: {
            id: '${appGatewayId}/frontendIPConfigurations/frontend-public'
          }
          frontendPort: {
            id: '${appGatewayId}/frontendPorts/port-443'
          }
          sslCertificate: {
            id: '${appGatewayId}/sslCertificates/tls-cert'
          }
        }
      }
      {
        name: 'listener-http'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: '${appGatewayId}/frontendIPConfigurations/frontend-public'
          }
          frontendPort: {
            id: '${appGatewayId}/frontendPorts/port-80'
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: 'http-to-https'
        properties: {
          redirectType: 'Permanent'
          includePath: true
          includeQueryString: true
          targetListener: {
            id: '${appGatewayId}/httpListeners/listener-https'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'route-https-to-appservice'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: '${appGatewayId}/httpListeners/listener-https'
          }
          backendAddressPool: {
            id: '${appGatewayId}/backendAddressPools/appServiceBackendPool'
          }
          backendHttpSettings: {
            id: '${appGatewayId}/backendHttpSettingsCollection/appServiceHttpsSettings'
          }
        }
      }
      {
        name: 'route-http-redirect'
        properties: {
          ruleType: 'Basic'
          priority: 110
          httpListener: {
            id: '${appGatewayId}/httpListeners/listener-http'
          }
          redirectConfiguration: {
            id: '${appGatewayId}/redirectConfigurations/http-to-https'
          }
        }
      }
    ]
    diagnosticSettings: [
      {
        name: 'to-law'
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    appGatewayPublicIp
    appGatewayWafPolicy
    webApp
    keyVault
    virtualNetwork
  ]
}

output appGatewayResourceId string = appGateway.outputs.resourceId
output appGatewayPublicIpAddress string = appGatewayPublicIp.outputs.ipAddress
output webAppResourceId string = webApp.outputs.resourceId
output webAppDefaultHostname string = webAppDefaultHostname
output appServicePlanResourceId string = appServicePlan.outputs.resourceId
output sqlServerResourceId string = sqlServer.outputs.resourceId
output sqlDatabaseName string = sqlDatabaseName
output keyVaultResourceId string = keyVault.outputs.resourceId
output storageAccountResourceId string = storageAccount.outputs.resourceId
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output applicationInsightsResourceId string = appInsights.outputs.resourceId
