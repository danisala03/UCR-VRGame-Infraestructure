function CreatePublicNSG {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$NSGName,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$PublicSubnetName
    )

    # Create NSG.
    $operationResult = az network nsg create --resource-group $RgName --name $NSGName
    if ($operationResult) {
        Write-Host "Public NSG: $NSGName created" -ForegroundColor Green
    } else {
        Write-Error "Error creating NSG: $NSGName"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

    # Allow incoming HTTP and HTTPS traffic.
    Write-Host "Allowing incoming HTTP, HTTPS and SSH traffic..."
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowHTTP --priority 1000 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow --protocol Tcp
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowHTTPS --priority 1100 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 443 --access Allow --protocol Tcp
    #az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowSSH --priority 100 --direction Inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access Allow --protocol Tcp --description "Allow SSH traffic"
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowFrontDoorToAppServices --priority 100 --direction Inbound --source-address-prefixes '*' --destination-port-ranges 80 443 --access Allow --protocol Tcp --description "Allow traffic from Azure Front Door to App Services"
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowAppServicesToInternet --priority 200 --direction Outbound --source-port-ranges '*' --destination-port-ranges '*' --access Allow --protocol Tcp --description "Allow outbound traffic from App Services to the internet"

    # Associate NSG with the subnet.
    $operationResult = az network vnet subnet update -g $RgName --vnet-name $VNetName -n $PublicSubnetName --network-security-group $NSGName
    if ($operationResult) {
        Write-Host "NSG: $NSGName associated with subnet" -ForegroundColor Green
    } else {
        Write-Error "Error associating NSG: $NSGName with subnet"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120
}

function CreatePrivateNSG {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$NSGName,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$PrivateSubnetName
    )

    # Create NSG.
    $operationResult = az network nsg create -g $RgName -n $NSGName
    if ($operationResult) {
        Write-Host "Private NSG: $NSGName created" -ForegroundColor Green
    } else {
        Write-Error "Error creating NSG: $NSGName"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

    # Allow traffic to Key Vault.
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowKeyVault --priority 100 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 443 --access Allow --protocol Tcp
    
    # Allow traffic to Cosmos DB.
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowCosmosDB --priority 110 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 10255 --access Allow --protocol Tcp
    
    # Allow traffic to VMSS.
    az network nsg rule create -g $RgName --nsg-name $NSGName --name AllowVMSSAccess --priority 200 --direction Inbound --source-address-prefixes 10.0.0.0/16 --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*'

    # Associate NSG with the subnet.
    $operationResult = az network vnet subnet update -g $RgName --vnet-name $VNetName --name $PrivateSubnetName --network-security-group $NSGName
    if ($operationResult) {
        Write-Host "NSG: $NSGName associated with subnet" -ForegroundColor Green
    } else {
        Write-Error "Error associating NSG: $NSGName with subnet"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120
}