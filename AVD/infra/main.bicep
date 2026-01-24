targetScope = 'resourceGroup'

@description('Location')
param location string = resourceGroup().location

@description('Prefix for names')
param prefix string = 'a2i-avd-lab'

@description('HostPool name')
param hostPoolName string = '${prefix}-hostpool'

@description('RemoteApp Application Group name')
param appGroupName string = '${prefix}-remoteapp-ag'

@description('Workspace name')
param workspaceName string = '${prefix}-workspace'

@description('VNet name')
param vnetName string = '${prefix}-vnet'

@description('Subnet name')
param subnetName string = 'default'

@description('NSG name')
param nsgName string = '${prefix}-nsg'

@description('VNet CIDR')
param vnetCidr string = '10.0.0.0/16'

@description('Subnet CIDR')
param subnetCidr string = '10.0.0.0/24'

@description('Session host count')
@minValue(1)
param vmCount int = 1

@description('Session host VM size (zones disabled by not setting zones)')
param vmSize string = 'Standard_D2s_v6'

@description('VM name prefix (<=9 chars recommended)')
@maxLength(9)
param vmNamePrefix string = 'a2iavdsh'

@description('Local admin username')
param adminUsername string = 'avdlocaladmin'

@secure()
@description('Local admin password')
param adminPassword string

@description('Marketplace image reference')
param imagePublisher string = 'MicrosoftWindowsDesktop'
param imageOffer string = 'Windows-11'
param imageSku string = 'win11-25h2-avd'
param imageVersion string = 'latest'

@description('AADLoginForWindows typeHandlerVersion (major.minor), e.g. 2.2')
param aadLoginTypeHandlerVersion string

@description('DSC typeHandlerVersion (major.minor), e.g. 2.83')
param dscTypeHandlerVersion string

@description('DSC modules URL (Configuration_*.zip)')
param dscModulesUrl string

@description('Host pool registration token expiry hours')
@minValue(1)
@maxValue(72)
param registrationTokenExpiryHours int = 24

@description('Deployment time (utcNow() only valid here, not in vars)')
param deploymentTime string = utcNow()

// -------------------- Network --------------------
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetCidr ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetCidr
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// -------------------- AVD core --------------------
var customRdp = 'enablerdsaadauth:i:1;targetisaadjoined:i:1;'

// IMPORTANT: no formatDateTime() because not available in your bicep runtime.
// dateTimeAdd returns ISO-8601 string that AVD accepts.
var expiry = dateTimeAdd(deploymentTime, 'PT${registrationTokenExpiryHours}H')

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: hostPoolName
  location: location
  properties: {
    friendlyName: hostPoolName
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'RailApplications'
    maxSessionLimit: 10
    customRdpProperty: customRdp
    startVMOnConnect: false
    registrationInfo: {
      expirationTime: expiry
      registrationTokenOperation: 'Update'
    }
  }
}

// listRegistrationTokens() returns { value: [...] }
var tokenList = hostPool.listRegistrationTokens().value
var regToken = (length(tokenList) > 0) ? tokenList[0].token : ''

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: appGroupName
  location: location
  properties: {
    applicationGroupType: 'RemoteApp'
    hostPoolArmPath: hostPool.id
    friendlyName: appGroupName
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
  name: workspaceName
  location: location
  properties: {
    friendlyName: workspaceName
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

// -------------------- RemoteApps --------------------
resource appNotepad 'Microsoft.DesktopVirtualization/applicationGroups/applications@2024-04-03' = {
  name: 'notepad'
  parent: appGroup
  properties: {
    friendlyName: 'Notepad'
    description: 'Notepad'
    filePath: 'C:\\Windows\\System32\\notepad.exe'
    commandLineSetting: 'DoNotAllow'
    showInPortal: true
    iconPath: 'C:\\Windows\\System32\\notepad.exe'
    iconIndex: 0
  }
}

resource appPaint 'Microsoft.DesktopVirtualization/applicationGroups/applications@2024-04-03' = {
  name: 'mspaint'
  parent: appGroup
  properties: {
    friendlyName: 'Paint'
    description: 'Paint'
    filePath: 'C:\\Windows\\System32\\mspaint.exe'
    commandLineSetting: 'DoNotAllow'
    showInPortal: true
    iconPath: 'C:\\Windows\\System32\\mspaint.exe'
    iconIndex: 0
  }
}

// -------------------- Session hosts --------------------
var suffixLen = 6
var vmNames = [for i in range(0, vmCount): toLower('${vmNamePrefix}${substring(uniqueString(resourceGroup().id, deployment().name, string(i)), 0, suffixLen)}')]

resource nics 'Microsoft.Network/networkInterfaces@2024-01-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: { id: subnetId }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}]


resource vms 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (vmName, i) in vmNames: {
  name: vmName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Premium_LRS' }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
          properties: { deleteOption: 'Delete' }
        }
      ]
    }
  }
}]

// Entra login extension (mdmId required even if empty)
resource aadLoginExt 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}/AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: aadLoginTypeHandlerVersion
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
  dependsOn: [
    vms[i]
  ]
}]

// DSC AddSessionHost (installs agent + bootloader + registers)
resource dscExt 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}/MicrosoftPowershellDSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: dscTypeHandlerVersion
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: dscModulesUrl
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolName
        aadJoin: true
      }
    }
    protectedSettings: {
      properties: {
        registrationInfoToken: regToken
      }
    }
  }
  dependsOn: [
    aadLoginExt[i]
    hostPool
  ]
}]

output hostPoolId string = hostPool.id
output appGroupId string = appGroup.id
output workspaceId string = workspace.id
output sessionHostNames array = vmNames
