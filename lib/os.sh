# shellcheck shell=bash
# Deteccion de distribucion.
#
# Define:
#   DISTRO_ID, DISTRO_NAME, DISTRO_FAMILY (debian | fedora | arch)
#   UBUNTU_BASE_RELEASE, UBUNTU_BASE_CODENAME (solo familia debian: version de
#   Ubuntu sobre la que se apoya la distro, necesaria para repos de terceros)

detect_distro() {
    [[ -r /etc/os-release ]] ||
        die 'No se puede leer /etc/os-release; no es posible detectar la distribucion.'

    local ID='' ID_LIKE='' PRETTY_NAME='' VERSION_ID='' UBUNTU_CODENAME='' VERSION_CODENAME=''
    # os-release contiene asignaciones de shell definidas por la distribucion.
    # shellcheck disable=SC1091
    source /etc/os-release

    DISTRO_ID="${ID:-desconocido}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    DISTRO_FAMILY=''

    case "$DISTRO_ID" in
        ubuntu | linuxmint) DISTRO_FAMILY='debian' ;;
        fedora) DISTRO_FAMILY='fedora' ;;
        arch) DISTRO_FAMILY='arch' ;;
        *)
            case " ${ID_LIKE:-} " in
                *' ubuntu '*) DISTRO_FAMILY='debian' ;;
                *' arch '*) DISTRO_FAMILY='arch' ;;
                *' rhel '* | *' centos '*) ;;
                *' fedora '*) DISTRO_FAMILY='fedora' ;;
            esac
            ;;
    esac

    [[ -n "$DISTRO_FAMILY" ]] ||
        die "Distribucion no soportada: ID=$DISTRO_ID ID_LIKE=${ID_LIKE:-}. Soportadas: Ubuntu (y derivadas), Linux Mint, Fedora y Arch (y derivadas)."

    if [[ "$DISTRO_FAMILY" == debian ]]; then
        UBUNTU_BASE_CODENAME="${UBUNTU_CODENAME:-}"
        UBUNTU_BASE_RELEASE=''
        if [[ -r /etc/upstream-release/lsb-release ]]; then
            # Linux Mint y otras derivadas declaran aca su base de Ubuntu.
            UBUNTU_BASE_RELEASE="$(awk -F= '$1 == "DISTRIB_RELEASE" { gsub(/"/, "", $2); print $2; exit }' \
                /etc/upstream-release/lsb-release)"
            if [[ -z "$UBUNTU_BASE_CODENAME" ]]; then
                UBUNTU_BASE_CODENAME="$(awk -F= '$1 == "DISTRIB_CODENAME" { gsub(/"/, "", $2); print $2; exit }' \
                    /etc/upstream-release/lsb-release)"
            fi
        elif [[ "$DISTRO_ID" == ubuntu ]]; then
            UBUNTU_BASE_RELEASE="${VERSION_ID:-}"
            UBUNTU_BASE_CODENAME="${UBUNTU_BASE_CODENAME:-${VERSION_CODENAME:-}}"
        elif [[ -n "$UBUNTU_BASE_CODENAME" ]] && command -v ubuntu-distro-info >/dev/null 2>&1; then
            UBUNTU_BASE_RELEASE="$(ubuntu-distro-info --series="$UBUNTU_BASE_CODENAME" -r | awk '{ print $1 }')"
        fi
        [[ -n "$UBUNTU_BASE_RELEASE" && -n "$UBUNTU_BASE_CODENAME" ]] ||
            die "No se pudo determinar la version base de Ubuntu de $DISTRO_NAME."
    fi
}
