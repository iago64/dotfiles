# shellcheck shell=bash
# Podman como unico motor de contenedores.

module_main() {
    pkg_install_module containers

    # El socket permite usar herramientas que esperan la API de Docker.
    if has_user_session_bus; then
        systemctl --user enable --now podman.socket
    else
        log_warn 'No hay sesion systemd de usuario (SSH, su o contenedor).'
        log_warn 'Cuando inicies sesion grafica: systemctl --user enable --now podman.socket'
    fi

    if command -v dockerd >/dev/null 2>&1; then
        log_warn 'Docker Engine sigue instalado de ejecuciones anteriores; el instalador ya no lo gestiona.'
        log_warn 'Si no lo usas: sudo systemctl disable --now docker y desinstala docker-ce.'
    fi
}
