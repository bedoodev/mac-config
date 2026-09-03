# mac-config

A starter repository that sets up a development environment on a new or reset Mac with one command.

## Run it

The script does the following:

- Installs Homebrew if it is missing. It supports the Apple Silicon path: /opt/homebrew.
- Installs apps, terminal tools, fonts, and VS Code extensions from the Brewfile. Packages that are already installed are skipped.
- Creates symbolic links instead of copying configuration files.
- Moves an existing configuration file to ~/.mac-config-backups/DATE-TIME before it makes a new link.
- Installs the current Node.js LTS version with NVM only when Node.js is missing.
- Applies common macOS settings.
- Installs the pinned LazyVim plugins after linking the Neovim configuration.

You can run the script again at any time. It keeps correct symbolic links and does not update installed Homebrew packages without a reason.

```
git clone https://github.com/bedoodev/mac-config.git
cd mac-config
./install.sh
```

## Installed software

Apps:

- Ghostty
- Visual Studio Code
- TablePlus
- JetBrains Mono Nerd Font

Terminal and development tools:

- Git, Neovim, Go, pyenv, NVM, and Node.js LTS
- Starship, tmux, zoxide, and fzf
- ripgrep, fd, bat, eza, jq, and yq
- direnv, micro, lazygit, and lazydocker
- kubectl and k9s

It also installs the Go, Python, Pylance, and Ruff extensions for VS Code.

Note: lazydocker needs a running Docker engine. This starter does not install Docker Desktop automatically.

## Skip Node.js installation

To install NVM but skip the Node.js LTS download, run:

    SKIP_NODE=1 ~/Developer/mac-config/install.sh

## Change settings

Edit the matching file in this folder. Because the setup uses symbolic links, the change is active right away:

- zsh/.zshrc: shell settings, aliases, and tool integrations
- ghostty/config: Ghostty theme, font, clipboard, and editor-style shortcuts. It is linked to both supported macOS config locations.
- nvim/: full Neovim (LazyVim) configuration linked to ~/.config/nvim
- starship/starship.toml: directory, Git, Go, and Python virtual environment prompt
- vscode/settings.json: editor, auto-save, Go, and Python settings
- git/.gitconfig.example: shared Git defaults without personal data
- macos/defaults.sh: macOS settings
- Brewfile: installed packages and apps

Run install.sh again after adding a new package or when you want to recreate the links.

## Keyboard behavior

Ghostty, zsh, and Neovim share editor-style shortcuts:

- Shift + Arrow selects text character by character or across lines.
- Shift + Option + Left/Right selects text word by word.
- Cmd + Left/Right moves to the beginning/end of a line.
- Cmd + Up/Down moves to the beginning/end of a buffer or file.
- Cmd + Shift + Arrow selects toward the corresponding boundary.
- Cmd + C copies selected text, or the current line when nothing is selected.
- Cmd + Z undoes, Cmd + Shift + Z redoes, and Cmd + A selects the current Neovim file.
- Cmd + B toggles the Neovim explorer; Cmd + Left/Right resizes it between 15% and 50% of the screen.
- Typing, Backspace, Delete, or paste replaces an active zsh selection.

The left Option key is used as Alt by Ghostty. Restart Ghostty after changing its configuration.

## Neovim Git workflow

- `:gs` or `<leader>gs` opens Git status; Enter opens the selected file in Diffview.
- `:gb` or `<leader>gb` opens local and remote branches.
- `:ga` or `<leader>ga` opens the two-pane staging view.
- In staging, Enter moves one file and Shift+Enter moves all files between the unstaged and staged panes.
- Left/Right switches staging panes, `r` refreshes, and Esc closes the modal.
- `:gc` or `<leader>gc` opens the commit window.
- In the commit window, Ctrl/Cmd+S commits, Ctrl/Cmd+P pushes, and Esc closes the modal.
- Up/Down browses Ex command history after entering `:`.
- `:ThemeSelect` opens the theme picker; `:ThemeDark` and `:ThemeLight` select the configured defaults.

The `nvim/LICENSE` file is the Apache 2.0 license from the upstream LazyVim starter template and is intentionally retained.

## Security

This repository has no tokens, passwords, SSH keys, or personal email addresses. Git ignores .env, *.local, *.secret, and secrets/. If Homebrew is missing, the script uses only the official Homebrew installation address.
