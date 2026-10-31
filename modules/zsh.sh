# shellcheck shell=bash
# Zsh con Oh My Zsh, zsh-autosuggestions y zsh-syntax-highlighting como shell por defecto.

module_main() {
    pkg_install_module zsh

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        # KEEP_ZSHRC: el .zshrc lo gestiona el modulo dotfiles (common/.zshrc).
        download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh |
            RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -s -- --unattended --keep-zshrc
    fi

    local custom="$HOME/.oh-my-zsh/custom/plugins"
    clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$custom/zsh-autosuggestions"
    clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$custom/zsh-syntax-highlighting"

    local zsh_path current_shell
    zsh_path="$(command -v zsh)"
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$current_shell" != "$zsh_path" ]]; then
        if ! grep -qxF "$zsh_path" /etc/shells; then
            printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        sudo usermod --shell "$zsh_path" "$USER"
        log_info "Shell por defecto: $zsh_path (aplica en el proximo inicio de sesion)."
    fi
}
