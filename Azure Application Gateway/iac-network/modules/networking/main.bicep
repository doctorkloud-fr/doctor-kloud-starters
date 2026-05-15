// =======================================================================
// networking.bicep — VNet, Subnet AGW, NSG, Public IP zone-redundante
// Auteur : Doctor Kloud — v1.0.0 — 2026-05
// =======================================================================

targetScope = 'resourceGroup'

param namingPrefix string
param environment string
param location string
param vnetAddressSpace string
param subnetAgwAddressPrefix string
param tags object

var locationShort = {
  westeurope: 'westeu'
  northeurope: 'northeu'
  francecentral: 'frcent'
}[location]

var vnetName         = 'vnet-${namingPrefix}-network-${environment}-${locationShort}'
var subnetAgwName    = 'snet-agw'
var nsgName          = 'nsg-${namingPrefix}-agw-${environment}-${locationShort}'
var publicIpName     = 'pip-${namingPrefix}-agw-${environment}-${locationShort}'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-GatewayManager-Inbound'
        properties: {
          description: 'OBLIGATOIRE — plan de contrôle Microsoft AGW V2'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer-Inbound'
        properties: {
          description: 'Health probes Azure Load Balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-Internet-HTTP-HTTPS-Inbound'
        properties: {
          description: 'Trafic utilisateur 80 et 443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['80', '443']
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Other-Inbound'
        properties: {
          description: 'Refus explicite tout autre trafic entrant'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [vnetAddressSpace] }
    subnets: [
      {
        name: subnetAgwName
        properties: {
          addressPrefix: subnetAgwAddressPrefix
          networkSecurityGroup: { id: nsg.id }
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: { name: 'Standard', tier: 'Regional' }
  zones: ['1', '2', '3']
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

output vnetId string = vnet.id
output subnetAgwId string = '${vnet.id}/subnets/${subnetAgwName}'
output publicIpId string = publicIp.id
output publicIpAddress string = publicIp.properties.ipAddress
output nsgId string = nsg.id
EOF

echo "✓ modules/networking/main.bicep créé"
modules/identity/main.bicep
bashmkdir -p ~/iac-network/modules/identity
cat > ~/iac-network/modules/identity/main.bicep <<'EOF'
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
