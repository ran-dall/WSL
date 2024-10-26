# Define the content of the scripts
function Get-SshRelayScriptContent {
    return @'
if [ -f "$HOME/.ssh/agent.env" ]; then
  source "$HOME/.ssh/agent.env"
  export SSH_AUTH_SOCK
fi
'@
}

function Get-AgentRelayScriptContent {
    return @'
#!/bin/bash

# Set the socket location for SSH agent forwarding
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# Create the necessary directory if it doesn't exist
mkdir -p "$(dirname "$SSH_AUTH_SOCK")"

# Write the SSH_AUTH_SOCK value to a file
echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$HOME/.ssh/agent.env"

# Define the piperelay command as an array
piperelay=(socat "UNIX-LISTEN:${SSH_AUTH_SOCK},fork" "EXEC:npiperelay -ei -s //./pipe/openssh-ssh-agent,nofork")

# Check if the SSH agent forwarding process is already running
if ! pgrep --full --exact --uid="${UID}" "${piperelay[*]}" >/dev/null; then
  # Remove existing socket if it exists
  rm -f "$SSH_AUTH_SOCK"

  echo "Starting SSH-Agent relay..."
  # Start the SSH-Agent relay directly without setsid (let systemd manage the background process)
  "${piperelay[@]}"
else
  echo "SSH-Agent relay is already running."
fi
'@
}

function Get-ServiceFileContent {
    return @'
[Unit]
Description=1Password SSH Agent Relay
After=network.target

[Service]
ExecStart=%h/.local/bin/1p-ssh-agent-relay.sh
Restart=on-failure
RestartSec=10
TimeoutStartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
'@
}

