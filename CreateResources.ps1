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

# Creates Resource Group
CreateResourceGroup -RgName $environmentJson.ResourceGroupName -Location $environmentJson.Location

# Creates App Service
#CreateAppService -RgName $environmentJson.ResourceGroupName $Location $environmentJson.Location -WebAppName $environmentJson.WebAppName -Sku $environmentJson.Sku -PythonVersion $environmentJson.PythonVersion -RepoUrl $environmentJson.RepoUrl

