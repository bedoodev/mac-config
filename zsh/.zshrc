# ~/.zshrc

# Homebrew
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

# Shell defaults
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

bindkey -e

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go
if command -v go >/dev/null 2>&1; then
  export PATH="$PATH:$(go env GOPATH)/bin"
fi

# Python / pyenv
export PYENV_ROOT="$HOME/.pyenv"

if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"

if command -v brew >/dev/null 2>&1; then
  NVM_FORMULA_DIR="$(brew --prefix nvm 2>/dev/null)"

  [ -s "$NVM_FORMULA_DIR/nvm.sh" ] &&
    source "$NVM_FORMULA_DIR/nvm.sh"

  unset NVM_FORMULA_DIR
fi

# Aliases
alias ls='eza'
alias ll='eza -lah'
alias la='eza --all --group-directories-first'
alias tree='eza --tree'

alias cat='bat'
alias nano='micro'

alias lg='lazygit'
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'

# Lazydocker with active Podman machine
ld() {
  local podman_socket

  podman_socket="$(
    podman machine inspect podman-machine-default \
      --format '{{.ConnectionInfo.PodmanSocket.Path}}' \
      2>/dev/null
  )"

  if [ -n "$podman_socket" ]; then
    DOCKER_HOST="unix://$podman_socket" command lazydocker "$@"
  else
    command lazydocker "$@"
  fi
}

# fzf
if command -v brew >/dev/null 2>&1; then
  FZF_BASE="$(brew --prefix fzf 2>/dev/null)"

  [ -r "$FZF_BASE/shell/completion.zsh" ] &&
    source "$FZF_BASE/shell/completion.zsh"

  [ -r "$FZF_BASE/shell/key-bindings.zsh" ] &&
    source "$FZF_BASE/shell/key-bindings.zsh"

  unset FZF_BASE
fi

# Shell integrations
command -v zoxide >/dev/null 2>&1 &&
  eval "$(zoxide init zsh)"

command -v direnv >/dev/null 2>&1 &&
  eval "$(direnv hook zsh)"

command -v starship >/dev/null 2>&1 &&
  eval "$(starship init zsh)"

