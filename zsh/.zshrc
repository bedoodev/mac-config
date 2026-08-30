# Homebrew: Apple Silicon first, Intel fallback.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Comfortable defaults
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
bindkey -e

# Bun and Go
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
if command -v go >/dev/null 2>&1; then
  export PATH="$PATH:$(go env GOPATH)/bin"
fi

# Better command-line tools
alias ls='eza'
alias ll='eza -lah'
alias la='eza --all --group-directories-first'
alias tree='eza --tree'
alias cat='bat'
alias lg='lazygit'
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'

# Lazydocker with the active Podman machine on macOS.
ld() {
  local podman_socket
  podman_socket="$(podman machine inspect podman-machine-default --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"

  if [ -n "$podman_socket" ]; then
    DOCKER_HOST="unix://$podman_socket" command lazydocker "$@"
  else
    command lazydocker "$@"
  fi
}

# fzf completion and key bindings
if command -v brew >/dev/null 2>&1; then
  FZF_BASE="$(brew --prefix fzf 2>/dev/null)"
  [ -r "$FZF_BASE/shell/completion.zsh" ] && source "$FZF_BASE/shell/completion.zsh"
  [ -r "$FZF_BASE/shell/key-bindings.zsh" ] && source "$FZF_BASE/shell/key-bindings.zsh"
  unset FZF_BASE
fi

# Python
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi

# nvm (installed by Homebrew, versions live outside this repository)
export NVM_DIR="$HOME/.nvm"
if command -v brew >/dev/null 2>&1; then
  NVM_FORMULA_DIR="$(brew --prefix nvm 2>/dev/null)"
  [ -s "$NVM_FORMULA_DIR/nvm.sh" ] && source "$NVM_FORMULA_DIR/nvm.sh"
  [ -s "$NVM_FORMULA_DIR/etc/bash_completion.d/nvm" ] && source "$NVM_FORMULA_DIR/etc/bash_completion.d/nvm"
  unset NVM_FORMULA_DIR
fi

# Shell integrations
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
