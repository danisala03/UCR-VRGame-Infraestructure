
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
        [string]$PublicSubnetName,
        
        [Parameter(Mandatory=$true)]
        [string]$PrivateSubnetName
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
    $operationResult = az webapp vnet-integration add --resource-group $RgName --name $WebAppName --vnet $VNetName --subnet $PublicSubnetName
    if ($operationResult) {
        Write-Host "VNet: $VNetName related to App Service: $WebAppName" -ForegroundColor Green
    } else {
        Write-Error "Error relating VNet: $VNetName to App Service: $WebAppName"
        exit -1
    }

    # $operationResult = az webapp vnet-integration add --resource-group $RgName --name $WebAppName --vnet $VNetName --subnet $PrivateSubnetName
    # if ($operationResult) {
    #     Write-Host "VNet: $VNetName related to App Service: $WebAppName" -ForegroundColor Green
    # } else {
    #     Write-Error "Error relating VNet: $VNetName to App Service: $WebAppName"
    #     exit -1
    # }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

}

function CreateAzureFrontDoor {
    param(

        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$AzFrontDoorProfileNameFrontEnd,

        [Parameter(Mandatory=$true)]
        [string]$AzFrontDoorProfileUcrForGameApp,

        [Parameter(Mandatory=$true)]
        [string]$OriginGroupNameFrontEnd,

        [Parameter(Mandatory=$true)]
        [string]$OriginGroupNameForGameApp,

        [Parameter(Mandatory=$true)]
        [string]$WebAppNameWestUS,

        [Parameter(Mandatory=$true)]
        [string]$WebAppNameEastUS,

        [Parameter(Mandatory=$true)]
        [string]$WebAppNameForGameWestUS,

        [Parameter(Mandatory=$true)]
        [string]$WebAppNameForGameEastUS
    )
    
    $sku = "Premium_AzureFrontDoor"
    # Creates the Azure Front Door for front end.
    az afd profile create --profile-name $AzFrontDoorProfileNameFrontEnd -g $RgName --sku $sku

    # Creates the Azure Front Door for game app.
    az afd profile create --profile-name $AzFrontDoorProfileUcrForGameApp -g $RgName --sku $sku

    Write-Host "Getting Endpoints"

    $EndpointNameFrontEnd = "endpoint-front-end"
    az afd endpoint create --endpoint-name $EndpointNameFrontEnd --profile-name $AzFrontDoorProfileNameFrontEnd -g $RgName --enabled-state Enabled
    
    $EndpointNameGameApp = "endpoint-game-app"
    az afd endpoint create --endpoint-name $EndpointNameGameApp --profile-name $AzFrontDoorProfileUcrForGameApp -g $RgName --enabled-state Enabled

    # Create origin group to both apps
    Write-Host "Creating origin group to both apps"
    az afd origin-group create -g $RgName --origin-group-name $OriginGroupNameFrontEnd --profile-name $AzFrontDoorProfileNameFrontEnd --probe-request-type GET --probe-protocol Http --probe-interval-in-seconds 60 --probe-path / --sample-size 4 --successful-samples-required 3 --additional-latency-in-milliseconds 50
    az afd origin-group create -g $RgName --origin-group-name $OriginGroupNameForGameApp --profile-name $AzFrontDoorProfileUcrForGameApp --probe-request-type GET --probe-protocol Http --probe-interval-in-seconds 60 --probe-path / --sample-size 4 --successful-samples-required 3 --additional-latency-in-milliseconds 50

    # Set orders of which are primary and secondary origins.
    Write-Host "Setting orders of which are primary and secondary origins"
    $host1FrontEnd = az webapp show --name $WebAppNameWestUS -g $RgName --query "hostNames[0]"
    $host2FrontEnd = az webapp show --name $WebAppNameEastUS -g $RgName --query "hostNames[0]"
    $host1GameApp = az webapp show --name $WebAppNameForGameWestUS -g $RgName --query "hostNames[0]"
    $host2GameApp = az webapp show --name $WebAppNameForGameEastUS -g $RgName --query "hostNames[0]"

    # First, create the origins for the front end app.
    Write-Host "Creating the origins for the front end app"
    $FrontEndPrimaryApp = "FrontEndPrimaryApp"
    az afd origin create -g $RgName --host-name $host1FrontEnd --profile-name $AzFrontDoorProfileNameFrontEnd --origin-group-name $OriginGroupNameFrontEnd --origin-name $FrontEndPrimaryApp --origin-host-header $host1FrontEnd --priority 1 --weight 1000 --enabled-state Enabled --http-port 80 --https-port 443
    $FrontEndSecondaryApp = "FrontEndSecondaryApp"
    az afd origin create -g $RgName --host-name $host2FrontEnd --profile-name $AzFrontDoorProfileNameFrontEnd --origin-group-name $OriginGroupNameFrontEnd --origin-name $FrontEndSecondaryApp --origin-host-header $host2FrontEnd --priority 2 --weight 1000 --enabled-state Enabled --http-port 80 --https-port 443

    # Second, create the origins for the game app.
    Write-Host "Creating the origins for the game app"
    $GameAppPrimaryApp = "GameAppPrimaryApp"
    az afd origin create -g $RgName --host-name $host1GameApp --profile-name $AzFrontDoorProfileUcrForGameApp --origin-group-name $OriginGroupNameForGameApp --origin-name $GameAppPrimaryApp --origin-host-header $host1GameApp --priority 1 --weight 1000 --enabled-state Enabled --http-port 80 --https-port 443
    $GameAppSecondaryApp = "GameAppSecondaryApp"
    az afd origin create -g $RgName --host-name $host2GameApp --profile-name $AzFrontDoorProfileUcrForGameApp --origin-group-name $OriginGroupNameForGameApp --origin-name $GameAppSecondaryApp --origin-host-header $host2GameApp --priority 2 --weight 1000 --enabled-state Enabled --http-port 80 --https-port 443

    # Create routing rules for front end app.
    Write-Host "Creating routing rules for front end app"
    $routeFrontEnd = "RoutingRuleFrontEnd"
    az afd route create -g $RgName --profile-name $AzFrontDoorProfileNameFrontEnd --endpoint-name $EndpointNameFrontEnd --forwarding-protocol MatchRequest --route-name $routeFrontEnd --https-redirect Enabled --origin-group $OriginGroupNameFrontEnd --supported-protocols Http Https --link-to-default-domain Enabled

    # Create routing rules for game app.
    Write-Host "Creating routing rules for game app"
    $routeGameApp = "RoutingRuleGameApp"
    az afd route create -g $RgName --profile-name $AzFrontDoorProfileUcrForGameApp --endpoint-name $EndpointNameGameApp --forwarding-protocol MatchRequest --route-name $routeGameApp --https-redirect Enabled --origin-group $OriginGroupNameForGameApp --supported-protocols Http Https --link-to-default-domain Enabled

    # Restic access to web apps. We can only access by using Azure Front Door.
    Write-Host "Restricting access to web apps. We can only access by using Azure Front Door."
    $frontEndId = az afd profile show -g $RgName --profile-name $AzFrontDoorProfileNameFrontEnd --query "frontDoorId"
    $gameAppId = az afd profile show -g $RgName --profile-name $AzFrontDoorProfileUcrForGameApp --query "frontDoorId"

    # Front End App.
    Write-Host "Front End App."
    az webapp config access-restriction add -g $RgName -n $WebAppNameWestUS --priority 100 --service-tag AzureFrontDoor.Backend --http-header x-azure-fdid=$frontEndId
    az webapp config access-restriction add -g $RgName -n $WebAppNameEastUS --priority 100 --service-tag AzureFrontDoor.Backend --http-header x-azure-fdid=$frontEndId

    # Game App.
    Write-Host "Game App."
    az webapp config access-restriction add -g $RgName -n $WebAppNameForGameWestUS --priority 100 --service-tag AzureFrontDoor.Backend --http-header x-azure-fdid=$gameAppId
    az webapp config access-restriction add -g $RgName -n $WebAppNameForGameEastUS --priority 100 --service-tag AzureFrontDoor.Backend --http-header x-azure-fdid=$gameAppId





}