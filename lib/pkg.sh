# shellcheck shell=bash
# Lectura de packages.txt e instalacion de paquetes a traves del adaptador de
# la distro (adapters/<familia>.sh define adapter_install y compania).

PACKAGES_FILE="$DOTFILES_DIR/packages.txt"

# Imprime una linea por paquete del modulo: "nombre<TAB>nativo<TAB>flatpak".
module_rows() {
    local module="$1" column
    case "$DISTRO_FAMILY" in
        debian) column=3 ;;
        fedora) column=4 ;;
        arch) column=5 ;;
        *) die "Familia de distro desconocida: $DISTRO_FAMILY" ;;
    esac

    awk -F'|' -v module="$module" -v column="$column" -v dotnet="$DOTNET_CHANNEL" '
        function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
        /^[[:space:]]*(#|$)/ { next }
        trim($1) == module {
            native = trim($column)
            gsub(/\$\{DOTNET_CHANNEL\}/, dotnet, native)
            printf "%s\t%s\t%s\n", trim($2), native, trim($6)
        }
    ' "$PACKAGES_FILE"
}

# Paquetes nativos del modulo, uno por linea y sin duplicados.
module_native_packages() {
    local native pkg
    while IFS=$'\t' read -r _ native _; do
        [[ "$native" == '-' ]] && continue
        for pkg in $native; do
            printf '%s\n' "$pkg"
        done
    done < <(module_rows "$1") | awk '!seen[$0]++'
}

pkg_install() {
    (($# > 0)) || return 0
    adapter_install "$@"
}

# Instala todos los paquetes nativos de un modulo en una sola transaccion.
pkg_install_module() {
    local -a packages=()
    mapfile -t packages < <(module_native_packages "$1")
    if ((${#packages[@]} == 0)); then
        log_info "Sin paquetes nativos para $1 en esta distro."
        return 0
    fi
    log_info "Paquetes: ${packages[*]}"
    if pkg_install "${packages[@]}"; then
        return 0
    fi

    # Un paquete que no existe hace fallar toda la transaccion: se reintenta de
    # a uno para instalar el resto y reportar exactamente cuales faltan.
    log_warn 'Fallo la instalacion conjunta; se reintenta paquete por paquete.'
    local pkg
    local -a failed=()
    for pkg in "${packages[@]}"; do
        pkg_install "$pkg" || failed+=("$pkg")
    done
    if ((${#failed[@]} > 0)); then
        log_error "No se pudieron instalar: ${failed[*]}"
        return 1
    fi
}

# Flatpak a nivel sistema con Flathub configurado.
ensure_flathub() {
    command -v flatpak >/dev/null 2>&1 || pkg_install flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

flatpak_install() {
    (($# > 0)) || return 0
    ensure_flathub
    sudo flatpak install -y --noninteractive --system flathub "$@"
}
