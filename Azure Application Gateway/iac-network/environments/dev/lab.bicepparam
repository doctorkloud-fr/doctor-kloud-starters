// =======================================================================
// lab.bicepparam — Paramètres lab A2i
// =======================================================================

using '../../main.bicep'

param environment   = 'dev'
param location      = 'westeurope'
param namingPrefix  = 'a2i'

param keyVaultName    = 'kv-a2i-tls-bicep'
param keyVaultSecretId = 'https://kv-a2i-tls-bicep.vault.azure.net/secrets/wildcard-a2itechnologies-fr'
param logAnalyticsId  = '/subscriptions/xxxxxxx-xxxxxx-xxxxxx/resourceGroups/rg-a2i-agw-bicep-westeu/providers/Microsoft.OperationalInsights/workspaces/law-a2i-network-prod'
param wafPolicyId     = '/subscriptions/xxxxxxx-xxxxxx-xxxxxx/resourceGroups/rg-a2i-agw-bicep-westeu/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/wafpol-a2i-web-dev'

param allowedHostnames = [
  'shop.a2itechnologies.fr'
  'web.a2itechnologies.fr'
  'rh.a2itechnologies.fr'
  'intranet.a2itechnologies.fr'
]

param minCapacity = 2
param maxCapacity = 10

param vnetAddressSpace       = '10.50.0.0/16'
param subnetAgwAddressPrefix = '10.50.0.0/24'

param tags = {
  Environment: 'Dev'
  Application: 'WebFrontal'
  Owner: 'owner@a2itechnologies.fr'
  ManagedBy: 'Bicep-IaC'
}
EOF

cat > ~/iac-network/environments/prod/prod.bicepparam <<'EOF'
// =======================================================================
// prod.bicepparam — Paramètres Production
// =======================================================================

using '../../main.bicep'

param environment   = 'prod'
param location      = 'westeurope'
param namingPrefix  = 'a2i'

param keyVaultName     = 'kv-a2i-tls-prod'
param keyVaultSecretId = 'https://kv-a2i-tls-prod.vault.azure.net/secrets/wildcard-a2itechnologies-fr'
param logAnalyticsId   = '/subscriptions/PROD-SUB-ID/resourceGroups/rg-a2i-network-prod-westeu/providers/Microsoft.OperationalInsights/workspaces/law-a2i-network-prod'
param wafPolicyId      = '/subscriptions/PROD-SUB-ID/resourceGroups/rg-a2i-network-prod-westeu/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/wafpol-a2i-web-prod'

param allowedHostnames = [
  'shop.a2itechnologies.fr'
  'web.a2itechnologies.fr'
  'rh.a2itechnologies.fr'
  'intranet.a2itechnologies.fr'
]

param minCapacity = 2
param maxCapacity = 25

param vnetAddressSpace       = '10.40.0.0/16'
param subnetAgwAddressPrefix = '10.40.0.0/24'

param tags = {
  Environment: 'Production'
  Application: 'WebFrontal'
  Owner: 'cloudops@a2itechnologies.fr'
  CostCenter: 'CC-IT-001'
  ManagedBy: 'Bicep-IaC'
}
