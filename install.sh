#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$SCRIPT_DIR/common"

error_trap() {
    local status=$?
    printf 'Error en install.sh (linea %s): %s\n' "$1" "$2" >&2
    exit "$status"
}
trap 'error_trap "$LINENO" "$BASH_COMMAND"' ERR

if [[ ! -r /etc/os-release ]]; then
    printf 'No se puede leer /etc/os-release; no es posible detectar la distribucion.\n' >&2
    exit 1
fi

# os-release contiene asignaciones de shell definidas por la distribucion.
# shellcheck disable=SC1091
source /etc/os-release

distro_script=''
case "${ID:-}" in
    linuxmint)
        distro_script="mint.sh"
        ;;
    ubuntu|debian)
        distro_script="ubuntu.sh"
        ;;
    fedora)
        distro_script="fedora.sh"
        ;;
    arch)
        distro_script="arch.sh"
        ;;
    *)
        case "${ID_LIKE:-}" in
            *ubuntu*|*debian*)
                distro_script="ubuntu.sh"
                ;;
            *fedora*|*rhel*)
                distro_script="fedora.sh"
                ;;
            *arch*)
                distro_script="arch.sh"
                ;;
            *)
                printf 'Distribucion no soportada: ID=%s ID_LIKE=%s\n' \
                    "${ID:-desconocido}" "${ID_LIKE:-}" >&2
                exit 1
                ;;
        esac
        ;;
esac

DISTRO_SCRIPT="$SCRIPT_DIR/distros/$distro_script"
if [[ ! -x "$DISTRO_SCRIPT" ]]; then
    printf 'No existe un script ejecutable para esta distribucion: %s\n' "$DISTRO_SCRIPT" >&2
    exit 1
fi

printf 'Instalando paquetes para %s con %s...\n' "${PRETTY_NAME:-$ID}" "$distro_script"
"$DISTRO_SCRIPT"

if [[ ! -d "$COMMON_DIR" ]]; then
    printf 'No existe el directorio de configuraciones compartidas: %s\n' "$COMMON_DIR" >&2
    exit 1
fi
if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
    printf 'HOME no esta definido o no es un directorio valido.\n' >&2
    exit 1
fi

backup_destination() {
    local destination="$1"
    local timestamp backup suffix
    timestamp="$(date '+%Y%m%d%H%M%S')"
    backup="${destination}.backup-${timestamp}-$$"
    suffix=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${destination}.backup-${timestamp}-$$-${suffix}"
        suffix=$((suffix + 1))
    done

    mv -- "$destination" "$backup"
    printf 'Respaldo creado: %s\n' "$backup"
}

link_common_entry() {
    local source_path="$1"
    local relative_path="${source_path#"$COMMON_DIR"/}"
    local destination="$HOME/$relative_path"

    # Preserve the directory tree and any unrelated files already in ~/.config.
    if [[ -d "$source_path" && ! -L "$source_path" ]]; then
        if [[ -L "$destination" ]] &&
            [[ "$(readlink -f -- "$destination")" == "$(readlink -f -- "$source_path")" ]]; then
            return
        fi

        if [[ -L "$destination" || ( -e "$destination" && ! -d "$destination" ) ]]; then
            backup_destination "$destination"
        fi

        mkdir -p -- "$destination"
        while IFS= read -r -d '' child; do
            link_common_entry "$child"
        done < <(find "$source_path" -mindepth 1 -maxdepth 1 -print0)
        return
    fi

    mkdir -p -- "$(dirname -- "$destination")"
    if [[ -L "$destination" ]] &&
        [[ "$(readlink -f -- "$destination")" == "$(readlink -f -- "$source_path")" ]]; then
        return
    fi

    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_destination "$destination"
    fi
    ln -s -- "$source_path" "$destination"
    printf 'Enlace creado: %s -> %s\n' "$destination" "$source_path"
}

while IFS= read -r -d '' entry; do
    [[ "$(basename -- "$entry")" == ".gitkeep" ]] && continue
    link_common_entry "$entry"
done < <(find "$COMMON_DIR" -mindepth 1 -maxdepth 1 -print0)

printf 'Instalacion y enlaces de configuracion completados.\n'
