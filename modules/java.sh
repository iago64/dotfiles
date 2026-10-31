# shellcheck shell=bash
# Java (ultima build de cada version mayor), Gradle y Quarkus con SDKMAN.

# Identificador SDKMAN mas reciente para una version mayor y un proveedor.
sdk_latest_java() {
    local major="$1" vendor="$2"
    sdk list java | awk -F'|' -v vendor="$vendor" -v major="$major" '
        NF >= 6 {
            dist = $4; id = $6
            gsub(/[[:space:]]/, "", dist); gsub(/[[:space:]]/, "", id)
            if (dist == vendor && index(id, major ".") == 1) print id
        }' | sort -V | tail -n 1
}

module_main() {
    export SDKMAN_DIR="$HOME/.sdkman"
    if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        if [[ -e "$SDKMAN_DIR" ]]; then
            log_warn "$SDKMAN_DIR existe pero esta incompleto; se respalda antes de reinstalar."
            backup_path "$SDKMAN_DIR"
        fi
        # rcupdate=false: la carga de SDKMAN la hace common/.config/dotfiles/env.sh.
        download 'https://get.sdkman.io?rcupdate=false' | bash
    fi

    # SDKMAN no es compatible con set -u.
    set +u
    # shellcheck disable=SC1091
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    # Sin preguntas interactivas (por ejemplo "set as default?"); lo leen las funciones de SDKMAN.
    # shellcheck disable=SC2034
    sdkman_auto_answer=true
    # shellcheck disable=SC2034
    sdkman_colour_enable=false

    local major id default_id=''
    for major in $JAVA_MAJORS; do
        id="$(sdk_latest_java "$major" "$JAVA_VENDOR")"
        [[ -n "$id" ]] || die "SDKMAN no ofrece Java $major de $JAVA_VENDOR."
        log_info "Java $major -> $id"
        sdk install java "$id"
        [[ "$major" == "$JAVA_DEFAULT_MAJOR" ]] && default_id="$id"
    done
    if [[ -n "$default_id" ]]; then
        sdk default java "$default_id"
    fi

    sdk install gradle
    sdk install quarkus
    set -u
}
