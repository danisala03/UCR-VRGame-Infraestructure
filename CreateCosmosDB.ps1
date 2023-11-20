function CreateCosmosDBAccount {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$CosmosDBAccountName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$SecondaryLocation,

        [Parameter(Mandatory=$true)]
        [string]$UserAssignedIdentityName,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$KeyVaultName,

        [Parameter(Mandatory=$true)]
        [string]$KeyVaultKey,

        [Parameter(Mandatory=$true)]
        [string]$PrivateSubnetName
    )

    # Get VNet details.
    $svcEndpoint = $(az network vnet subnet show -g $RgName --vnet-name $VNetName -n $PrivateSubnetName --query 'id' -o tsv)
    $ua = "/subscriptions/$SubscriptionId/resourcegroups/$RgName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$UserAssignedIdentityName"
    $keyUri = "https://$KeyVaultName.vault.azure.net/keys/$KeyVaultKey"

    # Creates Cosmos DB Account
    $operationResult = az cosmosdb create -n $CosmosDBAccountName -g $RgName --assign-identity $ua --default-identity "UserAssignedIdentity=$ua" --key-uri $keyUri --enable-virtual-network true --virtual-network-rules $svcEndpoint --enable-multiple-write-locations true --locations regionName=$Location failoverPriority=0 isZoneRedundant=false --locations regionName=$SecondaryLocation failoverPriority=1 isZoneRedundant=false --enable-multiple-write-locations true  
    if ($operationResult) {
        Write-Host "Cosmos DB Account: $CosmosDBAccountName created." -ForegroundColor Green
    } else {
        Write-Error "Error creating Cosmos DB Account: $CosmosDBAccountName."
        exit -1
    }    

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120
}