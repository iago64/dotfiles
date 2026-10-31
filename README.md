# Dotfiles

Prepara el mismo entorno de trabajo en **Ubuntu (y derivadas), Linux Mint,
Fedora y Arch (y derivadas)**: mismas herramientas, mismas versiones de los
runtimes y la misma configuracion personal. Debian puro y la familia RHEL
(RHEL, Rocky, Alma, CentOS) no estan soportados y el instalador los rechaza.

## Uso rapido

```bash
git clone https://github.com/iago64/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh          # instala todo
./verify.sh           # comprueba que no falte nada
```

Ejecutalo con tu usuario, no como root: pide `sudo` una vez y mantiene la
sesion mientras dura la instalacion. Al terminar, cerra sesion y volve a
entrar para usar zsh.

Opciones de `install.sh`:

| Opcion | Efecto |
| --- | --- |
| `--no-upgrade` | No actualiza el sistema antes de instalar. |
| `--cli` | Omite los modulos graficos (`desktop`, `vscode`, `apps`, `jetbrains`). |
| `--only m1,m2` | Ejecuta solo esos modulos. |
| `--skip m1,m2` | Omite esos modulos. |
| `--dry-run` | Muestra que se instalaria en esta distro, sin cambiar nada. |

Se puede volver a ejecutar las veces que haga falta: cada modulo detecta lo
que ya esta hecho. Si un modulo falla, los demas siguen y al final se indica
cuales fallaron y como reintentarlos (`./install.sh --only ...`). El log de
cada ejecucion queda en `~/.local/state/dotfiles/`.

## Que se instala

| Modulo | Contenido | Como |
| --- | --- | --- |
| `base` | git, curl, wget, jq, zip/unzip, tree, htop, fastfetch, vim, nano, strace, net-tools, xclip, gnupg, cliente y servidor SSH (sshd queda apagado) | Gestor de paquetes. En Ubuntu 24.04 fastfetch viene de la PPA oficial del proyecto. aptitude solo en Ubuntu/Mint. |
| `toolchain` | gcc/g++, make, cmake, autotools, gdb, valgrind, CUnit, Python 3 + pip | Gestor de paquetes |
| `desktop` | Terminator, Meld, GHex | Gestor de paquetes |
| `containers` | Podman y podman-compose (unico motor de contenedores) | Gestor de paquetes |
| `dotnet` | .NET SDK 10 | Repos nativos en Fedora y Arch; repo de Microsoft en Ubuntu/Mint con un pin de APT que solo deja entrar .NET y VS Code |
| `java` | Java 21 y 25 (Amazon Corretto, ultima build), Gradle y Quarkus | SDKMAN |
| `node` | Node.js 24 y pnpm | nvm + corepack |
| `vscode` | Visual Studio Code | Repo oficial de Microsoft (apt/rpm); AUR en Arch |
| `apps` | Discord, OBS, VLC, Bruno, Bitwarden | Paquete nativo si existe; si no, Flatpak (Flathub). En Fedora habilita RPM Fusion y cambia ffmpeg-free por ffmpeg. |
| `jetbrains` | JetBrains Toolbox | Descarga oficial en `/opt/jetbrains-toolbox`; despues se actualiza solo |
| `zsh` | Zsh, Oh My Zsh, zsh-autosuggestions y zsh-syntax-highlighting, como shell por defecto | Gestor de paquetes + git |
| `dotfiles` | Enlaces de `common/` en `$HOME` | Ver abajo |

Las versiones se definen una sola vez en `versions.env` (Node, Java, .NET,
nvm) y los nombres de paquete por distro en `packages.txt`.

## Estructura

