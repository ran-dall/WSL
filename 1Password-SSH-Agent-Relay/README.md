# 🛡️1Password SSH Agent Relay 🔄

This script automates the process of setting up an SSH agent relay for use with 1Password in a Windows Subsystem for Linux (WSL) environment. It uses `npiperelay` and `socat` to forward the SSH agent from Windows to WSL, allowing you to leverage 1Password's SSH agent capabilities within your WSL environment.

**_This is only needed for certain cases in which more SSH compatibility is needed (e.g., devcontainers)._**

The script:

1. Sets up necessary scripts to automate SSH agent forwarding.
2. Creates a `systemd` service to manage the SSH agent relay.
3. Adds configuration to `.bashrc` for modular configuration loading.
4. Configures SSH to use the 1Password agent by default.
5. Ensures necessary dependencies (`npiperelay` and `socat`) are installed.
6. Sets up environment variables for SSH agent forwarding.

## 📝 Usage

1. **Install Dependencies**: Ensure `npiperelay` and `socat` are installed. The script will attempt to install `socat` if it is not present.

2. **Set Up Directories**: The script will create necessary directories, such as `$HOME/.local/bin` and `$HOME/.config/systemd/user`, if they do not already exist.

3. **Create and Install Scripts**: The script will generate and install the required scripts for SSH agent forwarding in `$HOME/.local/bin`.

4. **Bash Configuration**: The script will modify your `.bashrc` to source configuration files from the `~/.bashrc.d` directory for easier configuration management.

5. **Enable and Start the Service**: The script will use `systemd` to automatically start the SSH agent relay service.

6. **SSH Configuration**: A default SSH configuration file will be created to use the 1Password SSH agent for all hosts.

## 🧑‍💻 Customization

- **Paths**: The default service file and scripts are written to `$HOME/.local/bin` and `$HOME/.config/systemd/user`.
- **Service Management**: Use `systemctl --user enable ssh-agent-relay.service` and `systemctl --user start ssh-agent-relay.service` to manage the service.
- **SSH Config**: Modify the generated SSH configuration file if you need to futher customize the 1Password SSH socket relay.

## ❓ Troubleshooting

- **npiperelay Not Found**: Ensure the `$npiperelayPath` is correct and that `npiperelay` is symlinked correctly.
- **socat Installation Issues**: Make sure your WSL distribution has a supported package manager (`apt`, `dnf`, etc.). You can also install `socat` manually if needed.
- **Systemd Service Not Starting**: Verify that `systemd` is available in your WSL distribution, and check the service logs for errors using:
  ```sh
  journalctl --user -u ssh-agent-relay.service
  ```

## 📄 License

This script is provided "as is," without warranty of any kind. Use it at your own risk.

## 😊 Acknowledgements

- **npiperelay**: Thanks to [@albertony](https://github.com/albertony) for maintaining a more up-to-date fork of `npiperelay`, originally authored by [@jstacks](https://github.com/jstacks).
