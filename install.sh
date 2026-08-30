#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.mac-config-backups/$(date +%Y%m%d-%H%M%S)"

info() {
  printf '\n\033[1;34m→ %s\033[0m\n' "$1"
}

success() {
  printf '\033[1;32m✓ %s\033[0m\n' "$1"
}

fail() {
  printf '\033[1;31m✗ %s\033[0m\n' "$1" >&2
  exit 1
}

backup_and_link() {
  source_path="$1"
  target_path="$2"

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    success "Link is already correct: $target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    relative_path="$(printf '%s' "$target_path" | sed "s#^$HOME/##")"
    backup_path="$BACKUP_DIR/$relative_path"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target_path" "$backup_path"
    info "Existing file backed up: $backup_path"
  fi

  ln -s "$source_path" "$target_path"
  success "Linked: $target_path"
}

[ "$(uname -s)" = "Darwin" ] || fail "This setup is for macOS only."

info "Checking Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  fail "The Command Line Tools installer started. Run install.sh again when it is finished."
fi
success "Command Line Tools are ready"

info "Setting up Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

command -v brew >/dev/null 2>&1 || fail "Homebrew could not be added to PATH."
success "Homebrew is ready: $(brew --prefix)"

info "Installing apps and terminal tools"
HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle --file="$REPO_DIR/Brewfile"
success "Homebrew packages are ready"

info "Linking configuration files"
backup_and_link "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$REPO_DIR/ghostty/config" "$HOME/.config/ghostty/config"
backup_and_link "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
backup_and_link "$REPO_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
backup_and_link "$REPO_DIR/git/.gitconfig.example" "$HOME/.gitconfig"

mkdir -p "$HOME/.nvm"

SKIP_NODE_VALUE="$(printenv SKIP_NODE 2>/dev/null || printf '0')"
if [ "$SKIP_NODE_VALUE" != "1" ]; then
  info "Setting up Node.js LTS with NVM"
  NVM_DIR="$HOME/.nvm"
  export NVM_DIR
  NVM_SCRIPT="$(brew --prefix nvm)/nvm.sh"
  if [ -s "$NVM_SCRIPT" ]; then
    . "$NVM_SCRIPT"
    nvm install --lts
    nvm alias default 'lts/*'
    success "Node.js LTS is ready"
  else
    fail "NVM is installed, but nvm.sh was not found."
  fi
else
  info "Skipping Node.js because SKIP_NODE=1"
fi

info "Applying macOS settings"
"$REPO_DIR/macos/defaults.sh"

printf '\n'
success "New Mac setup is complete."
printf 'Run the two git config commands in the README to add your Git identity.\n'
printf 'Close and reopen your terminal apps.\n'
