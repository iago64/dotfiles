# shellcheck shell=bash
# Herramientas base de linea de comandos.

module_main() {
    adapter_prepare base
    pkg_install_module base
    # sshd queda instalado pero apagado; para usarlo: sudo systemctl enable --now sshd
}
