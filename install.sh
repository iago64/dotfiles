#!/usr/bin/env bash
# Prepara el mismo entorno de trabajo en Ubuntu, Linux Mint, Fedora y Arch.
# Ejecutar ./install.sh --help para ver las opciones.
set -Eeuo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# shellcheck source=lib/log.sh
source "$DOTFILES_DIR/lib/log.sh"
# shellcheck source=lib/util.sh
source "$DOTFILES_DIR/lib/util.sh"
# shellcheck source=lib/os.sh
source "$DOTFILES_DIR/lib/os.sh"
# shellcheck source=versions.env
source "$DOTFILES_DIR/versions.env"
# shellcheck source=lib/pkg.sh
source "$DOTFILES_DIR/lib/pkg.sh"

# Orden de ejecucion. Cada modulo vive en modules/<nombre>.sh y define module_main.
ALL_MODULES=(base toolchain desktop containers dotnet java node vscode apps jetbrains zsh dotfiles)
# Modulos que se omiten con --cli (sin entorno grafico, por ejemplo en CI).
GUI_MODULES=(desktop vscode apps jetbrains)
# Sin estos comandos (los instala el modulo base) no tiene sentido continuar.
ESSENTIAL_COMMANDS=(git curl jq zip unzip)

declare -A MODULE_DESC=(
    [base]='Herramientas base de linea de comandos'
    [toolchain]='Compiladores, depuradores, CUnit y Python'
    [desktop]='Terminator, Meld y GHex'
    [containers]='Podman y podman-compose'
    [dotnet]=".NET SDK $DOTNET_CHANNEL"
    [java]="SDKMAN: Java ${JAVA_MAJORS// /, } ($JAVA_VENDOR), Gradle y Quarkus"
    [node]="nvm: Node.js $NODE_VERSION y pnpm"
    [vscode]='Visual Studio Code'
    [apps]='Discord, OBS, VLC, Bruno y Bitwarden'
    [jetbrains]='JetBrains Toolbox'
    [zsh]='Zsh, Oh My Zsh y plugins como shell por defecto'
    [dotfiles]='Enlaces de common/ en el directorio personal'
)

usage() {
    cat <<EOF
Uso: ./install.sh [opciones]

Instala y configura el entorno de trabajo. Se puede volver a ejecutar: cada
modulo detecta lo que ya esta hecho.

Opciones:
  --no-upgrade        No actualizar el sistema antes de instalar.
  --cli               Omitir modulos graficos (${GUI_MODULES[*]}).
  --only m1,m2        Ejecutar solo estos modulos.
  --skip m1,m2        Omitir estos modulos.
  --dry-run           Mostrar que se instalaria en esta distro, sin cambiar nada.
  -h, --help          Mostrar esta ayuda.

Modulos, en orden:
EOF
    local module
    for module in "${ALL_MODULES[@]}"; do
        printf '  %-12s %s\n' "$module" "${MODULE_DESC[$module]}"
    done
}

UPGRADE=1
CLI_ONLY=0
DRY_RUN=0
ONLY=()
SKIP=()

split_modules() {
    local -n target="$1"
    local value="$2" module
    IFS=',' read -ra target <<<"$value"
    for module in "${target[@]}"; do
        in_list "$module" "${ALL_MODULES[@]}" || die "Modulo desconocido: $module (ver --help)."
    done
}

while (($# > 0)); do
    case "$1" in
        --no-upgrade) UPGRADE=0 ;;
        --cli) CLI_ONLY=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --only)
            (($# > 1)) || die '--only necesita una lista de modulos.'
            split_modules ONLY "$2"
            shift
            ;;
        --only=*) split_modules ONLY "${1#*=}" ;;
        --skip)
            (($# > 1)) || die '--skip necesita una lista de modulos.'
            split_modules SKIP "$2"
            shift
            ;;
        --skip=*) split_modules SKIP "${1#*=}" ;;
        -h | --help)
            usage
            exit 0
            ;;
        *) die "Opcion desconocida: $1 (ver --help)." ;;
    esac
    shift
done

