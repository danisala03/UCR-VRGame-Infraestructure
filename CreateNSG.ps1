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
        [string]$SubnetName
    )

    # Create NSG.
    $operationResult = az network nsg create --resource-group $RgName --name $NSGName
    if ($operationResult) {
        Write-Host "NSG: $NSGName created" -ForegroundColor Green
    } else {
        Write-Error "Error creating NSG: $NSGName"
        exit -1
    }

    # Allow incoming HTTP and HTTPS traffic.
    az network nsg rule create --resource-group $RgName --nsg-name $NSGName --name AllowHTTP --priority 1000 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow --protocol Tcp
    az network nsg rule create --resource-group $RgName --nsg-name $NSGName --name AllowHTTPS --priority 1100 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 443 --access Allow --protocol Tcp

    # Associate NSG with the subnet.
    $operationResult = az network vnet subnet update --resource-group $RgName --vnet-name $VNetName --name $SubnetName --network-security-group $NSGName
    if ($operationResult) {
        Write-Host "NSG: $NSGName associated with subnet" -ForegroundColor Green
    } else {
        Write-Error "Error associating NSG: $NSGName with subnet"
        exit -1
    }
}