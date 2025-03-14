# This script is used to deploy the zshrc.d configuration to the user's zshrc file.
function Deploy-Zshrcd {
  param (
      [Parameter(Mandatory=$false)]
      [string]$OutputPath = "~/.zshrc"
  )
  
  $content = @'
# Source all configuration files from ~/.zshrc.d
# This helps keep configurations modular and organized.
# Each configuration should be in a separate file inside ~/.zshrc.d

if [ -d "$HOME/.zshrc.d" ]; then
for rcfile in "$HOME/.zshrc.d"/*; do
  [ -f "$rcfile" ] && source "$rcfile"
done
fi
'@
  
  if ($OutputPath) {
      $content | Out-File -FilePath $OutputPath -Append -Encoding utf8
      Write-Host "Zshrc.d configuration added to $OutputPath" -ForegroundColor Green
  }
  
  return $content
}

Export-ModuleMember -Function Deploy-Zshrcd
