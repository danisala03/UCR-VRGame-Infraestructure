
function CreateVNet {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$PublicSubnetName1,

        [Parameter(Mandatory=$true)]
        [string]$PublicSubnetName2,

        [Parameter(Mandatory=$true)]
        [string]$PrivateSubnetName1,

        [Parameter(Mandatory=$true)]
        [string]$PrivateSubnetName2,

        [Parameter(Mandatory=$true)]
        [string]$VMSSSubnetName
    )

    # Creates the VNet.
    $operationResult = az network vnet create -n $VNetName -g $RgName --address-prefix 10.0.0.0/16 --subnet-name $PublicSubnetName1 --subnet-prefix 10.0.0.0/24
    if ($operationResult) {
        Write-Host "Virtual Network: $VNetName created with Public Subnet: $PublicSubnetName1" -ForegroundColor Green
    } else {
        Write-Error "Error creating Virtual Network: $VNetName and Public Subnet: $PublicSubnetName1"
        exit -1
    }
    
    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

    # Creates Subnet for Private Access.
    $operationResult = az network vnet subnet create -g $RgName --vnet-name $VNetName -n $PublicSubnetName2 --address-prefix 10.0.1.0/24
    if ($operationResult) {
        Write-Host "Private Subnet: $PublicSubnetName2 created" -ForegroundColor Green
    } else {
        Write-Error "Error creating Subnet: $PublicSubnetName2"
        exit -1
    }

    # Creates Subnet for Private Access.
    $operationResult = az network vnet subnet create -g $RgName --vnet-name $VNetName -n $PrivateSubnetName1 --address-prefix 10.0.2.0/24
    if ($operationResult) {
        Write-Host "Private Subnet: $PrivateSubnetName1 created" -ForegroundColor Green
    } else {
        Write-Error "Error creating Subnet: $PrivateSubnetName1"
        exit -1
    }

            # Creates Subnet for Private Access.
    $operationResult = az network vnet subnet create -g $RgName --vnet-name $VNetName -n $PrivateSubnetName2 --address-prefix 10.0.3.0/24
    if ($operationResult) {
        Write-Host "Private Subnet: $PrivateSubnetName2 created" -ForegroundColor Green
    } else {
        Write-Error "Error creating Subnet: $PrivateSubnetName2"
        exit -1
    }

    # Creates Subnet for VSMSS Access.
    $operationResult = az network vnet subnet create -g $RgName --vnet-name $VNetName -n $VMSSSubnetName --address-prefix 10.0.4.0/24
    if ($operationResult) {
        Write-Host "VMSS Subnet: $VMSSSubnetName created" -ForegroundColor Green
    } else {
        Write-Error "Error creating Subnet: $VMSSSubnetName"
        exit -1
    }

    # Wait for 1 minute the changes
    Write-Host "Waiting for 1 minute to apply changes..."
    Start-Sleep -s 60

    Write-Host "Registering Service Endpoints..."
    # Registers Key Vault Service.
    az network vnet subnet update -n $VMSSSubnetName -g $RgName --vnet-name $VNetName --service-endpoints "Microsoft.KeyVault" "Microsoft.AzureCosmosDB"
    Write-Host "Service Endpoints registered." -ForegroundColor Green

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120
    
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