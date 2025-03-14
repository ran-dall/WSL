# Create the necessary directories if they do not already exist
function New-ItemIfNeeded {
    param (
        [string]$Path
    )
    if (-Not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path
    }
}

Export-ModuleMember -Function New-ItemIfNeeded
