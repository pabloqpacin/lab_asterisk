# Asterisk PBX en máquina virtual Ubuntu


- Básicamente una máquina virtual Ubuntu Desktop (24.04 LTS) con `Asterisk` instalado. También debe tener `AnyDesk` y `Docker`.
- Estado del proyecto:
  - Máquina Virtual
    - [x] Preparación
    - [ ] Implantación
  - Asterisk
    1. [ ] Instalación estándar con [@RedesPlus](https://www.youtube.com/playlist?list=PLXXiznRYETLfnWuAQHrMayGDPnBhSBICb)
    2. [ ] Puesta en marcha mediante docker...
- [Aquí](/docs/) la documentación:

| Doc                                           | Descripción
| ---                                           | ---
| ~~[mv_ubuntu_2404](/docs/mv_ubuntu_2404.md)~~ | ~~Puesta en marcha de Ubuntu 24.04 desde cero; <br>PROBLEMAS con Wayland/X11 para Anydesk~~
| [mv_ubuntu_2204](/docs/mv_ubuntu_2204.md)     | Configuración de Ubuntu para SETESUR
| [asterisk](/docs/asterisk.md)                 | Instalación y configuración de Asterisk y Zoiper5

<!--

---


## Objetivos

Máquina virtual `Ubuntu Desktop 24.04 LTS` para ser desplegada en VirtualBox en un ordenador Windows 10 en la red local de SETESUR. La configuración de red de la MV en VirtualBox debe ser **puente**.

Estas son las credenciales de la máquina:

```yaml
# Con permisos 'sudo' o de administrador
Usuario: setesur
Contra: changeme

# Sin permisos 'sudo'
Usuario: prueba
Contra: prueba
```

Este es el software que debe tener la máquina:
- anydesk
- asterisk & zoiper
- docker > portainer o desktop

## Documentación

- [mv_ubuntu.md](/docs/mv_ubuntu.md): instalación y configuración básica
- [asterisk.md](/docs/asterisk.md): usuarios, enrutamiento, softphones...

-->

