
function CreateVNet {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$SubnetName
    )

    # Creates the VNet.
    $operationResult = az network vnet create --name $VNetName --resource-group $RgName --address-prefix 10.0.0.0/16 --subnet-name $SubnetName --subnet-prefixes 10.0.0.0/24
    if ($operationResult) {
        Write-Host "Virtual Network: $VNetName created"
    } else {
        Write-Error "Error creating Virtual Network: $VNetName"
        exit -1
    }

    # # Creates Azure Bastion for the subnet.
    # $operationResult = az network vnet subnet create --name AzureBastionSubnet --resource-group $RgName --vnet-name $VNetName --address-prefix 10.0.1.0/26
    # if ($operationResult) {
    #     Write-Host "Subnet: AzureBastionSubnet created"
    # } else {
    #     Write-Error "Error creating Subnet: AzureBastionSubnet"
    #     exit -1
    # }
    
    # # Creates Public IP for Azure Bastion.
    # $operationResult = az network public-ip create --resource-group $RgName --name public-ip --sku Standard --location $Location --zone 1 2 3
    # if ($operationResult) {
    #     Write-Host "Public IP: public-ip created"
    # } else {
    #     Write-Error "Error creating Public IP: public-ip"
    #     exit -1
    # }

    # # Creates Azure Bastion.
    # $operationResult = az network bastion create --name bastion --public-ip-address public-ip --resource-group $RgName --vnet-name $VNetName --location $Location
    # if ($operationResult) {
    #     Write-Host "Azure Bastion: bastion created"
    # } else {
    #     Write-Error "Error creating Azure Bastion: bastion"
    #     exit -1
    # }

}