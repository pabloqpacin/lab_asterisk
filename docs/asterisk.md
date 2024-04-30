# Asterisk

- [Asterisk](#asterisk)
  - [Documentación](#documentación)
  - [Manual de instalación en máquina virtual Ubuntu 2X.04](#manual-de-instalación-en-máquina-virtual-ubuntu-2x04)
    - [1. Instalar y Configurar Servidor VoIP](#1-instalar-y-configurar-servidor-voip)
      - [Instalación de Asterisk en servidor](#instalación-de-asterisk-en-servidor)
      - [Configuración de usuarios y terminales](#configuración-de-usuarios-y-terminales)
      - [Instalación de Zoiper en clientes (softphones)](#instalación-de-zoiper-en-clientes-softphones)
      - [Configuración de direccionamiento de llamadas](#configuración-de-direccionamiento-de-llamadas)
      - [Llamada de prueba... exitosa!](#llamada-de-prueba-exitosa)
    - [2. Reproducir un fichero de Audio con Playback](#2-reproducir-un-fichero-de-audio-con-playback)


## Documentación

- General:
  - @masip.es: [Qué es Asterisk y cómo funciona: características, servicios y por qué lo necesitas](https://www.masip.es/blog/que-es-asterisk/)
- Setup Estándar:
  - https://github.com/asterisk/asterisk
  - https://www.asterisk.org/
  - https://www.asterisk.org/community/documentation/
  - **https://docs.asterisk.org/**
- Setup Docker:
  - @asterisk.org: [Continuous Integration with Asterisk and Docker (2017)](https://www.asterisk.org/continuous-integration-asterisk-docker/)
  - https://hub.docker.com/r/andrius/asterisk (100k pulls)
  - https://github.com/mlan/docker-asterisk (10k pulls)
- Tutoriales:
  - @RedesPlus (YT): [🔶 CURSO ASTERISK 📞 Tutorial Completo 🆓](https://www.youtube.com/playlist?list=PLXXiznRYETLfnWuAQHrMayGDPnBhSBICb)


## Manual de instalación en máquina virtual Ubuntu 2X.04

> Siguiendo al buen zagal de **Redes Plus (YT)**

### 1. Instalar y Configurar Servidor VoIP

#### Instalación de Asterisk en servidor

```bash
# Instalación
sudo apt update
sudo apt install asterisk \
    asterisk-core-sounds-es asterisk-core-sounds-es-g722 \
    asterisk-core-sounds-es-gsm asterisk-core-sounds-es-wav

# # Comprobaciones
# apt-cache search asterisk | grep -e "Spanish" -e "-es"
# dpkg -l 'asterisk*'
# asterisk -V
#     # Asterisk 18.10.0~dfsg+~cs6.10.40431411-2

# # Comandos de administración
# systemctl status asterisk
# systemctl start asterisk
# systemctl stop asterisk
# systemctl reload asterisk
```

```bash
# Estado inicial (errores a resolver)
grep 'asterisk' /var/log/syslog
    # Apr 25 18:02:33 UbuntuBox asterisk: radcli: rc_read_config: rc_read_config: can't open /etc/radiusclient-ng/radiusclient.conf: No such file or directory
    # Apr 25 18:02:33 UbuntuBox asterisk: radcli: rc_read_config: rc_read_config: can't open /etc/radiusclient-ng/radiusclient.conf: No such file or directory

sudo cp /etc/asterisk/cel.conf{,.bak} &&
    echo 'radiuscfg => /etc/radcli/radiusclient.conf' | sudo tee -a /etc/asterisk/cel.conf

sudo cp /etc/asterisk/cdr.conf{,.bak} &&
    sudo sed -i '/^;\[radius]/s/^;//' /etc/asterisk/cdr.conf &&
    echo 'radiuscfg => /etc/radcli/radiusclient.conf' | sudo tee -a /etc/asterisk/cdr.conf

sudo systemctl restart asterisk
```

#### Configuración de usuarios y terminales

- `sip.conf`: permite definir los canales SIP (peers), tanto para llamadas entrantes como salientes; terminales y usuarios

```bash
sudo cp /etc/asterisk/sip.conf{,.bak}

# # Borrar líneas comentadas y vacías
# sudo sed -i '/^\s*;/d' /etc/asterisk/sip.conf && sudo sed -i '/^$/d' /etc/asterisk/sip.conf

cat <<EOF | sudo tee /etc/asterisk/sip.conf
[general]
context=public
allowoverlap=no
udpbindaddr=0.0.0.0
tcpenable=no
tcpbindaddr=0.0.0.0
transport=udp
srvlookup=yes
; -- empieza cosecha propia
qualify=yes
language=es
disallow=all
allow=alaw, ulaw
; -- termina cosecha propia
[authentication]
[basic-options](!)
        dtmfmode=rfc2833
        context=from-office
        type=friend
[natted-phone](!,basic-options)
        directmedia=no
        host=dynamic
[public-phone](!,basic-options)
        directmedia=yes
[my-codecs](!)
        disallow=all
        allow=ilbc
        allow=g729
        allow=gsm
        allow=g723
        allow=ulaw
[ulaw-phone](!)
        disallow=all
        allow=ulaw
; -- empieza cosecha propia
[usuario](!)
type=friend
host=dynamic
context=setesur
; Extension 101
[ext101](usuario)
username=delfin
secret=s1234
;port=5061
; Extension 102
[ext102](usuario)
username=tortuga
secret=s1234
port=5061
; El type "user" autentica llamadas entrantes, "peer" salientes y "friend" ambas
; -- termina cosecha propia
EOF

sudo systemctl reload asterisk
```
```bash
# # Conectarse a la consola
# sudo asterisk -rvvv
#    # mantener consola abierta:
#      # - probar 'sudo systemctl reload asterisk' y ver avisos y errores...
#      # - veremos 'Peer ext102 is now Reachable' luego cuando Zoiper
bat-ff /var/log/asterisk/messages || \
    tail -f -n +1 /var/log/asterisk/messages || \
        sudo asterisk -r -vvv

sudo asterisk -x 'sip show users'
sudo asterisk -x 'sip show peers'
```
<!-- ```bash
# Otros comandos
sudo asterisk -x 'sip reload'
sudo asterisk -x 'dialplan reload'
sudo asterisk -x 'core show channels'
sudo asterisk -x 'sip show channels'
``` -->


#### Instalación de Zoiper en clientes (softphones)

- Instalar Zoiper (emulador de softphone) para la terminal `101` en el propio Ubuntu Server

```bash
# Descargar a través del navegador (no consigo encontrar el comando adecuado)
xdg-open https://www.zoiper.com/en/voip-softphone/download/zoiper5/for/linux-deb

# Instalar paquete y asegurar que las dependencias se instalan también
sudo dpkg -i $(xdg-user-dir DOWNLOAD)/Zoiper5*.deb && sudo apt install --fix-broken

# Abrir la aplicación zoiper (GUI)
```
```yaml
zoiper5:
  Continue as Free user:
    Login:
      - Username: ext102@localhost      # podríamos usar IPv4 o dominio si DNS
      - Password: s1234
    Hostname: localhost
    Authentication and Outbound proxy:
      - Optional: yes
      - Authentication username: ext102
    Configure Zoiper5: Configure:
        Speaker: yes
        Microphone: yes                 # VirtualBox: machine: settings: audio: Enable Audio Input
        Video: skip
```

- Instalar la app de Android [Zoiper](https://play.google.com/store/apps/details?id=com.zoiper.android.app) en un teléfono conectado a la WiFi

```md
Are you sure you want to use _Free limited_ version?
You will miss on all these features:
- __Reliable Incoming calls__ - Push proxy
- __Business features__ -- Call Recording, Call conference, call transfer, multiple accounts, presence, ZRTP encryption, MWI, QoS/DSCP, Auto Answer
- __Additional codecs__ -- G729 and h264
- __Wideband audio__ -- Superior audio quality & lower latency thanks to G.722, G.726, Opus, Speex
```

```yaml
Zoiper IAX SIP VOIP Softphone:
    Terms and Data Disclosure: Agree & Continue
    Account setup:
        - Username: ext101@192.168.1.205        # OJO, según IP del UbuntuServer...
        - Password: s1234
        - Hostname: 192.168.1.205
        - My provider/PBX requires an auth username or outbound proxy: yes
        - Authentication username: ext101
```
```md
Éxito pero todavía no existe enrutamiento para las llamadas:

> `[Apr 25 20:45:20] NOTICE[1336][C-00000001] chan_sip.c: Call from 'tortuga' (127.0.0.1:44485) to extension '101' rejected because extension not found in context 'setesur'.`
```

#### Configuración de direccionamiento de llamadas

- `extensions.conf`:
  - ~~define el comportamiento que va a tener una llamada en nuestra centralita (reglas de enrutamiento, aplicaciones a ejecutar, dialplan, etc.)  <!--(donde redirigir las llamadas)-->~~
  - controla el dialplan de la centralita: define cómo se comportarán las llamadas entrantes y salientes del sistema
  - fichero compuesto por **contextos**, **extensiones** y **prioridades**: ...

```bash
sudo cp /etc/asterisk/extensions.conf{,.bak}

cat <<EOF | sudo tee /etc/asterisk/extensions.conf
[setesur]
exten => 101,1,Dial(SIP/ext101)
exten => 102,1,Dial(SIP/ext102)
EOF

sudo asterisk -x 'dialplan reload'
```

#### Llamada de prueba... exitosa!

```bash
bat-ff /var/log/asterisk/cdr-csv/Master.csv || \
    tail -f -n +1 /var/log/asterisk/cdr-csv/Master.csv || \
        sudo asterisk -r -vvv
```

> ÉXITO

```log
[Apr 25 21:08:53] NOTICE[1336]: chan_sip.c:25007 handle_response_peerpoke: Peer 'ext101' is now Reachable. (11ms / 2000ms)
  == Using SIP RTP CoS mark 5
    -- Executing [101@setesur:1] Dial("SIP/ext102-00000000", "SIP/ext101") in new stack
  == Using SIP RTP CoS mark 5
    -- Called SIP/ext101
    -- SIP/ext101-00000001 is ringing
    -- Got SIP response 486 "Busy Here" back from 192.168.1.36:47674
    -- SIP/ext101-00000001 is busy
  == Everyone is busy/congested at this time (1:1/0/0)
    -- Auto fallthrough, channel 'SIP/ext102-00000000' status is 'BUSY'
  == Using SIP RTP CoS mark 5
    -- Executing [102@setesur:1] Dial("SIP/ext101-00000002", "SIP/ext102") in new stack
  == Using SIP RTP CoS mark 5
    -- Called SIP/ext102
    -- SIP/ext102-00000003 is ringing
    -- SIP/ext102-00000003 answered SIP/ext101-00000002
    -- Channel SIP/ext102-00000003 joined 'simple_bridge' basic-bridge <12bf7766-0607-47bd-8852-28a5fc802815>
    -- Channel SIP/ext101-00000002 joined 'simple_bridge' basic-bridge <12bf7766-0607-47bd-8852-28a5fc802815>
    -- Channel SIP/ext101-00000002 left 'native_rtp' basic-bridge <12bf7766-0607-47bd-8852-28a5fc802815>
    -- Channel SIP/ext102-00000003 left 'native_rtp' basic-bridge <12bf7766-0607-47bd-8852-28a5fc802815>
  == Spawn extension (setesur, 102, 1) exited non-zero on 'SIP/ext101-00000002'
```

```bash
# Que no empiece automáticamente
if [ -e ~/.config/autostart/Zoiper5.desktop ]; then
  mv ~/.config/autostart/Zoiper5.desktop{,.bak}
fi
```

### 2. Reproducir un fichero de Audio con Playback

...
