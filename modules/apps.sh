# shellcheck shell=bash
# Aplicaciones de escritorio: paquete nativo cuando existe, Flatpak si no.

warn_legacy_installs() {
    local snap_name
    if command -v snap >/dev/null 2>&1; then
        for snap_name in discord obs-studio vlc; do
            if snap list "$snap_name" >/dev/null 2>&1; then
                log_warn "Sigue instalado el snap $snap_name de ejecuciones anteriores: sudo snap remove $snap_name"
            fi
        done
    fi
    if [[ "$DISTRO_FAMILY" == debian ]] &&
        dpkg-query -W -f='${db:Status-Status}' discord 2>/dev/null | grep -qx installed; then
        log_warn 'Sigue instalado el .deb de Discord (ahora se usa Flatpak): sudo apt remove discord'
    fi
}

module_main() {
    adapter_prepare apps

    local name native flatpak
    local -a natives=() flatpaks=()
    while IFS=$'\t' read -r name native flatpak; do
        if [[ "$native" != '-' ]]; then
            # shellcheck disable=SC2206
            natives=($native)
            log_info "$name: paquete nativo ${natives[*]}"
            if pkg_install "${natives[@]}"; then
                continue
            fi
            log_warn "No se pudo instalar $name con el gestor de paquetes."
        fi
        if [[ "$flatpak" != '-' ]]; then
            log_info "$name: Flatpak $flatpak"
            flatpaks+=("$flatpak")
        else
            log_warn "$name no tiene paquete nativo ni Flatpak definido en packages.txt."
        fi
    done < <(module_rows apps)

    flatpak_install "${flatpaks[@]}"

    # Fedora trae ffmpeg recortado; con RPM Fusion se cambia por el completo.
    if [[ "$DISTRO_FAMILY" == fedora ]] && rpm -q ffmpeg-free >/dev/null 2>&1; then
        sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    fi

    warn_legacy_installs
}
