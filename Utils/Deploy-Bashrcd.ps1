# This script is used to deploy the bashrc.d configuration to the user's bashrc file.

function Deploy-Bashrcd {
    param (
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "~/.bashrc"
    )
    
    $content = @'
# Source all configuration files from ~/.bashrc.d
# This helps keep configurations modular and organized.
# Each configuration should be in a separate file inside ~/.bashrc.d

if [ -d "$HOME/.bashrc.d" ]; then
  for rcfile in "$HOME/.bashrc.d"/*; do
    [ -f "$rcfile" ] && source "$rcfile"
  done
fi
'@
    
    if ($OutputPath) {
        $content | Out-File -FilePath $OutputPath -Append -Encoding utf8
        Write-Host "Bashrc.d configuration added to $OutputPath" -ForegroundColor Green
    }
    
    return $content
}

Export-ModuleMember -Function Deploy-Bashrcd
