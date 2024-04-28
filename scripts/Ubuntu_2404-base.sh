#!/usr/bin/env bash

# # En un Ubuntu Desktop 24.04 LTS como usuario (no root):
# wget -q https://github.com/pabloqpacin/lab_asterisk/raw/main/scripts/Ubuntu_2404-base.sh
# bash Ubuntu_2404-base.sh

# REFS: dotfiles (debubu, ubuntuserver), proyecto_lemp_compose (lxc debian)

# NOTA 1: en abril de 2024 neovim funciona bien; en un año probablemente habrá que construir el programa manualmente
# NOTA 2: entonces... no flatpak?
# NOTA 3: PROBLEMAS MUY IMPORTANTES con anydesk y alacritty en Wayland; decidimos seguir usando 22.04 (clonando otra vm) por ahora!!!!!

# ~~# RESUMEN: paquetes de terminal y gráficos para el usuario ~~


set_variables() {
    sa_update="sudo apt-get update"
    snap_install="sudo snap install"
    read -p "Saltar confirmaciones tipo 'apt install <package>' e instalar todo? [y/N] " opt
    case $opt in
        'Y'|'y') sa_install="sudo apt-get install -y" ;;
        *)       sa_install="sudo apt-get install"    ;;
    esac
}

apt_update_install(){
    if [ ! -e "/etc/apt/apt.conf.d/99show-versions" ]; then
        echo 'APT::Get::Show-Versions "true";' | sudo tee /etc/apt/apt.conf.d/99show-versions
    fi

    $sa_update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

    if [ $(systemctl is-enabled ssh) == 'not-found' ]; then
        $sa_install openssh-server
        sudo systemctl enable --now ssh
    elif [ $(systemctl is-enabled ssh) == 'disabled' ]; then
        sudo systemctl enable --now ssh
    fi

    # if [ $(systemctl is-enabled cups) == 'enabled' ]; then
    #     sudo systemctl disable cups
    # fi

    $sa_install build-essential
    $sa_install --no-install-recommends neofetch
    $sa_install curl git net-tools wget wl-clipboard xclip xsel
    $sa_install bat btm eza flameshot fzf git-delta grc jq lf nmap ripgrep tmux vim
    # $sa_install alacritty btop cht.sh devilspie fd-find ipcalc kitty mycli zoxide
    # $sa_install --no-install-recommends python3-pip python3-venv oneko
    # $snap_install cheat

    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
        sudo mv $(which batcat) /usr/bin/bat
    fi
    # if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    #     sudo mv $(which fdfind) /usr/bin/fd
    # fi

    # if ! command -v tldr &>/dev/null; then
    #     read -p "Instalar tldr [y/N]? " opt_tldr
    #     if [[ $opt_tldr == 'y' ]]; then
            $sa_install tldr
            if [ ! -d ~/.local/share ]; then
                mkdir ~/.local/share
            fi
            tldr --update
    #     fi
    # fi
}

clone_symlink_dotfiles() {
    if true; then
        sudo mkdir /root/.config 2>/dev/null
    fi
    if [ ! -d ~/.config ]; then
        mkdir ~/.config &>/dev/null
    fi
    if [ ! -d ~/dotfiles ]; then
        git clone --depth 1 https://github.com/pabloqpacin/dotfiles $HOME/dotfiles
    fi
    if [ ! -L ~/.config/bat ]; then
        ln -s ~/dotfiles/.config/bat ~/.config
    fi
    if [ ! -L ~/.config/bottom ]; then
        ln -s ~/dotfiles/.config/bottom ~/.config
    fi
    if [ ! -L ~/.config/lf ]; then
        ln -s ~/dotfiles/.config/lf ~/.config
    fi
    if [ ! -L ~/.config/tmux ]; then
        ln -s ~/dotfiles/.config/tmux ~/.config
    fi
    if [ ! -L ~/.vimrc ]; then
        if [ -e ~/.vimrc ]; then mv ~/.vimrc{,.bak}; fi
        ln -s ~/dotfiles/.vimrc ~/ &&
        sudo ln -s $HOME/dotfiles/.vimrc /root/
        # sed -i "s/'nvim'/'vim'/g" ~/dotfiles/.zshrc
    fi
    if [ ! -L ~/.gitconfig ]; then
        sed -i "s/pabloqpacin/$USER/" ~/dotfiles/.gitconfig &&
            sed -i '/github/d' ~/dotfiles/.gitconfig
        ln -s ~/dotfiles/.gitconfig ~/
    fi
}

