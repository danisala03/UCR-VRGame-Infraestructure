# Receives as param the environment name: Stage or Prod
param(
    [ValidateSet("Stage", "Prod")]
    [Parameter(Mandatory=$true)]
    [string]$Environment
)
Write-Host "Setting Environment: $Environment"

# Reads the values for the given Environment.
$environmentJson = Get-Content -Raw -Path "$PSScriptRoot\Templates\Environment-$Environment.json" | ConvertFrom-Json
Write-Host "SubId: $($environmentJson.SubscriptionId)"

# Log in to Azure using the Azure CLI. First asks if it is already logged in.
$loginResult = az account show
if ($loginResult) {
    Write-Host "Already logged in. Subscription set to: $($loginResult.id)"
} else {
    Write-Host "Not logged in. Logging in..."
    az login
}

# Sets the subscription for the given environment.
az account set -s $environmentJson.SubscriptionId
Write-Host "Logged in. Subscription set to: $($environmentJson.SubscriptionId)"

# Imports to call the functions from the other scripts.
. "$PSScriptRoot\CreateResourceGroup.ps1"
. "$PSScriptRoot\CreateAppService.ps1"
. "$PSScriptRoot\CreateVNet.ps1"
. "$PSScriptRoot\CreateNSG.ps1"
. "$PSScriptRoot\CreateUserAssignedIdentity.ps1"
. "$PSScriptRoot\CreateCosmosDB.ps1"
. "$PSScriptRoot\CreateKeyVault.ps1"
. "$PSScriptRoot\CreateVMSS.ps1"

# Creates Resource Group
Write-Host "Creating Resource Group: $($environmentJson.ResourceGroupName)"
CreateResourceGroup -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location

# Create VNet
Write-Host "Creating VNet: $($environmentJson.VNetName)"
CreateVNet -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -VNetName $environmentJson.VNetName -PublicSubnetName1 $environmentJson.PublicSubnetName1 -PrivateSubnetName1 $environmentJson.PrivateSubnetName1 -PublicSubnetName2 $environmentJson.PublicSubnetName2 -PrivateSubnetName2 $environmentJson.PrivateSubnetName2 -VMSSSubnetName $environmentJson.VMSSSubnetName

# Creates and Configures Azure Network Security Group (NSG)
Write-Host "Creating and Configuring Azure Network Security Groups (NSG)"

Write-Host "Creating Private NSG: $($environmentJson.NSGPrivateName)"
CreatePrivateNSG -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -NSGName $environmentJson.NSGPrivateName -VNetName $environmentJson.VNetName -PrivateSubnetName $environmentJson.VMSSSubnetName

Write-Host "Creating Public NSG: $($environmentJson.NSGPublicName)"
CreatePublicNSG -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -NSGName $environmentJson.NSGPublicName -VNetName $environmentJson.VNetName -PublicSubnetName $environmentJson.PublicSubnetName1

# Creates App Service
Write-Host "Creating App Services"

# First Front End App
CreateAppService -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -WebAppName $environmentJson.WebAppNameWestUS -Sku $environmentJson.Sku -PythonVersion $environmentJson.PythonVersion -RepoUrl $environmentJson.RepoUrl -VNetName $environmentJson.VNetName -PublicSubnetName $environmentJson.PublicSubnetName1 -PrivateSubnetName $environmentJson.PrivateSubnetName1
CreateAppService -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -WebAppName $environmentJson.WebAppNameEastUS -Sku $environmentJson.Sku -PythonVersion $environmentJson.PythonVersion -RepoUrl $environmentJson.RepoUrl -VNetName $environmentJson.VNetName -PublicSubnetName $environmentJson.PublicSubnetName2 -PrivateSubnetName $environmentJson.VMSSSubnetName

# Then Game App
CreateAppService -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -WebAppName $environmentJson.WebAppNameForGameWestUS -Sku $environmentJson.Sku -PythonVersion $environmentJson.PythonVersion -RepoUrl $environmentJson.RepoUrl -VNetName $environmentJson.VNetName -PublicSubnetName $environmentJson.PrivateSubnetName1 -PrivateSubnetName $environmentJson.PrivateSubnetName1
CreateAppService -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -WebAppName $environmentJson.WebAppNameForGameEastUS -Sku $environmentJson.Sku -PythonVersion $environmentJson.PythonVersion -RepoUrl $environmentJson.RepoUrl -VNetName $environmentJson.VNetName -PublicSubnetName $environmentJson.PrivateSubnetName2 -PrivateSubnetName $environmentJson.VMSSSubnetName

# Finally, adds Azure Front Door for Acitve - Pasive architecture
Write-Host "Creating Azure Front Door"
CreateAzureFrontDoor -RgName $environmentJson.ResourceGroupName -AzFrontDoorProfileNameFrontEnd $environmentJson.AzFrontDoorProfileNameFrontEnd -AzFrontDoorProfileUcrForGameApp $environmentJson.AzFrontDoorProfileUcrForGameApp -OriginGroupNameFrontEnd $environmentJson.OriginGroupNameFrontEnd -OriginGroupNameForGameApp $environmentJson.OriginGroupNameForGameApp -WebAppNameWestUS $environmentJson.WebAppNameWestUS -WebAppNameEastUS $environmentJson.WebAppNameEastUS -WebAppNameForGameWestUS $environmentJson.WebAppNameForGameWestUS -WebAppNameForGameEastUS $environmentJson.WebAppNameForGameEastUS

# Creates VMSS
Write-Host "Creating VMSS: $($environmentJson.VMSSName)"
#CreateVMSS -RgName $environmentJson.ResourceGroupName -Location $environmentJson.SecondaryLocation -VMSSName $environmentJson.VMSSName -VNetName $environmentJson.VNetName -VMSSSubnetName $environmentJson.VMSSSubnetName -NSGPublicName $environmentJson.NSGPublicName

# Creates User Assigned Managed Identity
Write-Host "Creating User Assigned Managed Identity: $($environmentJson.UserAssignedIdentityName)"
CreateUAIdentity -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -UserAssignedIdentityName $environmentJson.UserAssignedIdentityName

# Creates Key Vault
Write-Host "Creating Key Vault: $($environmentJson.KeyVaultName)"
CreateKeyVault -SubscriptionId $environmentJson.SubscriptionId -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -KeyVaultName $environmentJson.KeyVaultName -KeyVaultKey $environmentJson.KeyVaultKey -UserAssignedIdentityName $environmentJson.UserAssignedIdentityName -VNetName $environmentJson.VNetName -PrivateSubnetName $environmentJson.VMSSSubnetName -VMSSName $environmentJson.VMSSName 

# Creates Cosmos DB Account
Write-Host "Creating Cosmos DB Account: $($environmentJson.CosmosDBAccountName)"
CreateCosmosDBAccount -SubscriptionId $environmentJson.SubscriptionId -RgName $environmentJson.ResourceGroupName -CosmosDBAccountName $environmentJson.CosmosDBAccountName -Location $environmentJson.Location -SecondaryLocation $environmentJson.SecondaryLocation -UserAssignedIdentityName $environmentJson.UserAssignedIdentityName -VNetName $environmentJson.VNetName -KeyVaultName $environmentJson.KeyVaultName -KeyVaultKey $environmentJson.KeyVaultKey -PrivateSubnetName $environmentJson.VMSSSubnetName

