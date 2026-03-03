using './main.dev.bicep'

param location = 'swedencentral'
param projectName = 'project001'
param environment = 'dev'

param sqlAdministratorLogin = 'sqladminuser'
param sqlAdministratorPassword = '<replace-with-a-secure-password>'

// Versioned Key Vault secret ID for the App Gateway TLS certificate (PFX)
param appGatewayTlsCertificateSecretId = '<https://<key-vault-name>.vault.azure.net/secrets/<cert-secret-name>/<version>>'
