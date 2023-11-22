
function CreateVMSS {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$VMSSName,

        [Parameter(Mandatory=$true)]
        [string]$VNetName,

        [Parameter(Mandatory=$true)]
        [string]$VMSSSubnetName,

        [Parameter(Mandatory=$true)]
        [string]$NSGPublicName,

        [Parameter(Mandatory=$true)]
        [string]$UserAssignedIdentityName
    )

    # Creates the VMSS.
    $ua = "/subscriptions/$SubscriptionId/resourcegroups/$RgName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$UserAssignedIdentityName"
    $LoadBalancerName = "testLB"
    $DnsName = "my-dns-test"
    $operationResult = az vmss create --name $VMSSName --location $Location -g $RgName --public-ip-address-dns-name $DnsName --load-balancer $LoadBalancerName --vnet-name $VNetName --subnet $VMSSSubnetName --image Ubuntu2204 --generate-ssh-keys --nsg $NSGPublicName --assign-identity $ua --public-ip-per-vm
    if ($operationResult) {
        Write-Host "VSMS: $VMSSName created" -ForegroundColor Green
    } else {
        Write-Error "Error creating VSMS: $VMSSName"
        exit -1
    }

    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120

    Write-Host "Installing Nginx to allow SSH connections ..."
    $scriptSettings = @{
        script = "#!/bin/bash`nsudo apt-get -y update`nsudo apt-get -y install nginx"
    } | ConvertTo-Json
    
    az vmss extension set --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript --vmss-name $VMSSName -g $RgName --settings $scriptSettings

}