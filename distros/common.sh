#!/usr/bin/env bash

install_jetbrains_toolbox() {
    local toolbox_url toolbox_bin

    toolbox_url="$(curl -fsSL \
        'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' |
        jq -er '.TBA[0].downloads.linux.link')"
    curl -fsSL "$toolbox_url" | sudo tar -xzC /opt

    # La primera ejecucion de Toolbox se autoinstala y crea su entrada de menu.
    if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        printf 'Sin sesion grafica: ejecute JetBrains Toolbox manualmente desde /opt.\n'
        return 0
    fi
    toolbox_bin="$(find /opt -path '/opt/jetbrains-toolbox*/bin/jetbrains-toolbox' \
        -type f 2>/dev/null | sort | tail -n 1)"
    if [[ -n "$toolbox_bin" ]]; then
        nohup setsid "$toolbox_bin" >/dev/null 2>&1 &
    fi
}

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
