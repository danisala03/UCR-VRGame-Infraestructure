function CreateKeyVault {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$KeyVaultName,

        [Parameter(Mandatory=$true)]
        [string]$KeyVaultKey,

        [Parameter(Mandatory=$true)]
        [string]$UserAssignedIdentityName,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$PrivateSubnetName
    )

    # Get VNet details.
    $ua = "/subscriptions/$SubscriptionId/resourcegroups/$RgName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$UserAssignedIdentityName"
    $uaId = $(az identity show --ids $ua --query principalId --output tsv)

    # Creates Key Vault
    $operationResult = az keyvault create -n $KeyVaultName -g $RgName --location $Location --enable-purge-protection true --enable-rbac-authorization false 
    if ($operationResult) {
        Write-Host "Key Vault: $KeyVaultName created." -ForegroundColor Green
    } else {
        Write-Error "Error creating Key Vault: $KeyVaultName."
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

    # Link Key Vault with VNet.
    $keyVaultId=$(az keyvault show --name $KeyVaultName -g $RgName --query id --output tsv)
    az keyvault network-rule add --resource-id $keyVaultId --subnet $PrivateSubnetName --vnet-name $VNetName -n $KeyVaultName

    # Create Key Vault Key.
    az keyvault key create --vault-name $KeyVaultName -n $KeyVaultKey --protection software
    
    # Set Key Vault Key permissions.
    az keyvault set-policy --name $KeyVaultName --object-id $uaId --key-permissions get list wrapKey unwrapKey

    az keyvault network-rule add -g $RgName -n $KeyVaultName --ip-address "191.10.18.0/24"

    az keyvault update -g $RgName -n $KeyVaultName --bypass AzureServices

    az keyvault update -g $RgName -n $KeyVaultName --default-action Deny

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120
}