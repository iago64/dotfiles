# shellcheck shell=bash
# Enlaza el contenido de common/ en $HOME y engancha el entorno compartido en bash.

COMMON_DIR="$DOTFILES_DIR/common"
BASH_HOOK_MARKER='# dotfiles: entorno compartido (nvm, pnpm, SDKMAN, .NET)'

same_target() {
    [[ -L "$1" ]] && [[ "$(readlink -f -- "$1")" == "$(readlink -f -- "$2")" ]]
}

# Los directorios se recorren y se crean en el destino (respeta lo que ya
# haya en ~/.config); los archivos se enlazan. Lo que choque se respalda.
link_entry() {
    local source_path="$1"
    local destination="$HOME/${source_path#"$COMMON_DIR"/}"
    local child

    if [[ -d "$source_path" && ! -L "$source_path" ]]; then
        same_target "$destination" "$source_path" && return 0
        if [[ -L "$destination" || (-e "$destination" && ! -d "$destination") ]]; then
            backup_path "$destination"
        fi
        mkdir -p -- "$destination"
        while IFS= read -r -d '' child; do
            link_entry "$child"
        done < <(find "$source_path" -mindepth 1 -maxdepth 1 ! -name .gitkeep -print0)
        return 0
    fi

    mkdir -p -- "$(dirname -- "$destination")"
    same_target "$destination" "$source_path" && return 0
    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_path "$destination"
    fi
    ln -s -- "$source_path" "$destination"
    log_info "Enlace: ~/${destination#"$HOME"/} -> ${source_path#"$DOTFILES_DIR"/}"
}

# bash no se reemplaza (cada distro trae su .bashrc); solo se le agrega la
# carga del mismo env.sh que usa zsh.
ensure_bash_hook() {
    local bashrc="$HOME/.bashrc"
    grep -qxF "$BASH_HOOK_MARKER" "$bashrc" 2>/dev/null && return 0
    # shellcheck disable=SC2016
    printf '\n%s\n[ -f "$HOME/.config/dotfiles/env.sh" ] && . "$HOME/.config/dotfiles/env.sh"\n' \
        "$BASH_HOOK_MARKER" >>"$bashrc"
    log_info 'Agregada la carga de env.sh en ~/.bashrc'
}

module_main() {
    [[ -d "$COMMON_DIR" ]] || die "No existe $COMMON_DIR."
    local entry
    while IFS= read -r -d '' entry; do
        link_entry "$entry"
    done < <(find "$COMMON_DIR" -mindepth 1 -maxdepth 1 ! -name .gitkeep -print0)
    ensure_bash_hook
}