# Interactive ZLE configuration
if [[ -o interactive ]]; then

  # Cmd gibi genişletilmiş modifier'ların zsh'a CSI-u olarak ulaşmasını sağla.
  # Komut çalıştırılırken modu kapat; nvim gibi uygulamalar kendi protokolünü yönetir.
  autoload -Uz add-zle-hook-widget

  enable-kitty-keyboard() {
    printf '\e[>1u'
  }

  disable-kitty-keyboard() {
    printf '\e[<u'
  }

  add-zle-hook-widget line-init enable-kitty-keyboard
  add-zle-hook-widget line-finish disable-kitty-keyboard

	# Prefix-based history search
	autoload -Uz history-search-end

	zle -N history-beginning-search-backward-end history-search-end
	zle -N history-beginning-search-forward-end history-search-end

	bindkey '^[[A' history-beginning-search-backward-end
	bindkey '^[[B' history-beginning-search-forward-end
  # Custom key bindings
  for keymap in emacs viins; do
    bindkey -M "$keymap" '\e[122;9u' undo
    bindkey -M "$keymap" '\e[122;10u' redo

    bindkey -M "$keymap" '\e[27;9u' kill-whole-line

    bindkey -M "$keymap" '\e[1;3D' backward-word
    bindkey -M "$keymap" '\e[1;3C' forward-word
    bindkey -M "$keymap" '\e[27;3u' backward-kill-word

    bindkey -M "$keymap" '\e[99~' beginning-of-line
    bindkey -M "$keymap" '\e[100~' end-of-line
    bindkey -M "$keymap" '\e[101~' beginning-of-history
    bindkey -M "$keymap" '\e[102~' end-of-history
  done

  # Shift + Left
  select-backward-char() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    zle backward-char
  }

  zle -N select-backward-char

  # Shift + Right
  select-forward-char() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    zle forward-char
  }

  zle -N select-forward-char

  # Shift + Option + Left
  select-backward-word() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    zle backward-word
  }

  zle -N select-backward-word

  # Shift + Option + Right
  select-forward-word() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    zle forward-word
  }

  zle -N select-forward-word

  # Shift + Up
  select-up-line() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    # Geçerli satırın üstünde metin yoksa komut geçmişine geçme.
    if [[ $LBUFFER == *$'\n'* ]]; then
      zle up-line-or-history
    fi
  }

  zle -N select-up-line

  # Shift + Down
  select-down-line() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    # Geçerli satırın altında metin yoksa komut geçmişine geçme.
    if [[ $RBUFFER == *$'\n'* ]]; then
      zle down-line-or-history
    fi
  }

  zle -N select-down-line

  # Cmd + Shift + Left
  select-beginning-of-line() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    zle beginning-of-line
  }

  zle -N select-beginning-of-line

  # Cmd + Shift + Right
  select-end-of-line() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    zle end-of-line
  }

  zle -N select-end-of-line

  # Cmd + Shift + Up/Down
  select-beginning-of-buffer() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    CURSOR=0
  }

  select-end-of-buffer() {
    if (( REGION_ACTIVE == 0 )); then
      zle set-mark-command
    fi

    CURSOR=${#BUFFER}
  }

  zle -N select-beginning-of-buffer
  zle -N select-end-of-buffer

  # Ghostty selection key bindings
  for keymap in emacs viins; do
    bindkey -M "$keymap" '\e[1;2D' select-backward-char
    bindkey -M "$keymap" '\e[1;2C' select-forward-char
    bindkey -M "$keymap" '\e[1;2A' select-up-line
    bindkey -M "$keymap" '\e[1;2B' select-down-line
    bindkey -M "$keymap" '\e[1;4D' select-backward-word
    bindkey -M "$keymap" '\e[1;4C' select-forward-word

    bindkey -M "$keymap" '\e[1;10D' select-beginning-of-line
    bindkey -M "$keymap" '\e[1;10C' select-end-of-line
    bindkey -M "$keymap" '\e[103~' select-beginning-of-line
    bindkey -M "$keymap" '\e[104~' select-end-of-line
    bindkey -M "$keymap" '\e[105~' select-beginning-of-buffer
    bindkey -M "$keymap" '\e[106~' select-end-of-buffer

    bindkey -M "$keymap" '\e[1;2H' select-beginning-of-line
    bindkey -M "$keymap" '\e[1;2F' select-end-of-line
    bindkey -M "$keymap" '\e[1;6H' select-beginning-of-buffer
    bindkey -M "$keymap" '\e[1;6F' select-end-of-buffer
  done

  # Cmd + C: Shift+Ok ile seçilen ZLE bölgesini macOS panosuna kopyala.
  copy-selected-text() {
    if (( REGION_ACTIVE == 0 || MARK == CURSOR )); then
      local current_line_left="${LBUFFER##*$'\n'}"
      local current_line_right="${RBUFFER%%$'\n'*}"
      printf '%s' "$current_line_left$current_line_right" | pbcopy
      return
    fi

    local start=$MARK
    local finish=$CURSOR

    if (( start > finish )); then
      local tmp=$start
      start=$finish
      finish=$tmp
    fi

    printf '%s' "$BUFFER[$(( start + 1 )),$finish]" | pbcopy
  }

  zle -N copy-selected-text
  for keymap in emacs viins; do
    bindkey -M "$keymap" '\e[99;9u' copy-selected-text
  done

  # Backspace/Delete aktif seçimi siler; seçim yoksa normal davranır.
  delete-selection-or-backward-char() {
    if (( REGION_ACTIVE )); then
      zle kill-region
    else
      zle .backward-delete-char
    fi
  }

  delete-selection-or-char() {
    if (( REGION_ACTIVE )); then
      zle kill-region
    else
      zle .delete-char
    fi
  }

  zle -N backward-delete-char delete-selection-or-backward-char
  zle -N delete-char delete-selection-or-char

  # Yazılan karakter aktif seçimin yerini alır.
  replace-selection-self-insert() {
    if (( REGION_ACTIVE )); then
      zle kill-region
    fi

    zle .self-insert
  }

  zle -N self-insert replace-selection-self-insert

  # Yapıştırılan metin de aktif seçimin yerini alır.
  replace-selection-bracketed-paste() {
    if (( REGION_ACTIVE )); then
      zle kill-region
    fi

    zle .bracketed-paste
  }

  zle -N bracketed-paste replace-selection-bracketed-paste

  # Fare seçimine yakın, daha yumuşak bir ZLE seçim rengi.
  zle_highlight=("region:bg=#585b70,fg=#cdd6f4")

  # Shift + Enter -> insert newline without executing
  insert-newline() {
    LBUFFER+=$'\n'
  }

  zle -N insert-newline
  bindkey '\e[13;2u' insert-newline

fi
