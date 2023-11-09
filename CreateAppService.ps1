
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
        [string]$RepoUrl
    )

    # Variables set to read the ARM Template.
    $jsonFileLocation = "$PSScriptRoot\Templates\AppService.json"

    # Creates the App Service.
    $operationResult = az deployment group create --resource-group $RgName --parameters webAppName=$WebAppName sku=$Sku repoUrl=$RepoUrl linuxFxVersion=$PythonVersion location=$Location --template-file $jsonFileLocation
    
    if ($operationResult) {
        Write-Host "App Service: $WebAppName created"
    } else {
        Write-Error "Error creating App Service: $WebAppName"
        exit -1
    }
}