setup_zsh(){
    $sa_update && $sa_install zsh

    if [ ! -d ~/.oh-my-zsh ]; then
        yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        bash $HOME/dotfiles/scripts/setup/omz-msg_random_theme.sh
    fi
    
    if [ $(echo $SHELL | awk -F '/' '{print $(NF)}') != 'zsh' ]; then
        sudo chsh -s $(which zsh) $USER
    fi
    
    if [ ! -L ~/.zshrc ]; then
        mv ~/.zshrc{,.bak} &&
        ln -s ~/dotfiles/.zshrc ~/
    fi
    
    if [[ ! -d ~/dotfiles/zsh/plugins/zsh-autosuggestions || ! -d ~/dotfiles/zsh/plugins/zsh-syntax-highlighting ]]; then
        bash $HOME/dotfiles/zsh/plugins/clone-em.sh
    fi
}

setup_nvim(){
    $sa_install neovim                                                          # OJO: update-alternatives /usr/bin/vim ......

    if ! command -v npm &>/dev/null; then
        if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        fi
        if ! command -v node &>/dev/null && ! command -v npm &>/dev/null; then
            [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
            nvm install node
        fi
    fi

    # TODO: revisar recomendaciones del desarrollador; quizá usar otro plugin-manager este verano
    if [ ! -d ~/.local/share/nvim/site/pack/packer ]; then
        git clone --depth 1 https://github.com/wbthomason/packer.nvim \
            ~/.local/share/nvim/site/pack/packer/start/packer.nvim
    fi

    if [ ! -L ~/.config/nvim ]; then
        sudo mkdir -p /root/.config/nvim &&
        sudo ln -s ~/dotfiles/.vimrc /root/.config/nvim/init.vim

        ln -s ~/dotfiles/.config/nvim ~/.config
        cd ~/.config/nvim && {
            read -p "Pasa los mensajes de error con <INTRO>, luego escribe :so <INTRO>, :PackerSync <INTRO> y :qa <INTRO> " null
            nvim lua/pabloqpacin/packer.lua
            read -p "Pasa los mensajes de error con <INTRO>, luego escribe :Mason <INTRO> y :qa <INTRO> " null
            nvim after/plugin/lsp.lua
            cd $HOME
        }
    fi
}

install_rust(){
    if ! command -v cargo &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

        $HOME/.cargo/bin/cargo install --locked yazi-fm &&
            sudo cp $HOME/.cargo/yazi /usr/bin/yazi
    fi
}

setup_docker_portainer(){

    if ! command -v docker &>/dev/null; then
        sh <(curl -sSL https://get.docker.com)
        sudo usermod -aG docker $USER
    fi

    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "portainer"; then
        sudo docker run -d --name portainer --restart=always -p 8008:8000 -p 9443:9443  \
            -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
            portainer/portainer-ce:latest

        sleep 2 && xdg-open https://localhost:9443 &>/dev/null
    fi

    # docker-desktop?
}

install_gui_pkgs(){

    if ! command -v anydesk &>/dev/null && ! flatpak list 2>/dev/null | grep -q 'anydesk'; then
        wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/anydesk-archive-keyring.gpg
        echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
        $sa_update && $sa_install anydesk
        sudo systemctl disable anydesk
    fi

    if ! command -v brave-browser &>/dev/null; then
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
            https://brave-browser-apt-release.s3.brave.com/ stable main" \
            | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        $sa_update && $sa_install brave-browser
    fi

    if ! command -v codium &>/dev/null; then
        wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor \
            | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
            | sudo tee /etc/apt/sources.list.d/vscodium.list
        $sa_update && $sa_install codium
        
        # case $XDG_SESSION_TYPE in 'x11')
            $sa_install devilspie
            ln -s ~/dotfiles/.devilspie ~/
            ln -s ~/dotfiles/.config/autostart ~/.config
            bash ~/dotfiles/scripts/setup/codium-extensions.sh
            codium &
            sleep 2 && pkill codium
            # rm $HOME/.config/VSCodium/User/settings.json && \
            ln -s ~/dotfiles/.config/code/User/settings.json ~/.config/VSCodium/User
        #     ;;
        # esac
    fi

    # if ! command -v keepassxc &>/dev/null; then
    #     $sa_install keepassxc
    #     mkdir ~/KeePassXC
    #     # yes 'changeme' | head -n 2 | keepassxc-cli db-create ~/KeePassXC/example.kdbx -p
    #     # keepassxc-cli add -u pablo.quevedo@setesur.com ~/KeePassXC/Passwords.kdbx GoogleWorkspace -p
    #     # xdg-open https://keepassxc.org/docs/KeePassXC_UserGuide#_setup_browser_integration
    # fi

    # if ! command -v nmapsi4 &>/dev/null; then
    #     $sa_install nmapsi4
    # fi

    # if ! command -v wireshark &>/dev/null; then
    #     read -p "En el menú que aparecerá, selecciona Yes " null  
    #     $sa_update && $sa_install wireshark tshark
    #     sudo usermod -aG wireshark $USER
    # fi

}

info_vbox_additions(){
    echo -e "\nInstalamos los drivers de VirtualBox:"
    echo "- VirtualBox: Devices > Insert Guest Additions CD image..."
    read -p "- Ubuntu: /media/setesur/VBox_GAs_6.1.50 > Click derecho en 'autorun.sh' > Ejecutar " null
}


# ---

if true; then
    set_variables
    apt_update_install
    clone_symlink_dotfiles

    case $(echo $sa_install | awk '{print $(NF)}') in
        '-y')
            setup_zsh
            setup_nvim
            # install_rust
        ;;
        *)
            opt_zsh=''
            while [[ $opt_zsh != 'y' && $opt_zsh != 'n' ]]; do
                read -p "Establecer zsh [y/n]? " opt_zsh
            done
            if [[ $opt_zsh == 'y' ]]; then
                setup_zsh
            fi

            opt_nvim=''
            while [[ $opt_nvim != 'y' && $opt_nvim != 'n' ]]; do
                read -p "Instalar y configurar Neovim [y/n]? " opt_nvim
            done
            if [[ $opt_nvim == 'y' ]]; then
                setup_nvim
            fi

            # opt_rust=''
            # while [[ $opt_rust != 'y' && $opt_rust != 'n' ]]; do
            #     read -p "Instalar rust [y/n]? " opt_rust
            # done
            # if [[ $opt_rust == 'y' ]]; then
            #     install_rust
            # fi
        ;;
    esac

    setup_docker_portainer
    install_gui_pkgs            # anydesk brave codium ~~keepassxc nmapsi4 wireshark~~
    info_vbox_additions