```text
install.sh          orquestador: opciones, deteccion, log y ejecucion de modulos
verify.sh           comprueba el entorno e imprime herramienta -> version
versions.env        versiones de los runtimes
packages.txt        manifiesto de paquetes: nombre en apt, dnf, pacman y Flatpak
lib/                funciones compartidas (log, deteccion de distro, paquetes)
adapters/           una por familia: debian (Ubuntu/Mint), fedora, arch
modules/            un archivo por modulo, en el orden de install.sh
common/             configuracion personal que se enlaza en $HOME
ci/                 preparacion de contenedores para el CI
.github/workflows/  CI: shellcheck, shfmt e instalacion en las cuatro distros
```

## Agregar o cambiar una herramienta

- **Un paquete del sistema:** agrega una fila en `packages.txt` con el nombre
  en cada gestor. Usa `-` donde no exista; en Arch, `aur:<paquete>` lo instala
  desde AUR. Para una app de escritorio (modulo `apps`) completa tambien la
  columna Flatpak, que se usa cuando no hay paquete nativo.
- **Una version de runtime:** cambia `versions.env`.
- **Algo que no es un paquete:** crea `modules/<nombre>.sh` con una funcion
  `module_main`, agregalo a `ALL_MODULES` (y a `MODULE_DESC`) en `install.sh`
  y suma su comprobacion en `verify.sh`.

Despues, `./install.sh --dry-run` muestra como se resuelve en tu distro.

## Configuracion personal (`common/`)

Todo lo que esta en `common/` se refleja en `$HOME`: los archivos se enlazan
simbolicamente y los directorios se crean, sin tocar lo demas que ya haya en,
por ejemplo, `~/.config`. Si algo choca, se mueve a un respaldo
`<archivo>.backup-<fecha>` antes de enlazar.

| Archivo | Uso |
| --- | --- |
| `.zshrc` | Oh My Zsh, plugins, historial. Ajustes de una maquina: `~/.zshrc.local`. |
| `.config/dotfiles/env.sh` | Entorno compartido por bash y zsh: nvm, pnpm, SDKMAN y .NET. A `~/.bashrc` solo se le agrega una linea que lo carga. |
| `.gitconfig` | Identidad, alias, meld como herramienta de merge/diff. Ajustes de una maquina: `~/.gitconfig.local`. |
| `.config/terminator/config` | Fuente, colores y scroll infinito. |
| `.config/Code/User/` | `settings.json` y `keybindings.json` de VS Code. |

Como son enlaces, los cambios que hagas desde las aplicaciones (por ejemplo
en la configuracion de VS Code) quedan en el repo y se pueden commitear.

## Verificacion y CI

`./verify.sh` (o `./verify.sh --cli` sin las herramientas graficas) lista cada
herramienta con su version y termina con error si falta algo. La salida
deberia ser la misma en cualquier distro.

El workflow de GitHub Actions pasa `shellcheck` y `shfmt` y, en contenedores
de Ubuntu 24.04, Linux Mint 22, Fedora y Arch, ejecuta `install.sh --cli` dos
veces (para comprobar que es idempotente) y despues `verify.sh --cli`.

## Notas para maquinas ya instaladas con la version anterior

El instalador no desinstala nada; avisa lo que quedo de antes:

- **Docker Engine** ya no se instala (solo Podman). Si no lo usas:
  `sudo systemctl disable --now docker` y desinstala `docker-ce`.
- **Snaps** de Discord, OBS, VLC y VS Code en Ubuntu, y el **.deb de Discord**
  en Mint, quedan duplicados con las versiones nuevas: `sudo snap remove ...`
  o `sudo apt remove discord`.
- Las carpetas versionadas `/opt/jetbrains-toolbox-*` de la version anterior
  se pueden borrar.
- Emacs, RetroArch y blueman ya no forman parte del entorno.
- Si el repo de Microsoft habia reemplazado paquetes de Ubuntu (por ejemplo
  `containernetworking-plugins`), el modulo `dotnet` los vuelve a la version
  de Ubuntu.

Si clonas el repo en Windows, `.gitattributes` fuerza finales de linea LF
para que los scripts funcionen al copiarlos a Linux.
