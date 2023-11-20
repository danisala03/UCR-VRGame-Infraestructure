function CreateUAIdentity {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RgName,

        [Parameter(Mandatory=$true)]
        [string]$Location,

        [Parameter(Mandatory=$true)]
        [string]$UserAssignedIdentityName 
    )

    # Creates User Assigned Managed Identity.
    $operationResult = az identity create -g $RgName -n $UserAssignedIdentityName
    if ($operationResult) {
        Write-Host "User Assigned Managed Identity: $UserAssignedIdentityName created." -ForegroundColor Green
    } else {
        Write-Error "Error creating User Assigned Managed Identity: $UserAssignedIdentityName."
        exit -1
    }
    
    # Wait for 2 minutes the changes
    Write-Host "Waiting for 2 minutes to apply changes..."
    Start-Sleep -s 120
}