SELECTED=()
for module in "${ALL_MODULES[@]}"; do
    if ((${#ONLY[@]} > 0)) && ! in_list "$module" "${ONLY[@]}"; then continue; fi
    if ((${#SKIP[@]} > 0)) && in_list "$module" "${SKIP[@]}"; then continue; fi
    if ((CLI_ONLY)) && in_list "$module" "${GUI_MODULES[@]}"; then continue; fi
    SELECTED+=("$module")
done
((${#SELECTED[@]} > 0)) || die 'No quedo ningun modulo para ejecutar.'

if ((EUID == 0)); then
    die 'No ejecutes install.sh como root: usa tu usuario; el script pide sudo cuando lo necesita.'
fi
[[ -n "${HOME:-}" && -d "$HOME" ]] || die 'HOME no esta definido o no es un directorio valido.'
export USER="${USER:-$(id -un)}"

detect_distro
# shellcheck source=/dev/null
source "$DOTFILES_DIR/adapters/$DISTRO_FAMILY.sh"

print_plan() {
    local module name native flatpak
    printf 'Distro: %s (familia %s)\n' "$DISTRO_NAME" "$DISTRO_FAMILY"
    printf 'Upgrade del sistema: %s\n' "$( ((UPGRADE)) && echo si || echo no)"
    for module in "${SELECTED[@]}"; do
        printf '\n[%s] %s\n' "$module" "${MODULE_DESC[$module]}"
        while IFS=$'\t' read -r name native flatpak; do
            if [[ "$native" != '-' ]]; then
                printf '    %-16s %s\n' "$name" "$native"
            elif [[ "$flatpak" != '-' ]]; then
                printf '    %-16s flatpak:%s\n' "$name" "$flatpak"
            else
                printf '    %-16s (no aplica en esta distro)\n' "$name"
            fi
        done < <(module_rows "$module")
    done
}

if ((DRY_RUN)); then
    print_plan
    exit 0
fi

setup_logging() {
    local log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    mkdir -p -- "$log_dir"
    LOG_FILE="$log_dir/install-$(date '+%Y%m%d-%H%M%S').log"
    # Todo lo que se imprime va tambien al log, sin codigos de color.
    exec > >(tee >(sed -u 's/\x1b\[[0-9;]*m//g' >>"$LOG_FILE")) 2>&1
}

# Pide la contrasena una vez y la mantiene vigente durante toda la instalacion.
start_sudo_keepalive() {
    sudo -v || die 'Se necesitan permisos de sudo.'
    (
        while kill -0 "$$" 2>/dev/null; do
            sudo -n true 2>/dev/null
            sleep 50
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

run_module() {
    local module="$1"
    # Cada modulo corre en un subshell: un error lo corta solo a el.
    set -Eeuo pipefail
    trap 'log_error "Fallo en ${BASH_SOURCE[0]#"$DOTFILES_DIR"/}:$LINENO: $BASH_COMMAND"' ERR
    # shellcheck source=/dev/null
    source "$DOTFILES_DIR/modules/$module.sh"
    module_main
}

setup_logging
start_sudo_keepalive

log_step "Instalando entorno para $DISTRO_NAME (familia $DISTRO_FAMILY)"
log_info "Modulos: ${SELECTED[*]}"
log_info "Log: $LOG_FILE"

log_step 'Actualizando indices de paquetes'
adapter_refresh || die 'No se pudieron actualizar los indices de paquetes.'
if ((UPGRADE)); then
    log_step 'Actualizando el sistema'
    adapter_upgrade || die 'Fallo la actualizacion del sistema (se puede omitir con --no-upgrade).'
elif [[ "$DISTRO_FAMILY" == arch ]]; then
    log_warn 'En Arch las actualizaciones parciales no estan soportadas; si falla una instalacion, ejecuta sin --no-upgrade.'
fi

FAILED=()
for module in "${SELECTED[@]}"; do
    log_step "[$module] ${MODULE_DESC[$module]}"
    # Se ejecuta fuera de un if/||: dentro de esos contextos bash ignora set -e.
    set +e
    (run_module "$module")
    status=$?
    set -e
    if ((status == 0)); then
        log_ok "$module"
    else
        FAILED+=("$module")
        log_error "El modulo $module fallo (codigo $status)."
        if [[ "$module" == base ]]; then
            for command_name in "${ESSENTIAL_COMMANDS[@]}"; do
                command -v "$command_name" >/dev/null 2>&1 ||
                    die "Se aborta: falta $command_name, necesario para el resto de la instalacion."
            done
        fi
    fi
done

log_step 'Resumen'
if ((${#FAILED[@]} > 0)); then
    log_error "Modulos con errores: ${FAILED[*]}"
    log_info "Revisa el log ($LOG_FILE) y vuelve a ejecutar: ./install.sh --only $(
        IFS=,
        echo "${FAILED[*]}"
    )"
    exit 1
fi
log_ok 'Instalacion completa.'
log_info 'Cierra sesion y vuelve a entrar para usar zsh como shell por defecto.'
log_info "Para comprobar el entorno: $DOTFILES_DIR/verify.sh$( ((CLI_ONLY)) && echo ' --cli')"
