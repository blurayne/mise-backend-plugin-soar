# mise-backend-plugin-soar

A [mise](https://mise.jdx.dev) backend plugin for [soar](https://soar.qaidvoid.dev/) — the fast, distro-independent package manager for Linux static binaries and AppImages.

## What it does

This plugin lets you install and manage packages from the [soarpkgs](https://github.com/pkgforge/soarpkgs) registry via mise, using the familiar `plugin:tool@version` syntax:

```bash
mise use soar:jq@latest
mise use soar:ripgrep@latest
mise use soar:neovim@latest
```

## Requirements

- **Linux only** — soar is a Linux-specific tool
- **soar must be installed** on your system

### Installing soar

```bash
# Via mise (recommended)
mise use -g github:pkgforge/soar

# Or via the official install script
curl -fsSL "https://raw.githubusercontent.com/pkgforge/soar/main/install.sh" | sh
```

## Installation

### From GitHub

```bash
mise plugin install soar https://github.com/blurayne/mise-backend-plugin-soar
```

### Local development

```bash
git clone https://github.com/blurayne/mise-backend-plugin-soar
cd mise-backend-plugin-soar
mise plugin link --force soar .
```

## Usage

```bash
# List available versions of a package
mise ls-remote soar:jq

# Install a package at a specific version
mise install soar:jq@1.7.1

# Install the latest version
mise install soar:jq@latest

# Use a package in the current project
mise use soar:ripgrep@latest

# Run a tool without installing it globally
mise exec soar:jq@latest -- jq --version
```

## How it works

| Hook | Behaviour |
|------|-----------|
| `BackendListVersions` | Runs `soar --json query <tool>` and extracts version info from the JSON response. |
| `BackendInstall` | Runs `soar install --yes --binary-only <tool>@<version>` with `SOAR_BIN` set to the mise install directory, so the binary lands at `<install_path>/bin/`. |
| `BackendExecEnv` | Prepends `<install_path>/bin` to `PATH`. |

### Version pinning

soar's registry tracks one version per package (usually latest stable). Where the registry supports `@version` specifiers the version is passed through; otherwise soar installs whatever it knows about. Use `mise ls-remote soar:<tool>` to see what is available.

### Binary placement

Binaries are installed with `--binary-only`, which excludes desktop integration files, logs, and build artefacts. Each mise-managed version gets its own isolated directory under `~/.local/share/mise/installs/soar/<tool>/`.

## Development

```bash
# Install dev tools
mise install

# Format
mise run format

# Lint
mise run lint

# Run full test suite (requires soar to be installed)
mise run test

# All CI checks
mise run ci
```

## Documentation

- [soar documentation](https://soar.qaidvoid.dev/)
- [soarpkgs registry](https://github.com/pkgforge/soarpkgs)
- [mise backend plugin development guide](https://mise.jdx.dev/backend-plugin-development.html)

## License

MIT
