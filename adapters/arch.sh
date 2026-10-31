# shellcheck shell=bash
# Adaptador para Arch Linux y derivadas (pacman + yay para AUR).

adapter_refresh() {
    : # En Arch se sincroniza junto con el upgrade (pacman -Syu).
}

adapter_upgrade() {
    sudo pacman -Syu --noconfirm
}

adapter_install() {
    local -a repo=() aur=()
    local pkg
    for pkg in "$@"; do
        if [[ "$pkg" == aur:* ]]; then
            aur+=("${pkg#aur:}")
        else
            repo+=("$pkg")
        fi
    done
    if ((${#repo[@]} > 0)); then
        sudo pacman -S --needed --noconfirm "${repo[@]}" || return
    fi
    if ((${#aur[@]} > 0)); then
        arch_ensure_yay || return
        yay -S --needed --noconfirm "${aur[@]}" || return
    fi
}

adapter_prepare() {
    : # Arch no necesita repos adicionales.
}

arch_ensure_yay() {
    command -v yay >/dev/null 2>&1 && return 0
    log_info 'Instalando yay (AUR helper).'
    sudo pacman -S --needed --noconfirm git base-devel || return
    local build_dir status=0
    build_dir="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin" &&
        (cd "$build_dir/yay-bin" && makepkg -si --noconfirm) || status=$?
    rm -rf -- "$build_dir"
    return "$status"
}
