// =======================================================================
// identity.bicep — User-Assigned MI + role assignment Key Vault
// Auteur : Doctor Kloud — v1.0.0 — 2026-05
// =======================================================================

targetScope = 'resourceGroup'

param namingPrefix string
param environment string
param location string
param keyVaultName string
param tags object

var locationShort = {
  westeurope: 'westeu'
  northeurope: 'northeu'
  francecentral: 'frcent'
}[location]

var managedIdentityName      = 'id-${namingPrefix}-agw-${environment}-${locationShort}'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, managedIdentity.id, keyVaultSecretsUserRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      keyVaultSecretsUserRoleId
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
