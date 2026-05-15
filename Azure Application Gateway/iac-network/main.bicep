// =======================================================================
// main.bicep — Orchestration déploiement AGW V2 production-ready
// Auteur : Doctor Kloud — v1.0.0 — 2026-05
// =======================================================================

targetScope = 'resourceGroup'

@description('Environnement cible : prod, staging ou dev')
@allowed(['prod', 'staging', 'dev'])
param environment string

@description('Région Azure de déploiement')
@allowed(['francecentral', 'westeurope', 'northeurope'])
param location string = 'westeurope'

@description('Préfixe de nommage (ex: a2i, client, contoso)')
@minLength(3)
@maxLength(10)
param namingPrefix string

@description('Nom du Key Vault contenant le certificat TLS')
param keyVaultName string

@description('Secret ID complet du certificat Wildcard dans Key Vault')
param keyVaultSecretId string

@description('Resource ID du workspace Log Analytics')
param logAnalyticsId string

@description('Liste des Hostnames à exposer sur les Listeners HTTPS')
param allowedHostnames array

@description('Resource ID de la WAF Policy associée')
param wafPolicyId string

@description('Nombre minimum d instances autoscale (jamais 0)')
@minValue(2)
@maxValue(125)
param minCapacity int = 2

@description('Nombre maximum d instances autoscale')
@minValue(2)
@maxValue(125)
param maxCapacity int = 25

@description('CIDR du VNet')
param vnetAddressSpace string = '10.40.0.0/16'

@description('CIDR du Subnet AGW (au moins /24)')
param subnetAgwAddressPrefix string = '10.40.0.0/24'

@description('Tags appliqués à toutes les ressources')
param tags object

// -----------------------------------------------------------------------
// MODULES
// -----------------------------------------------------------------------

module networking 'modules/networking/main.bicep' = {
  name: 'deploy-networking-${environment}'
  params: {
    namingPrefix: namingPrefix
    environment: environment
    location: location
    vnetAddressSpace: vnetAddressSpace
    subnetAgwAddressPrefix: subnetAgwAddressPrefix
    tags: tags
  }
}

module identity 'modules/identity/main.bicep' = {
  name: 'deploy-identity-${environment}'
  params: {
    namingPrefix: namingPrefix
    environment: environment
    location: location
    keyVaultName: keyVaultName
    tags: tags
  }
}

module appGateway 'modules/appGateway/main.bicep' = {
  name: 'deploy-agw-${environment}'
  params: {
    namingPrefix: namingPrefix
    environment: environment
    location: location
    subnetId: networking.outputs.subnetAgwId
    publicIpId: networking.outputs.publicIpId
    managedIdentityId: identity.outputs.managedIdentityId
    keyVaultSecretId: keyVaultSecretId
    wafPolicyId: wafPolicyId
    allowedHostnames: allowedHostnames
    minCapacity: minCapacity
    maxCapacity: maxCapacity
    tags: tags
  }
  dependsOn: [networking, identity]
}

module monitoring 'modules/monitoring/main.bicep' = {
  name: 'deploy-monitoring-${environment}'
  params: {
    namingPrefix: namingPrefix
    environment: environment
    location: location
    agwResourceId: appGateway.outputs.agwResourceId
    agwName: appGateway.outputs.agwName
    logAnalyticsId: logAnalyticsId
    tags: tags
  }
  dependsOn: [appGateway]
}

// -----------------------------------------------------------------------
// OUTPUTS
// -----------------------------------------------------------------------

output agwResourceId string = appGateway.outputs.agwResourceId
output agwPublicIp string = networking.outputs.publicIpAddress
output agwManagedIdentityId string = identity.outputs.managedIdentityId
