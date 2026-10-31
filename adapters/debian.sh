# shellcheck shell=bash
# Adaptador para Ubuntu, Linux Mint y derivadas de Ubuntu (APT).

APT_OPTS=(-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

apt_get() {
    sudo env DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

adapter_refresh() {
    apt_get update
}

adapter_upgrade() {
    apt_get "${APT_OPTS[@]}" upgrade
}

adapter_install() {
    apt_get "${APT_OPTS[@]}" install "$@"
}

# El paquete tiene una version instalable en los repos configurados.
apt_has_candidate() {
    local candidate
    candidate="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ { print $2; exit }')"
    [[ -n "$candidate" && "$candidate" != '(none)' ]]
}

# Repos que necesita cada tema antes de instalar sus paquetes.
adapter_prepare() {
    case "$1" in
        base) debian_prepare_base ;;
        dotnet) debian_prepare_dotnet ;;
        vscode) debian_prepare_vscode ;;
        *) : ;;
    esac
}

# fastfetch no esta en los repos de Ubuntu 24.04: se usa la PPA oficial del proyecto.
debian_prepare_base() {
    apt_has_candidate fastfetch && return 0
    log_info 'fastfetch no esta en los repos de la distro; se agrega ppa:zhangsongcui3371/fastfetch.'
    if ! command -v add-apt-repository >/dev/null 2>&1; then
        adapter_install software-properties-common
    fi
    if sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch; then
        apt_get update
    else
        log_warn 'No se pudo agregar la PPA de fastfetch; se intentara seguir sin ella.'
    fi
}

# El repo de Microsoft publica tambien paquetes que pisan a los de Ubuntu
# (por ejemplo containernetworking-plugins). Este pin solo deja entrar .NET y
# VS Code desde ese origen e ignora los .NET de Ubuntu para no mezclar feeds.
debian_write_microsoft_pin() {
    sudo install -m 0755 -d /etc/apt/preferences.d
    sudo tee /etc/apt/preferences.d/dotfiles-microsoft.pref >/dev/null <<'EOF'
# Gestionado por dotfiles (adapters/debian.sh).
Package: dotnet* aspnetcore* netstandard* code
Pin: origin "packages.microsoft.com"
Pin-Priority: 500

Package: dotnet* aspnetcore* netstandard*
Pin: release o=Ubuntu
Pin-Priority: -10

Package: *
Pin: origin "packages.microsoft.com"
Pin-Priority: 1
EOF
}

# Vuelve a la version de Ubuntu los paquetes que el repo de Microsoft ya piso
# antes de existir el pin.
debian_restore_shadowed_packages() {
    local -a lists=(/var/lib/apt/lists/packages.microsoft.com_*_Packages)
    [[ -e "${lists[0]}" ]] || return 0

    local pkg status installed candidate
    while IFS= read -r pkg; do
        case "$pkg" in
            dotnet* | aspnetcore* | netstandard* | code* | packages-microsoft-prod) continue ;;
        esac
        read -r status installed < <(dpkg-query -W -f='${db:Status-Status} ${Version}\n' "$pkg" 2>/dev/null) || continue
        [[ "$status" == installed ]] || continue
        apt-cache madison "$pkg" | grep -F "| $installed |" | grep -q 'packages.microsoft.com' || continue
        candidate="$(apt-cache policy "$pkg" | awk '/Candidate:/ { print $2; exit }')"
        [[ -n "$candidate" && "$candidate" != '(none)' && "$candidate" != "$installed" ]] || continue
        log_info "Restaurando $pkg $candidate de Ubuntu (estaba $installed de Microsoft)."
        apt_get "${APT_OPTS[@]}" install --allow-downgrades "$pkg=$candidate"
    done < <(comm -12 \
        <(awk '/^Package: / { print $2 }' "${lists[@]}" | sort -u) \
        <(dpkg-query -W -f='${Package}\n' | sort -u))
}

debian_prepare_dotnet() {
    debian_write_microsoft_pin
    if ! dpkg-query -W -f='${db:Status-Status}' packages-microsoft-prod 2>/dev/null | grep -qx installed; then
        local deb
        deb="$(mktemp --suffix=.deb)"
        download "https://packages.microsoft.com/config/ubuntu/${UBUNTU_BASE_RELEASE}/packages-microsoft-prod.deb" "$deb"
        sudo dpkg -i "$deb"
        rm -f -- "$deb"
    fi
    apt_get update
    debian_restore_shadowed_packages
}

debian_prepare_vscode() {
    debian_write_microsoft_pin
    # Si ya hay una fuente para el repo de VS Code (la agrega tambien el propio
    # paquete "code"), no se duplica: APT falla con Signed-By distintos.
    if ! grep -rqs 'packages.microsoft.com/repos/code' /etc/apt/sources.list.d/; then
        sudo install -m 0755 -d /etc/apt/keyrings
        download https://packages.microsoft.com/keys/microsoft.asc |
            gpg --dearmor |
            sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
        sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
        printf 'deb [arch=%s signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\n' \
            "$(dpkg --print-architecture)" |
            sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    fi
    apt_get update
}
