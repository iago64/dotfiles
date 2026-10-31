# shellcheck shell=bash
# Adaptador para Fedora (DNF).

adapter_refresh() {
    : # dnf refresca los metadatos por su cuenta.
}

adapter_upgrade() {
    sudo dnf upgrade -y --refresh
}

adapter_install() {
    sudo dnf install -y "$@"
}

adapter_prepare() {
    case "$1" in
        vscode) fedora_prepare_vscode ;;
        apps) fedora_enable_rpmfusion ;;
        *) : ;;
    esac
}

fedora_prepare_vscode() {
    [[ -f /etc/yum.repos.d/vscode.repo ]] && return 0
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
}

# RPM Fusion free y nonfree: Discord y los codecs completos de OBS/VLC.
fedora_enable_rpmfusion() {
    local version
    local -a missing=()
    version="$(rpm -E %fedora)"
    rpm -q rpmfusion-free-release >/dev/null 2>&1 ||
        missing+=("https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${version}.noarch.rpm")
    rpm -q rpmfusion-nonfree-release >/dev/null 2>&1 ||
        missing+=("https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${version}.noarch.rpm")
    if ((${#missing[@]} > 0)); then
        sudo dnf install -y "${missing[@]}"
    fi
}
