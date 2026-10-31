#!/usr/bin/env bash
# Comprueba que el entorno quedo completo. La salida (herramienta -> version)
# deberia ser la misma en cualquier distro soportada.
#
# Uso: ./verify.sh [--cli]    (--cli omite las herramientas graficas)
set -o pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/log.sh
source "$DOTFILES_DIR/lib/log.sh"
# shellcheck source=versions.env
source "$DOTFILES_DIR/versions.env"

CLI_ONLY=0
case "${1:-}" in
    --cli) CLI_ONLY=1 ;;
    '') ;;
    -h | --help)
        sed -n '2,5p' "$0"
        exit 0
        ;;
    *) die "Opcion desconocida: $1" ;;
esac

# Carga nvm, SDKMAN, pnpm y .NET igual que una shell interactiva.
env_file="$HOME/.config/dotfiles/env.sh"
[[ -f "$env_file" ]] || env_file="$DOTFILES_DIR/common/.config/dotfiles/env.sh"
# shellcheck source=common/.config/dotfiles/env.sh
source "$env_file"

MISSING=0

ok() { printf '  %-6s %-22s %s\n' 'OK' "$1" "$2"; }
fail() {
    printf '  %s%-6s%s %-22s %s\n' "$_c_err" 'FALTA' "$_c_reset" "$1" "$2"
    MISSING=$((MISSING + 1))
}
section() { printf '\n%s\n' "$1"; }

# check NOMBRE COMANDO [ARGS para obtener la version...]
check() {
    local name="$1" cmd="$2" version
    shift 2
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fail "$name" "no se encontro '$cmd'"
        return
    fi
    if (($# > 0)); then
        version="$("$cmd" "$@" 2>&1 | grep -m1 -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//' | cut -c1-70)"
    else
        version="$(command -v "$cmd")"
    fi
    ok "$name" "$version"
}

check_file() {
    local name="$1" path
    shift
    for path in "$@"; do
        if [[ -e "$path" ]]; then
            ok "$name" "$path"
            return
        fi
    done
    fail "$name" "no existe: $*"
}

# check_major NOMBRE VERSION_ESPERADA VERSION_REAL
check_major() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" || "$actual" == "$expected".* ]]; then
        ok "$name" "$actual"
    else
        fail "$name" "se esperaba $expected, hay '${actual:-nada}'"
    fi
}

section 'Base'
check git git --version
check curl curl --version
check wget wget --version
check jq jq --version
check zip zip -v
check unzip unzip -v
check tree tree --version
check htop htop --version
check fastfetch fastfetch --version
check vim vim --version
check nano nano --version
check strace strace -V
check net-tools netstat
check xclip xclip
check gnupg gpg --version
check ssh ssh -V
check_file sshd /usr/sbin/sshd /usr/bin/sshd

section 'Toolchain'
check gcc gcc --version
check g++ g++ --version
check gdb gdb --version
check make make --version
check cmake cmake --version
check autoconf autoconf --version
check automake automake --version
check libtool libtoolize --version
check valgrind valgrind --version
check python3 python3 --version
check pip python3 -m pip --version
check_file CUnit /usr/include/CUnit/CUnit.h

section 'Contenedores'
check podman podman --version
check podman-compose podman-compose --version

section 'Runtimes'
check_major ".NET SDK" "${DOTNET_CHANNEL%%.*}" "$(dotnet --version 2>/dev/null)"
check_major Node "$NODE_VERSION" "$(node --version 2>/dev/null | sed 's/^v//')"
check pnpm pnpm --version
for major in $JAVA_MAJORS; do
    if compgen -G "${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/${major}.*-${JAVA_VENDOR}" >/dev/null; then
        ok "Java $major" "$(basename "$(compgen -G "${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/${major}.*-${JAVA_VENDOR}" | sort -V | tail -n 1)")"
    else
        fail "Java $major" "no hay $JAVA_VENDOR $major en SDKMAN"
    fi
done
check_major 'Java por defecto' "$JAVA_DEFAULT_MAJOR" \
    "$(java -version 2>&1 | awk -F'"' '/version/ { print $2; exit }')"
check gradle gradle --version
check quarkus quarkus --version

section 'Shell'
check zsh zsh --version
check_file 'Oh My Zsh' "$HOME/.oh-my-zsh/oh-my-zsh.sh"
check_file zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
check_file zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
login_shell="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)"
if [[ "$(basename -- "$login_shell")" == zsh ]]; then
    ok 'Shell por defecto' "$login_shell"
else
    fail 'Shell por defecto' "es $login_shell"
fi

section 'Configuracion (common/)'
while IFS= read -r -d '' file; do
    relative="${file#"$DOTFILES_DIR/common/"}"
    if [[ -L "$HOME/$relative" && "$(readlink -f -- "$HOME/$relative")" == "$(readlink -f -- "$file")" ]]; then
        ok "\$HOME/$relative" 'enlazado'
    else
        fail "\$HOME/$relative" 'no apunta al repo'
    fi
done < <(find "$DOTFILES_DIR/common" -type f ! -name .gitkeep -print0 | sort -z)

if ((! CLI_ONLY)); then
    section 'Escritorio'
    check terminator terminator --version
    check meld meld --version
    check ghex ghex
    check 'VS Code' code --version
    check_file 'JetBrains Toolbox' \
        "$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox" \
        /opt/jetbrains-toolbox/bin/jetbrains-toolbox

    section 'Aplicaciones'
    while IFS='|' read -r module name _ _ _ flatpak_id; do
        module="${module//[[:space:]]/}"
        [[ "$module" == apps ]] || continue
        name="${name//[[:space:]]/}"
        flatpak_id="${flatpak_id//[[:space:]]/}"
        if command -v "$name" >/dev/null 2>&1; then
            ok "$name" "$(command -v "$name")"
        elif [[ "$flatpak_id" != '-' ]] && flatpak info "$flatpak_id" >/dev/null 2>&1; then
            ok "$name" "flatpak $flatpak_id"
        else
            fail "$name" 'no instalado'
        fi
    done < <(grep -v '^[[:space:]]*#' "$DOTFILES_DIR/packages.txt")
fi

printf '\n'
if ((MISSING > 0)); then
    log_error "Faltan $MISSING elementos."
    exit 1
fi
log_ok 'Entorno completo.'