function Get-BashrcSnippet {
    return @'
# Source all configuration files from ~/.bashrc.d
# This helps keep configurations modular and organized.
# Each configuration should be in a separate file inside ~/.bashrc.d

if [ -d "$HOME/.bashrc.d" ]; then
  for rcfile in "$HOME/.bashrc.d"/*; do
    [ -f "$rcfile" ] && source "$rcfile"
  done
fi
'@
}

# New function to generate SSH config content
function Get-SshConfigContent {
    return @'
# Default configuration for hosts to use 1Password agent
Host *
    IdentityAgent $SSH_AUTH_SOCK

'@
}

# Define the destination directories on the local Linux system
$currentUser = (whoami).Trim()
$localScriptDir = "/home/$currentUser/.local/bin"
$localServiceDir = "/home/$currentUser/.config/systemd/user"
$bashrcPath = "/home/$currentUser/.bashrc"

# Create the necessary directories if they do not already exist
function New-ItemIfNeeded {
    param (
        [string]$Path
    )
    if (-Not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path
    }
}

New-ItemIfNeeded -Path $localScriptDir
New-ItemIfNeeded -Path $localServiceDir

# Ensure npiperelay is present and symlinked correctly
$windowsUsername = bash -c 'ls /mnt/c/Users | grep -Ev "Public|Default|All Users|Default User" | while read user; do if [ -d "/mnt/c/Users/$user/Desktop" ]; then echo $user; break; fi; done'
$windowsUsername = $windowsUsername.Trim()
$npiperelayPath = "/mnt/c/Users/$windowsUsername/AppData/Local/Microsoft/WinGet/Links/npiperelay.exe"
$symlinkPath = "/usr/local/bin/npiperelay"

function Set-Npiperelay {
    param (
        [string]$SourcePath,
        [string]$SymlinkPath
    )
    if (-Not (Test-Path -Path $SymlinkPath)) {
        if (-Not (Test-Path -Path $SourcePath)) {
            Write-Warning "npiperelay.exe not found at $SourcePath. Please ensure it is installed."
            Write-Output "You can install npiperelay using the following command on your Windows host:"
            Write-Output "winget install albertony.npiperelay"
            exit 1
        }
        bash -c "sudo ln -s $SourcePath $SymlinkPath"
        Write-Output "Created symbolic link for npiperelay."
    } else {
        Write-Output "Symbolic link for npiperelay already exists. Skipping."
    }
}

Set-Npiperelay -SourcePath $npiperelayPath -SymlinkPath $symlinkPath

# Ensure socat is installed
function Install-SocatIfNeeded {
    if (-Not (bash -c "command -v socat")) {
        Write-Output "socat is not installed. Installing socat..."
        if (bash -c "command -v apt") {
            bash -c "sudo apt update && sudo apt install -y socat"
        } elseif (bash -c "command -v apt-get") {
            bash -c "sudo apt-get update && sudo apt-get install -y socat"
        } elseif (bash -c "command -v dnf") {
            bash -c "sudo dnf install -y socat"
        } elseif (bash -c "command -v yum") {
            bash -c "sudo yum install -y socat"
        } else {
            Write-Error "No supported package manager found. Please install socat manually."
            exit 1
        }
    }
}

Install-SocatIfNeeded

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

Write-Script -Path "$localScriptDir/ssh-relay.sh" -Content (Get-SshRelayScriptContent)
Write-Script -Path "$localScriptDir/1p-ssh-agent-relay.sh" -Content (Get-AgentRelayScriptContent)
Write-Script -Path "$localServiceDir/ssh-agent-relay.service" -Content (Get-ServiceFileContent)

# Ensure .bashrc contains the snippet to load rcfiles
function Update-BashrcConfig {
    param (
        [string]$BashrcPath,
        [string]$Snippet
    )
    if (-Not (Select-String -Path $BashrcPath -Pattern "# Source all configuration files from ~/.bashrc.d" -Quiet)) {
        Add-Content -Path $BashrcPath -Value $Snippet
        Write-Output "Added bashrc.d sourcing snippet to $BashrcPath."
    } else {
        Write-Output "$BashrcPath already contains the bashrc.d sourcing snippet. Skipping."
    }
}

Update-BashrcConfig -BashrcPath $bashrcPath -Snippet (Get-BashrcSnippet)

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

Set-ExecutableIfNeeded -Paths @("$localScriptDir/ssh-relay.sh", "$localScriptDir/1p-ssh-agent-relay.sh")

# Reload systemd daemon and enable the service only if not already enabled
function Enable-SystemdServiceIfNeeded {
    if (-Not (bash -c "systemctl --user is-enabled ssh-agent-relay.service")) {
        Write-Output "Enabling and starting the ssh-agent-relay.service..."
        bash -c "systemctl --user daemon-reload && systemctl --user enable ssh-agent-relay.service && systemctl --user start ssh-agent-relay.service"
    } else {
        Write-Output "ssh-agent-relay.service is already enabled. Skipping."
    }
}

Enable-SystemdServiceIfNeeded
# Ensure SSH config has the required setting
function EnsureSshConfig {
    param (
        [string]$SshConfigPath,
        [string]$SshConfigContent
    )
    
    # Create the ~/.ssh directory if it doesn't exist
    if (-Not (Test-Path -Path $(dirname $SshConfigPath))) {
        New-Item -ItemType Directory -Force -Path $(dirname $SshConfigPath)
    }

    # Create the ~/.ssh/config file if it doesn't exist
    if (-Not (Test-Path -Path $SshConfigPath)) {
        Set-Content -Path $SshConfigPath -Value $SshConfigContent -Force
        Write-Output "$SshConfigPath created with default configuration."
    }
    else {
        # Read the content of the existing SSH config file
        $existingConfig = Get-Content -Path $SshConfigPath -Raw

        # Normalize the content to avoid differences in formatting
        $existingConfigNormalized = $existingConfig -replace '\s+', ' ' -replace '\n', ' ' -replace '\r', ' '
        $sshConfigContentNormalized = $SshConfigContent -replace '\s+', ' ' -replace '\n', ' ' -replace '\r', ' '

        # Check if the IdentityAgent configuration already exists
        if (-Not ($existingConfigNormalized -like "*$sshConfigContentNormalized*")) {
            Add-Content -Path $SshConfigPath -Value $SshConfigContent
            Write-Output "Added IdentityAgent configuration to $SshConfigPath."
        }
        else {
            Write-Output "$SshConfigPath already contains the IdentityAgent configuration. Skipping."
        }
    }
}

# Get the SSH configuration content from the function
$sshConfigPath = "/home/$currentUser/.ssh/config"
$sshConfigContent = Get-SshConfigContent

EnsureSshConfig -SshConfigPath $sshConfigPath -SshConfigContent $sshConfigContent
