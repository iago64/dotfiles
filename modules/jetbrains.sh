# shellcheck shell=bash
# JetBrains Toolbox. Despues de la primera ejecucion se actualiza solo.

TOOLBOX_DIR=/opt/jetbrains-toolbox
TOOLBOX_USER_BIN="$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"

module_main() {
    if [[ -x "$TOOLBOX_USER_BIN" ]]; then
        log_info 'JetBrains Toolbox ya esta instalado (se actualiza solo).'
        return 0
    fi

    if [[ ! -x "$TOOLBOX_DIR/bin/jetbrains-toolbox" ]]; then
        local platform url
        case "$(uname -m)" in
            x86_64) platform=linux ;;
            aarch64) platform=linuxARM64 ;;
            *) die "Arquitectura no soportada por JetBrains Toolbox: $(uname -m)" ;;
        esac
        url="$(download 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' |
            jq -er --arg p "$platform" '.TBA[0].downloads[$p].link')"
        log_info "Descargando $url"
        sudo install -m 0755 -d "$TOOLBOX_DIR"
        # Directorio fijo: volver a ejecutar no acumula versiones en /opt.
        download "$url" | sudo tar -xz --strip-components=1 -C "$TOOLBOX_DIR"
    fi

    local old
    for old in /opt/jetbrains-toolbox-*; do
        [[ -d "$old" ]] && log_warn "Version vieja de Toolbox de ejecuciones anteriores: sudo rm -rf $old"
    done

    # La primera ejecucion se instala en ~/.local/share/JetBrains y crea la entrada de menu.
    if has_graphical_session; then
        nohup setsid "$TOOLBOX_DIR/bin/jetbrains-toolbox" >/dev/null 2>&1 &
        log_info 'JetBrains Toolbox se esta abriendo para completar su instalacion.'
    else
        log_warn "Sin sesion grafica: abre $TOOLBOX_DIR/bin/jetbrains-toolbox una vez desde el escritorio."
    fi
}
