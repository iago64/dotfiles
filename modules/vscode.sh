# shellcheck shell=bash
# Visual Studio Code desde el repo oficial (apt/rpm) o AUR en Arch.

module_main() {
    adapter_prepare vscode
    pkg_install_module vscode

    if command -v snap >/dev/null 2>&1 && snap list code >/dev/null 2>&1; then
        log_warn 'Hay un VS Code de snap ademas del instalado ahora. Para quitarlo: sudo snap remove code'
    fi
}
