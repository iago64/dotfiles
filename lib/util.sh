# shellcheck shell=bash
# Utilidades compartidas por los modulos.

# Descarga con reintentos. Uso: download URL [destino]; sin destino escribe a stdout.
download() {
    local url="$1" dest="${2:-}"
    if [[ -n "$dest" ]]; then
        curl -fsSL --retry 3 --retry-delay 2 -o "$dest" "$url"
    else
        curl -fsSL --retry 3 --retry-delay 2 "$url"
    fi
}

# Hay una sesion systemd de usuario (necesaria para systemctl --user).
has_user_session_bus() {
    [[ -n "${XDG_RUNTIME_DIR:-}" && -S "$XDG_RUNTIME_DIR/bus" ]] &&
        systemctl --user show-environment >/dev/null 2>&1
}

has_graphical_session() {
    [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]
}

# Clona un repo git o lo actualiza si ya existe.
clone_or_update() {
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
        git -C "$dest" pull --ff-only --quiet
    else
        git clone --depth 1 --quiet "$url" "$dest"
    fi
}

# Devuelve 0 si $1 esta en la lista de argumentos restantes.
in_list() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Mueve un archivo existente a un respaldo con fecha y lo informa.
backup_path() {
    local path="$1" timestamp backup suffix=1
    timestamp="$(date '+%Y%m%d%H%M%S')"
    backup="${path}.backup-${timestamp}"
    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${path}.backup-${timestamp}-${suffix}"
        suffix=$((suffix + 1))
    done
    mv -- "$path" "$backup"
    log_info "Respaldo creado: $backup"
}
