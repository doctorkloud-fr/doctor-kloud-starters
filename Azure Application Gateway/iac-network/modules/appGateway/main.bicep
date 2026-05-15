// =======================================================================
// appGateway.bicep — AGW V2 production-ready
// Auteur : Doctor Kloud — v1.0.0 — 2026-05
// =======================================================================

targetScope = 'resourceGroup'

param namingPrefix string
param environment string
param location string
param subnetId string
param publicIpId string
param managedIdentityId string
param keyVaultSecretId string
param wafPolicyId string
param allowedHostnames array
param minCapacity int
param maxCapacity int
param tags object

var locationShort = {
  westeurope: 'westeu'
  northeurope: 'northeu'
  francecentral: 'frcent'
}[location]

var agwName                = 'agw-${namingPrefix}-${environment}-${locationShort}'
var frontendIpConfigName   = 'feip-public'
var frontendPort80Name     = 'feport-80'
var frontendPort443Name    = 'feport-443'
var sslCertName            = 'cert-wildcard'
var httpListenerHttpName   = 'lst-http-redirect'
var probeName              = 'probe-health'
var backendPoolWebName     = 'bpool-web'
var backendPoolApiName     = 'bpool-api'
var backendSettingsWebName = 'bset-web'
var backendSettingsApiName = 'bset-api'
var rewriteSetName         = 'rwset-forwarded-proto'
var redirectConfigName     = 'redirect-http-to-https'
var redirectRuleName       = 'rule-http-redirect'

var httpsListeners = [for hostname in allowedHostnames: {
  name: 'lst-https-${replace(hostname, '.', '-')}'
  hostname: hostname
}]

resource agw 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: agwName
  location: location
  tags: tags
  zones: ['1', '2', '3']
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${managedIdentityId}': {} }
  }
  properties: {
    sku: { name: 'WAF_V2', tier: 'WAF_V2' }
    autoscaleConfiguration: { minCapacity: minCapacity, maxCapacity: maxCapacity }
    enableHttp2: true
    sslPolicy: { policyType: 'Predefined', policyName: 'AppGwSslPolicy20220101' }
    firewallPolicy: { id: wafPolicyId }
    gatewayIPConfigurations: [{ name: 'gwip-config', properties: { subnet: { id: subnetId } } }]
    frontendIPConfigurations: [{ name: frontendIpConfigName, properties: { publicIPAddress: { id: publicIpId } } }]
    frontendPorts: [
      { name: frontendPort80Name,  properties: { port: 80  } }
      { name: frontendPort443Name, properties: { port: 443 } }
    ]
    sslCertificates: [{ name: sslCertName, properties: { keyVaultSecretId: keyVaultSecretId } }]
    httpListeners: concat(
      [{
        name: httpListenerHttpName
        properties: {
          frontendIPConfiguration: { id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, frontendIpConfigName) }
          frontendPort: { id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, frontendPort80Name) }
          protocol: 'Http'
        }
      }],
      [for listener in httpsListeners: {
        name: listener.name
        properties: {
          frontendIPConfiguration: { id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, frontendIpConfigName) }
          frontendPort: { id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, frontendPort443Name) }
          protocol: 'Https'
          hostName: listener.hostname
          requireServerNameIndication: true
          sslCertificate: { id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', agwName, sslCertName) }
        }
      }]
    )
    backendAddressPools: [
      { name: backendPoolWebName, properties: { backendAddresses: [{ fqdn: 'app-${namingPrefix}-web-${environment}.azurewebsites.net' }] } }
      { name: backendPoolApiName, properties: { backendAddresses: [{ fqdn: 'app-${namingPrefix}-api-${environment}.azurewebsites.net' }] } }
    ]
    probes: [{
      name: probeName
      properties: {
        protocol: 'Https'
        path: '/health'
        interval: 30
        timeout: 30
        unhealthyThreshold: 3
        pickHostNameFromBackendHttpSettings: true
        minServers: 0
        match: { statusCodes: ['200-399'] }
      }
    }]
    backendHttpSettingsCollection: [
      {
        name: backendSettingsWebName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          connectionDraining: { enabled: true, drainTimeoutInSec: 60 }
          probe: { id: resourceId('Microsoft.Network/applicationGateways/probes', agwName, probeName) }
        }
      }
      {
        name: backendSettingsApiName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          connectionDraining: { enabled: true, drainTimeoutInSec: 60 }
          probe: { id: resourceId('Microsoft.Network/applicationGateways/probes', agwName, probeName) }
        }
      }
    ]
    rewriteRuleSets: [{
      name: rewriteSetName
      properties: {
        rewriteRules: [{
          name: 'set-x-forwarded-proto'
          ruleSequence: 100
          actionSet: {
            requestHeaderConfigurations: [{ headerName: 'X-Forwarded-Proto', headerValue: 'https' }]
          }
        }]
      }
    }]
    redirectConfigurations: [{
      name: redirectConfigName
      properties: {
        redirectType: 'Permanent'
        targetListener: { id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agwName, httpsListeners[0].name) }
        includePath: true
        includeQueryString: true
      }
    }]
    requestRoutingRules: concat(
      [{
        name: redirectRuleName
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: { id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agwName, httpListenerHttpName) }
          redirectConfiguration: { id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', agwName, redirectConfigName) }
        }
      }],
      [for (listener, idx) in httpsListeners: {
        name: 'rule-${listener.name}'
        properties: {
          ruleType: 'Basic'
          priority: 100 + idx
          httpListener: { id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agwName, listener.name) }
          backendAddressPool: { id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agwName, backendPoolWebName) }
          backendHttpSettings: { id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agwName, backendSettingsWebName) }
          rewriteRuleSet: { id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', agwName, rewriteSetName) }
        }
      }]
    )
  }
}

output agwResourceId string = agw.id
output agwName string = agw.name
