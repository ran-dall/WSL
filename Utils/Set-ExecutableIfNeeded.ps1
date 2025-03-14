# Make the scripts executable if not already executable
function Set-ExecutableIfNeeded {
    param (
        [string[]]$Paths
    )
    foreach ($Path in $Paths) {
        $isExecutable = bash -c "[ -x $Path ] && echo 'yes' || echo 'no'"
        if ($isExecutable -eq "no") {
            bash -c "chmod +x $Path"
            Write-Output "$Path is now executable."
        } else {
            Write-Output "$Path is already executable. Skipping."
        }
    }
}

Export-ModuleMember -Function Set-ExecutableIfNeeded
