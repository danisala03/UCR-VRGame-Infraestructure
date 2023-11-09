function CreateResourceGroup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,
        [Parameter(Mandatory=$true)]
        [string]$Location
    )

    # Creates Resource Group
    #az group create --name $RgName --location $Location
    Write-Host "Resource Group: $RgName created in $Location"
}