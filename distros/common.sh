#!/usr/bin/env bash

configure_zsh_environment() {
    local zshrc="$HOME/.zshrc"
    local marker="# --- Entorno personalizado de dotfiles ---"

    local template="$HOME/.oh-my-zsh/templates/zshrc.zsh-template"

    if ! grep -Fqx "$marker" "$zshrc" 2>/dev/null; then
        if [[ -f "$template" ]]; then
            [[ -f "$zshrc" ]] && cp -- "$zshrc" "$zshrc.pre-dotfiles.bak"
            cp -- "$template" "$zshrc"
        fi
        cat >> "$zshrc" <<'EOF'

# --- Entorno personalizado de dotfiles ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export PATH="$HOME/.local/share/pnpm:$PATH"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
    fi
}
