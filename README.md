# Apidog Linux Installer

Apidog is an excellent API development platform, but it doesn't treat Linux as a first-class citizen. Unlike macOS and Windows, which have distribution-specific installers, Linux users are left with an AppImage that doesn't integrate well with the system. This means no `apidog` command in your terminal, making it less convenient to use.

This repository aims to solve that problem by providing a set of shell scripts that will:

## Repository

**GitHub Repository:** [git@github.com:crdornelles/apidog-linux-installer.git](https://github.com/crdornelles/apidog-linux-installer)

1. Download and install Apidog for you
2. Provide an `apidog` command that you can run from your shell
3. Allow you to easily update Apidog when new versions are released

## Installation

You can install the Apidog Linux Installer using either curl or wget. Choose the method you prefer:

### Using curl

```bash
# Install Apidog
curl -fsSL https://raw.githubusercontent.com/crdornelles/apidog-linux-installer/main/install.sh | bash
```

### Using wget

```bash
# Install Apidog
wget -qO- https://raw.githubusercontent.com/crdornelles/apidog-linux-installer/main/install.sh | bash
```

The installation script will:

1. Download the `apidog.sh` script and save it as `apidog` in `~/.local/bin/`
2. Make the script executable
3. Download and install the latest version of Apidog

## Uninstalling

To uninstall the Apidog Linux Installer, you can run the uninstall script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/crdornelles/apidog-linux-installer/main/uninstall.sh)"
```

or

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/crdornelles/apidog-linux-installer/main/uninstall.sh)"
```

The uninstall script will:

1. Remove the `apidog` script from `~/.local/bin/`
2. Remove the Apidog AppImage
3. Ask if you want to remove the Apidog configuration files

## Usage

After installation, you can use the `apidog` command to launch Apidog or update it:

- To launch Apidog: `apidog`
- To update Apidog: `apidog --update`
- To check Apidog version: `apidog --version` or `apidog -v`
  - Shows the installed version of Apidog if available
  - Returns an error if Apidog is not installed or version cannot be determined

## Note

If you encounter a warning that `~/.local/bin` is not in your PATH, you can add it by running:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

or add it to your shell profile (e.g., `.bashrc`, `.zshrc`, etc.):

```bash
echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

## Troubleshooting

If you encounter issues with the Apidog AppImage:

1. **GPU Process Error**: If you see "GPU process isn't usable, Goodbye.", the script automatically sets `APIDOG_DISABLE_GPU='true'` to disable GPU acceleration.

2. **FUSE Requirements**: The installer will automatically check and install FUSE2 if needed for AppImage support.

3. **Architecture Mismatch**: The installer verifies that the downloaded AppImage matches your system architecture.

## Acknowledgments

This project was inspired by and based on the excellent work done in the [cursor-linux-installer](https://github.com/watzon/cursor-linux-installer) project. We would like to thank all the contributors and maintainers of that project for creating a solid foundation that made this Apidog installer possible.

Special thanks to:
- The original cursor-linux-installer team for their innovative approach to Linux application installation
- All contributors who helped improve the base installer scripts
- The open-source community for their continuous support and feedback

## License

This software is released under the MIT License.

## Contributing

If you find a bug or have a feature request, please open an issue on GitHub.

If you want to contribute to the project:

1. Fork the repository: [git@github.com:crdornelles/apidog-linux-installer.git](https://github.com/crdornelles/apidog-linux-installer)
2. Clone your fork: `git clone git@github.com:YOUR_USERNAME/apidog-linux-installer.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes and commit them: `git commit -m "Add your feature"`
5. Push to your fork: `git push origin feature/your-feature-name`
6. Submit a pull request

## Development

To set up the development environment:

```bash
git clone git@github.com:crdornelles/apidog-linux-installer.git
cd apidog-linux-installer
```
