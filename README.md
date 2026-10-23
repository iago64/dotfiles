# Dotfiles

Repositorio para instalar herramientas y enlazar configuraciones personales en Linux.

## Uso

```bash
./install.sh
```

El instalador detecta la distribucion desde `/etc/os-release`, ejecuta el script
de `distros/` correspondiente (incluido `mint.sh` para Linux Mint) y despues
enlaza el contenido de `common/` en `$HOME`. Si un destino ya existe y no es el
enlace correcto, se conserva como una copia con sufijo `.backup-<fecha>-<pid>`
antes de crear el enlace.

Los scripts de instalacion necesitan `sudo` y pueden instalar herramientas de
terceros. Revise el script de su distribucion antes de ejecutarlo. Las acciones
opcionales no se ejecutan automaticamente:

- `distros/ubuntu-network-manager.sh` reemplaza la configuracion de Netplan
  para usar NetworkManager y reinicia el servicio.
- `distros/arch-hyprland.sh` instala Hyprland y el paquete ML4W desde AUR.

Los repositorios originales no contenian archivos de configuracion personales
para copiar. Agregue los archivos compartidos a `common/` (por ejemplo,
`common/.bashrc` o `common/.config/nombre-app/`) y vuelva a ejecutar el
instalador para enlazarlos.
