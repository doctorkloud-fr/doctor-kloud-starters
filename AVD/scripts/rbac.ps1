param(
  [Parameter(Mandatory=$true)][string]$SubscriptionId,
  [Parameter(Mandatory=$true)][string]$ResourceGroupName,
  [Parameter(Mandatory=$true)][string]$AppGroupResourceId,
  [Parameter(Mandatory=$true)][string]$PrincipalObjectId
)

$ErrorActionPreference = "Stop"

Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

$rgScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"

function Ensure-Role($roleName, $scope) {
  $existing = Get-AzRoleAssignment -ObjectId $PrincipalObjectId -Scope $scope -ErrorAction SilentlyContinue |
    Where-Object { $_.RoleDefinitionName -eq $roleName } |
    Select-Object -First 1

  if ($existing) {
    Write-Host "OK: $roleName already assigned on $scope"
    return
  }

  New-AzRoleAssignment -ObjectId $PrincipalObjectId -RoleDefinitionName $roleName -Scope $scope | Out-Null
  Write-Host "Assigned: $roleName on $scope"
}

Ensure-Role "Desktop Virtualization User" $AppGroupResourceId
Ensure-Role "Virtual Machine User Login"  $rgScope
