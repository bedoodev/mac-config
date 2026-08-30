# mac-config

A starter repository that sets up a development environment on a new or reset Mac with one command.

## Run it

~/Developer/mac-config/install.sh

The script does the following:

- Installs Homebrew if it is missing. It supports the Apple Silicon path: /opt/homebrew.
- Installs apps, terminal tools, fonts, and VS Code extensions from the Brewfile.
- Creates symbolic links instead of copying configuration files.
- Moves an existing configuration file to ~/.mac-config-backups/DATE-TIME before it makes a new link.
- Installs the current Node.js LTS version with NVM and sets it as the default.
- Applies common macOS settings.

You can run the script again at any time. It keeps correct symbolic links and does not update installed Homebrew packages without a reason.

## Installed software

Apps:

- Ghostty
- Visual Studio Code
- TablePlus
- JetBrains Mono Nerd Font

Terminal and development tools:

- Git, Go, pyenv, NVM, and Node.js LTS
- Starship, tmux, zoxide, and fzf
- ripgrep, fd, bat, eza, jq, and yq
- direnv, micro, lazygit, and lazydocker
- kubectl and k9s

It also installs the Go, Python, Pylance, and Ruff extensions for VS Code.

Note: lazydocker needs a running Docker engine. This starter does not install Docker Desktop automatically.

## Git identity

Your name and email are not stored in this repository. After installation, add them to your local file:

    git config --file ~/.gitconfig.local user.name "Your Name"
    git config --file ~/.gitconfig.local user.email "you@example.com"

If you use different work and personal identities, you can use Git conditional includes instead of one ~/.gitconfig.local file.

## Skip Node.js installation

To install NVM but skip the Node.js LTS download, run:

    SKIP_NODE=1 ~/Developer/mac-config/install.sh

## Change settings

Edit the matching file in this folder. Because the setup uses symbolic links, the change is active right away:

- zsh/.zshrc: shell settings, aliases, and tool integrations
- ghostty/config: Ghostty dark theme, font, and shortcuts
- starship/starship.toml: directory, Git, Go, and Python virtual environment prompt
- vscode/settings.json: editor, auto-save, Go, and Python settings
- git/.gitconfig.example: shared Git defaults without personal data
- macos/defaults.sh: macOS settings
- Brewfile: installed packages and apps

Run install.sh again after adding a new package or when you want to recreate the links.

## Security

This repository has no tokens, passwords, SSH keys, or personal email addresses. Git ignores .env, *.local, *.secret, and secrets/. If Homebrew is missing, the script uses only the official Homebrew installation address.
