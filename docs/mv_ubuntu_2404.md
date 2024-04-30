# Máquina Virtual Ubuntu Desktop 24.04 como servidor Asterisk

> OJO: a fecha de abril de 2024, Ubuntu 24.04 en Máquina Virtual no funciona bien con x11 y como Anydesk no funciona en Wayland decidimos usar Ubuntu 22.04. Este documento NO .

- [Máquina Virtual Ubuntu Desktop 24.04 como servidor Asterisk](#máquina-virtual-ubuntu-desktop-2404-como-servidor-asterisk)
  - [NOTAS](#notas)
    - [objetivos](#objetivos)
    - [comentarios](#comentarios)
    - [documentación](#documentación)
  - [Parte 1: creación de máquina, instalación del sistema, configuración del escritorio](#parte-1-creación-de-máquina-instalación-del-sistema-configuración-del-escritorio)
    - [Creación de máquina virtual `UbuntuDesk-24.04-Asterisk` en VirtualBox](#creación-de-máquina-virtual-ubuntudesk-2404-asterisk-en-virtualbox)
    - [Instalación de Ubuntu](#instalación-de-ubuntu)
    - [Configuración del Escritorio (1)](#configuración-del-escritorio-1)
    - [Actualización inicial y primera instantántea `Fresh Install`](#actualización-inicial-y-primera-instantántea-fresh-install)
  - [Parte 2: instalación de programas de terminal y de escritorio (todo automatizado)](#parte-2-instalación-de-programas-de-terminal-y-de-escritorio-todo-automatizado)
    - [Script `ubuntu-base.sh`](#script-ubuntu-basesh)
    - [Configuración del Escritorio (2)](#configuración-del-escritorio-2)
  - [Parte 3: Docker, en general](#parte-3-docker-en-general)
  - [Parte 4: servidor Asterisk PBX (+ clientes Zoiper)](#parte-4-servidor-asterisk-pbx--clientes-zoiper)
  - [PENDIENTE](#pendiente)
    - [Nuevo usuario `prueba` (sin privilegios `sudo`)](#nuevo-usuario-prueba-sin-privilegios-sudo)



```md
# OBJETIVOS
- creación vm + movidas virtualbox
- cambiar wayland por x11 (por Anydesk)
- base.sh && users.sh
- asterisk.md
```


## NOTAS

### objetivos

- [ ] tener en cuenta conexiones con vscode/github, mobaxterm, putty...


### comentarios

- En general vamos a <u>evitar los **snaps**</u>. <!--ojo en la app Software, lo que pone de que los snaps se actualizan automáticamente a diario sí o sí...-->
<!-- - A ver... A la máquina virtual (vm) le ponemos **red puente** para que esté como una sistema más en la red local, como cualquier otro dispositivo|ordenador|equipo de trabajo. ¿La principal ventaja para mí? Poder conectarme desde mi terminal en mi anfitrión para configurar cosas. Esto es importante para mí porque a ver, aunque las vms funcionan bien pues hay una latencia con las ventanas y cosas así; no es una experiencia nativa y se nota, sin más. Entonces yo me conecto con `ssh` y pista. ~~En fin, está bien que sea un Ubuntu Desktop para tocar las cosas y hacerlo más ameno PERO si el objetivo de la máquina es dar servicio de telefonía VoIP es mejor que sea un server *headless*, purita terminal -- y por supuesto que disfruteis de la experiencia Linux en algún ordenador medio viejuno que tengáis por ahí, alguno que no sea capaz de cumplir con las exigencias de Windows y a los que Linux pueda darles vida de nueva.~~ -->
<!-- - Yo me conecto a la vm con un simple `ssh` desde mi terminal el anfitrión. En general, vamos a preferir establecer conexiones remotas mediante **SSH**. Este sistema Ubuntu es Linux, lo que significa que la interfaz de comandos es **BASH**. En nuestro caso, **ZSH** con algunos plugins para mejorar la experiencia en la terminal.<br> -->


### documentación

- Sobre la **instalación automatizada**
  - @canonical-subiquity.readthedocs-hosted.com: [Autoinstall configuration reference manual](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
  - @canonical-subiquity.readthedocs-hosted.com: [Autoinstall schema (validation)](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-schema.html)
- Problemas de AnyDesk con [Wayland](https://es.wikipedia.org/wiki/Wayland_(protocolo)) (sesión gráfica default en 24.04):
  - foo

<!-- ## Manual Paso a Paso -->
## Parte 1: creación de máquina, instalación del sistema, configuración del escritorio

### Creación de máquina virtual `UbuntuDesk-24.04-Asterisk` en VirtualBox

<!-- ### Creación de vm en VirtualBox -->

Con el navegador web navegamos a https://ubuntu.com/download/desktop y clickamos en el botón *Download 24.04 LTS (6GB)*. Se descargará el archivo `ubuntu-24.04-desktop-amd64.iso`.

Abrimos VirtualBox y creamos una nueva máquina virtual con estas especificaciones:


```yaml
Name and Operating System:
    Name: UbuntuDesk-24.04-Asterisk
    ISO Image: ../ubuntu-24.04-desktop-amd64.iso
Hardware:
    Base Memory: 4096MB
    Processors: 4CPUs
    Enable EFI: yes
Hard Disk: 50GB VDI
```

Antes de encenderla, nos vamos a las opciones y configuramos estas características:

```yaml
General: Advanced:
    Shared Clipboard: Bidirectional
# Display:                                                                          # for Wayland in my PopOS host...
#     Enable 3D Acceleration: yes                                                   # for Wayland in my PopOS host...
Audio:
    Enable Audio Input: yes
Network: Adapter 1:
    Attached to: Bridged Adapter
    # Name: enp4s0;  # MAC Address: '08:00:27:66:99:57'
```

Ya podemos encender la máquina.

### Instalación de Ubuntu 

> Esto solo lo haremos "1 vez", ya que en el futuro podremos clonar la vm

En VirtualBox pinchamos en Start y se abre la pantalla con el gestor de arranque de Ubuntu. Como es una sesión en vivo, que Ubuntu no está instalado todavía, introducimos la primera opción y completamos el Asistente de instalación de esta manera:

```yaml
Try or Install Ubuntu:

    Choose your language: Español
    Accesibilidad: Siguiente
    Disposicion del teclado: Español
    Conectarse a una red: 'Utilizar conexión por cable'
    Probar o instalar Ubuntu: Instalar

    Tipo de instalacion: interactiva                                            # TODO: try
    Aplicaciones: Selección ampliada                                            # TODO: list
    Optimizar el equipo:                                                        # No hacen daño; habrá que ver qué hace falta en función del HOST
        Instalar software de terceros: si
        Instalar compatibilidad formatos multimedia: si
    Configuracion del disco: 'Borrar disco e instalar Ubuntu'                   # TODO: LVM
    Cuenta:
        - Nombre: SETESUR
        - Nombre del equipo: asterisk
        - Nombre de usuario: setesur
        - Contraseña: changeme                                                  # TODO: password manager
        # NOTE: luego añadiremos el usuario PRUEBA
        - Solicitar contraseña para acceder: si
        - Utilizar Active Directory: no                                         # TODO: ojo
    Huso horario:
        - Ubicacion: Madrid (Madrid, Spain)
        - Huso horario: Europe/Madrid
```

Esas han sido nuestras opciones y este es el resumen que aparece junto con el botón Confirmar.

```yaml
RESUMEN:
    General:
        Configuracion del disco: Borrar disco e instalar Ubuntu
        Disco de instalacion: VBOX HARDDISK sda
        Aplicaciones: Selección ampliada
    Seguridad y mas:
        Cifrado del disco: Ninguna
        Software propietario: Códecs y controladores
    Particiones:
        - partición sda1 formateada como fat32 utilizada para /boot/efi
        - partición sda2 formateada como ext4 utilizada para /
```

El Asistente completará la instalación en unos minutos. Seleccionamos la opción de reiniciar.

Saldrá una última pantalla con el mensaje "Please remove the installation medium, then press ENTER". Podemos pulsar Enter directamente (VirtualBox "extrae" el CD virtual con la ISO por nosotros).


### Configuración del Escritorio (1)

Iniciamos sesión con el usuario `setesur` y la contraseña establecida anteriormente.

Aparecen unos menús de Bienvenida:

```yaml
Bienvenida a Ubuntu 24.04 LTS:
    Enable ubuntu Pro: Skip for now
    Compartir datos del sistema: no
    Abrir el Centro de aplicaciones: no
```

Con eso hecho, abrimos la aplicación Configuración:

```yaml
Configuracion:
    Apariencia: Estilo: Oscuro
    Escritorio de Ubuntu:
        Dock:
            - Ocultar automaticamente: si
            - Tamaño de icono: 24
```

### Actualización inicial y primera instantántea `Fresh Install`

Luego usaremos las herramientas gráficas de actualización del sistema, drivers y sofware, pero primero abramos la Terminal para poner estos comandos básicos:

```bash
sudo apt update
    # TODO: "Warning: The unit file, source configuratino file or drop-ins of (apt-news.service | esm-cache.service) changed on disk. Run 'systemctl daemon-reload' to reload units
sudo apt upgrade -y
    # "Todos los paquetes están actualizados"... supongo que es porque la 24.04 salió hace 24 horas xd

# Introducimos el comando que nos sugería el sistema
sudo systemctl daemon-reload
```

En este punto podemos apagar la vm y, en los menús de VirtualBox, creamos una nueva Instantánea o *snapshot*. Por hábito la llamaremos `Fresh Install`.

Ahora tenemos la libertad de aplicar cualquier configuración e instalar lo que sea en Ubuntu, ya que podremos <u>restaurar el estado actual de la máquina</u> si rompemos algo o si simplemente queremos hacer pruebas de cara a perfeccionar el proceso de los siguientes apartados.

---

## Parte 2: instalación de programas de terminal y de escritorio (todo automatizado)

### Script `ubuntu-base.sh`

Reiniciamos la máquina virtual `UbuntuDesk-24.04-Asterisk` y abrimos la terminal. Introducimos el siguiente comando, que usa `curl` para recoger el código de nuestro script y `bash` para ejecutarlo.

```bash
bash -c "$(curl -fsSL https://github.com/pabloqpacin/lab_asterisk/raw/main/scripts/ubuntu-base.sh)"
```

El script está en este mismo repositorio, en [/scripts/ubuntu-base.sh](/scripts/ubuntu-base.sh). A grandes rasgos, el script hace lo siguiente:

- [ ] Cambiar Wayland por x11 en la configuración por defecto (**PANTALLA DE INICIO**)
- [ ] Actualizar el sistema
- [ ] Instalar herramientas de terminal: bat lf tmux zsh...
- [ ] Clonar [mis dotfiles](https://github.com/pabloqpacin/dotfiles) y establecer algunos enlaces simbólicos (a mis archivos de configuración para los usuarios `setesur` y `root`)
- [ ] Instalar Docker, Docker Desktop y Portainer
- [ ] Instalar aplicaciones gráficas:
  - [ ] **Brave**: como Chrome pero mejor
  - [ ] **Anydesk**: importante para conexiones remotas...
  - [ ] **Keepassxc**: gestor de contraseñas libre y gratuito
  - [ ] **VSCodium**: editor de texto y código, fork open source de VSCode
  - [ ] **Nmapsi4** y **Wireshark**: monitoreo de redes

---

> PROBLEMA: incompatibilidad anydesk & alacritty con wayland, y problemas al cambiar a x11; decidimos usar otra vm con ubuntu 22.04 que ya tenía ready


<!-- Foo y tal. -->


### Configuración del Escritorio (2)

...


---

## Parte 3: Docker, en general

...

## Parte 4: servidor Asterisk PBX (+ clientes Zoiper)

...





---

## PENDIENTE

### Nuevo usuario `prueba` (sin privilegios `sudo`)