fi

sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean
echo "" && neofetch && sudo grc docker ps -a && echo "" && df -h | grep -e '/$' -e 'Mo'
[ -f /var/run/reboot-required ] && echo -e "\nReinicia la máquina.\n"


# ---

# # Importante para AnyDesk...
# set_x11_vbox(){}
    # $sa_install virtualbox-guest-utils virtualbox-guest-x11
    # sudo sed -i '/WaylandEnable/s/^#//' /etc/gdm3/custom.conf || {
    # echo "EN OPCIONES DE VBOX, SELECCIONA '3D Acceleration'"
    # echo "AL HACER LOGIN, SELECCIONA 'Ubuntu en Xorg"
    # }
# }

#    # apt show neovim => Vesrion: 0.9.5-6ubuntu2 => ¿Soportará mis plugins? ¡Probemos!

# install_nerdfonts(){
#     # if [ ! -d ~/.fonts ]; then mkdir ~/.fonts; fi
#     if ! fc-cache -v | grep -q 'Fira'; then
#         wget -qO /tmp/FiraCode.zip 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip'
#         sudo unzip -q /tmp/FiraCode.zip -d /usr/share/fonts/FiraCodeNerdFont
#     fi
#     if ! fc-cache -v | grep -q 'Cascadia'; then
#         wget -qO /tmp/CascadiaCode.zip 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip'
#         sudo unzip -q /tmp/CascadiaCode.zip -d /usr/share/fonts/CascadiaCodeNerdFont
#     fi
#     fc-cache -f
# }
