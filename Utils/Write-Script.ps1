# Write the script contents to the destination directories if they do not already exist
function Write-Script {
    param (
        [string]$Path,
        [string]$Content
    )
    if (-Not (Test-Path -Path $Path)) {
        Set-Content -Path $Path -Value $Content -Force
    } else {
        Write-Output "$Path already exists. Skipping creation."
    }
}

Export-ModuleMember -Function Write-Script
