# Máquina Virtual Ubuntu Desktop 22.04 como servidor Asterisk

- [Máquina Virtual Ubuntu Desktop 22.04 como servidor Asterisk](#máquina-virtual-ubuntu-desktop-2204-como-servidor-asterisk)
  - [NOTAS](#notas)
  - [Creación de Máquina Virtual](#creación-de-máquina-virtual)
    - [Preparación del Sistema](#preparación-del-sistema)
    - [Importación de la Máquina Virtual](#importación-de-la-máquina-virtual)
  - [Configuración SETESUR](#configuración-setesur)
    - [1. Administración de usuarios](#1-administración-de-usuarios)
      - [1.1 Creación de usuarios](#11-creación-de-usuarios)
      - [1.2 Definir sesión x11 (no Wayland)](#12-definir-sesión-x11-no-wayland)
      - [1.3 Configuración del escritorio](#13-configuración-del-escritorio)
    - [2. Instalaciones importantes](#2-instalaciones-importantes)
      - [2.1 Gestor de Contraseñas *KeePassXC*](#21-gestor-de-contraseñas-keepassxc)
      - [2.2 Implementación de Portainer para admon. Docker](#22-implementación-de-portainer-para-admon-docker)
  - [Implementación de Asterisk PBX](#implementación-de-asterisk-pbx)
    - [3.1 Asignación de IP fija](#31-asignación-de-ip-fija)
    - [3.2 Instalación y configuración de Asterisk](#32-instalación-y-configuración-de-asterisk)

## NOTAS

1. Mi **versión** de VirtualBox es la 7.0.10. Tener en cuenta la versión utilizada en la ofi de SETESUR para prevenir incompatibilidades.
2. Yo recomendaría tener una **partición** dedicada a almacenar las máquinas virtuales. Esto evita saturar la partición del sistema operativo en caso de tener varias máquinas o hacer muchas instantáneas. ~~Además las máquinas Windows suelen pesar mucho más que las Linux.~~
3. Recomiendo tomar **instantáneas** en VirtualBox antes y después de realizar procesos de instalación/configuración importantes. Así si algo sale mal es fácil restaurar la máquina, lo que da pie a preparar script mediante *ensayo y error* para automatizar procesos en el futuro.


<!-- ```md
## Setesur Custom
- **Login > Ubuntu on Xorg**
- **Language**
- ~~**useradd**~~
- anydesk
- ~~keepassxc~~
- ~~wireshark~~
- **docker**
``` -->


## Creación de Máquina Virtual

### Preparación del Sistema

> Partimos de una VM de 2023, configurada con [DebUbu-base.sh](https://github.com/pabloqpacin/dotfiles/blob/main/scripts/autosetup/DebUbu-base.sh), que actualizamos a finales de abril de 2024...

<details>
<summary>Detalles (no es importante)</summary>

- Base bs

```bash
go_pkgs=('fzf' 'lf')
cargo_pkgs=('bat' 'btm' 'eza' 'delta')

for pkg in ${go_pkgs[@]}; do
    sudo mv $HOME/go/bin/$pkg /usr/bin
done
for pkg in ${cargo_pkgs[@]}; do
    sudo mv $HOME/.cargo/bin/$pkg /usr/bin
done
```

- node/npm bs

```bash
if dpkg -l | grep -q 'nodejs'; then
    sudo apt autoremove -y nodejs
fi

if ! command -v npm &>/dev/null; then
    if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    fi
    if ! command -v node &>/dev/null && ! command -v npm &>/dev/null; then
        [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
        nvm install node
    fi
fi
```

- Base bs, pull dotfiles && nvim>bashls

```bash
agi jq net-tools tree vim
cd dotfiles && git pull
# nvim: exec PackerSync
```

- root bs

```bash
sudo mkdir /root/.config
sudo ln -s ~/dotfiles/.config/lf /root/.config
sudo ln -s ~/dotfiles/.config/bat /root/.config
sudo ln -s ~/dotfiles/.config/bottom /root/.config
sudo ln -s ~/dotfiles/.vimrc /root/
echo "alias tree='tree -aC'" | sudo tee -a /root/.bashrc
```

- Instalamos AnyDesk

```bash
if ! command -v anydesk &>/dev/null && ! flatpak list 2>/dev/null | grep -q 'anydesk'; then
    wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/anydesk-archive-keyring.gpg
    echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
    sudo apt update && sudo apt install -y anydesk
    sudo systemctl disable anydesk
fi
```

- **Cambiamos Wayland por x11 (Anydesk no funciona en Wayland)**

```yaml
Pantalla de login: Sesion: 'Ubuntu on Xorg'
```

> Snapshot: `Custom_Base`

- **EXPORTAMOS .OVA**

```yaml
VirtualBox:
  UbuntuDesk-22.04-Asterisk:
    Click derecho: Export to OCI...:
      Format settings:
        - Format: Open Virtualization Format 0.9
        - File: /home/pabloqpacin/Documents/UbuntuDesk-22.04-Asterisk.ova
        - MAC Addrses Policy: Strip all network adapter MAC addresses
        - Write Manifest file: yes

```

</details>

Ahora mismo, aparte de `root`, solo existe el usuario `pabloqpacin` (con contraseña `changeme`). La idea es crear otros usuarios para SETESUR lo antes posible.

### Importación de la Máquina Virtual

A fecha de 30 de abril de 2024, he subido la OVA a una carpeta compartida en el Drive. Pesa unos 13GB. Solo hay que descargarla en un equipo que tenga VirtualBox instalado.

```yaml
Explorador de archivos:
  UbuntuDesk-22.04-Asterisk.ova:
    Click derecho: Open with VirtualBox
      Settings:
        - Machine Base Folder: ...          # donde se almacena la MV...
        - MAC Address Policy: Generate new MAC addresses for all network adapters
        - Import hard drives as VDI: yes
```

Configuración impotrante en VirtualBox:

```yaml
General: Advanced:
    Shared Clipboard: Bidirectional
Audio:
    Enable Audio Input: yes
Network: Adapter 1:
    Attached to: Bridged Adapter
    # Name: enp4s0;  # MAC Address: '08:00:27:66:99:57'
```

---

## Configuración SETESUR

### 1. Administración de usuarios

#### 1.1 Creación de usuarios

Hemos preparado el script [skel_useradd.sh](/scripts/skel_useradd.sh), que creará el usuario `setesur` con la contraseña `prueba1234`. Para ejecutarlo se puede clonar el repo o directamente descargar el script y ejecutarlo:

```bash
# 1. Clonamos el repositorio y ejecutamos el script
git clone --depth 1 https://github.com/pabloqpacin/lab_asterisk.git $HOME/lab_asterisk
bash $HOME/lab_asterisk/scripts/skel_useradd.sh

# 2. Descagar el script directamente y lo ejecutamos
wget -qlO $HOME/skel_useradd.sh https://github.com/pabloqpacin/lab_asterisk/raw/main/scripts/skel_useradd.sh
bash $HOME/skel_useradd.sh
```

Es posible modificar el script para crear más usuarios. Solo hay que descomentar estas líneas o escribir nuevas:

```bash
declare -A users
users=(
    # ["josu"]="prueba12"         # tiene que ser de 8 o más chars
    # ["prueba"]="changeme"       # no puede coincidir name y pass
    ["setesur"]="prueba1234"
    # ["pablo.quevedo"]="changeme"
)
```

#### 1.2 Definir sesión x11 (no Wayland)

Para iniciar sesión en el Escritorio hay que introducir nombre de usuario y contraseña en una pantalla de login. Pues para que Anydesk funcione es vital seleccionar la opción `Ubuntu on Xorg` en esa pantalla de login.

![001-login_sesion_xorg.png](/img/mv_ubuntu/001-login_sesion_xorg.png)

#### 1.3 Configuración del escritorio

Básicamente...

```yaml
Configuración:
  Apariencia: Estilo: Oscuro
  Escritorio de Ubuntu:
    Dock:
      - Ocultar automáticamente: si
      - Tamaño de icono: 24

Dock:
    1: Alacritty
    2: Brave Web Browser
    3: VSCodium
    ...: ...
```

---

### 2. Instalaciones importantes

#### 2.1 Gestor de Contraseñas *KeePassXC*

Instalación de KeePassXC

```bash
if ! command -v keepassxc &>/dev/null; then
    sudo apt update && sudo apt install -y keepassxc
    mkdir ~/KeePassXC
fi
```
<!-- ```bash
# yes 'changeme' | head -n 2 | keepassxc-cli db-create ~/KeePassXC/example.kdbx -p
# keepassxc-cli add -u pablo.quevedo@setesur.com ~/KeePassXC/Passwords.kdbx GoogleWorkspace -p
# xdg-open https://keepassxc.org/docs/KeePassXC_UserGuide#_setup_browser_integration
``` -->

Creación de base de datos (en general, todo por defecto) y se añade entrada para *Portainer*:

```yaml
KeePassXC:
  Crear una base de datos nueva:
    Información general:
      - Nombre de la base de datos: Contraseñas
      - Descripción: 'Test en UbuntuDesk-22.04-Asterisk'
    # Configuraciones de cifrado:
    #   - Tiempo de descifrado: 1.0s
    #   - Formato de base de datos: KDBX 4.0 (recomendado)
    #   # - Configuración avanzada: ...
    Credenciales de base de datos:
        - Contraseña: changeme
        - Confirmar contraseña: changeme
        # - Clave: ...
    Guardar en: ~/KeePassXC/Contraseñas.kdbx

  Abrir base de datos existente:  
    Contraseñas:
        Raíz: Añadir un nuevo apunte:
            - Título: portainer
            - Usuario: admin
            - Contraseña: VRc{53~:Q8XA]|WunEld
            - URL: https://localhost:9443
```

#### 2.2 Implementación de Portainer para admon. Docker

Docker ya debería estar instalado. Para poder interactuar con Docker, el usuario debe pertenecer al grupo `sudo` o al grupo `docker`.

Según la [documentación de Docker Desktop](https://docs.docker.com/desktop/install/linux-install/): "*Docker Desktop en Linux ejecuta una máquina virtual (VM) que crea y utiliza un contexto Docker personalizado, `desktop-linux`, en el arranque.*". En nuestro caso, como el sistema Ubuntu ya está en una máquina virtual, se plantea la situación de **virtualización anidada**, algo bastante problemático y y cuya resolución en Windows suele dar lugar a incompatibilidades entre VirtualBox, WSL, Hyper-V y otras tecnologías de virtualización. ¿Conclusión? <u>No usaremos Docker Desktop</u>.

En cambio, sí que podemos usar **Portainer** para administrar nuestro entorno Docker de forma gráfica. Podrá administrarlo cualquier usuario en tanto que pueda loguearse como usuario `admin` en Portainer.

Con los siguientes comandos se instala y se accede al panel de administración (en `https://localhost:9443`) para establecer una nueva contraseña (que en este caso hemos creado previamente con KeePassXC).


```bash
# portainer
install_portainer(){
    if ! docker ps -a --format '{{.Names}}' | grep -q "portainer"; then
        docker run -d --name portainer --restart=always -p 8008:8000 -p 9443:9443  \
            -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
            portainer/portainer-ce:latest
    fi
}
init(){
    sleep 2
    xdg-open https://localhost:9443 &>/dev/null
    # email & password == admin & passwordbymanager
    # TODO: SSL cert
}
# ---
install_portainer
init
# ---
# docker-desktop:
#   - peligro: virtualización anidada
#   - https://docs.docker.com/desktop/install/linux-install/
```

Igualmente, recomendamos aprender algunos comandos esenciales de Docker, destacando `docker ps`. También recomendamos emplear [aliases](https://github.com/pabloqpacin/dotfiles/blob/main/zsh/plugins/pqp-docker-k8s/pqp-docker-k8s.plugin.zsh) para aumentar la productividad...

---

## Implementación de Asterisk PBX

En este punto debemos tomar una instantánea para poder restaurar el sistema con facilidad.

### 3.1 Asignación de IP fija

Como la máquina virtual va a funcionar como servidor de telefonía VoIP en nuestra red local de SETESUR, recomendamos asignarle una dirección IP fija a la máquina. Recordamos que la interfaz de red de la máquina en VirtualBox debe ser configurada como **puente**.

Los siguientes comandos harán que la máquina solicite la IP `192.168.1.205`. Habría que cambiarlo por `x.x.20.x` o cualquier otra subred oportuna (https://drive.google.com/drive/folders/1JncxM5iQ8sK1NHHOF-qRsPBwniL5-qR1).

```bash
sudo mv /etc/netplan/01-network-manager-all.yaml{,.bak}

cat<<EOF | sudo tee /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3: # Change enp0s3 to your actual interface name
      dhcp4: no
      addresses: [192.168.1.205/24] # Set your desired static IP address and subnet mask
      gateway4: 192.168.1.1 # Set your gateway IP address
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4] # Set your DNS server addresses
EOF

sudo netplan try
```

### 3.2 Instalación y configuración de Asterisk

A partir de aquí, seguir la documentación específica de Asterisk: [docs/asterisk.md](/docs/asterisk.md)
