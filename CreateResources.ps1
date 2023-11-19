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

# Creates Resource Group
Write-Host "Creating Resource Group: $($environmentJson.ResourceGroupName)"
CreateResourceGroup -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location

# Create VNet
Write-Host "Creating VNet: $($environmentJson.VNetName)"
#CreateVNet -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -VNetName $environmentJson.VNetName -SubnetName $environmentJson.SubnetName

# Creates App Service
Write-Host "Creating App Service: $($environmentJson.WebAppName)"
#CreateAppService -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -WebAppName $environmentJson.WebAppName -Sku $environmentJson.Sku -PythonVersion $environmentJson.PythonVersion -RepoUrl $environmentJson.RepoUrl -VNetName $environmentJson.VNetName -SubnetName $environmentJson.SubnetName

# Creates and Configures Azure Network Security Group (NSG)
Write-Host "Creating and Configuring Azure Network Security Group (NSG): $($environmentJson.NSGName)"
CreatePublicNSG -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location -NSGName $environmentJson.NSGName -VNetName $environmentJson.VNetName -SubnetName $environmentJson.SubnetName