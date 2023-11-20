
function CreateAppService {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$WebAppName,

        [Parameter(Mandatory=$true)]
        [string]$Sku,
        
        [Parameter(Mandatory=$true)]
        [string]$PythonVersion,
        
        [Parameter(Mandatory=$true)]
        [string]$RepoUrl,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$SubnetName
    )

    # Variables set to read the ARM Template.
    $jsonFileLocation = "$PSScriptRoot\Templates\AppService.json"

    # Creates the App Service.
    $operationResult = az deployment group create --resource-group $RgName --parameters webAppName=$WebAppName repoUrl=$RepoUrl sku=$Sku repoUrl=$RepoUrl location=$Location --template-file $jsonFileLocation
    if ($operationResult) {
        Write-Host "App Service: $WebAppName created" -ForegroundColor Green
    } else {
        Write-Error "Error creating App Service: $WebAppName"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

    # Relates the Vnet to the App Service.
    $operationResult = az webapp vnet-integration add --resource-group $RgName --name $WebAppName --vnet $VNetName --subnet $SubnetName
    if ($operationResult) {
        Write-Host "VNet: $VNetName related to App Service: $WebAppName" -ForegroundColor Green
    } else {
        Write-Error "Error relating VNet: $VNetName to App Service: $WebAppName"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

}