#!/usr/bin/env bash


# wget 192.168.1.42:8000/scripts/ubuntu-base.sh && bash ubuntu-base.sh

# # En un Ubuntu Desktop 24.04 LTS como usuario (no root):
# bash -c "$(curl -fsSL https://github.com/pabloqpacin/lab_asterisk/raw/main/scripts/mv_ubuntu.sh)"

# REFS: dotfiles (debubu, ubuntuserver), proyecto_lemp_compose (lxc debian)

# NOTA 1: en abril de 2024 neovim funciona bien; en un año probablemente habrá que construir el programa manualmente
# NOTA 2: entonces... no flatpak?

# ~~# RESUMEN: paquetes de terminal y gráficos para el usuario ~~


set_variables() {
    sa_update="sudo apt-get update"
    # read -p "Saltar confirmaciones tipo 'apt install <package>'? [y/N] " opt
    read -p "Saltar confirmaciones tipo 'apt install <package>' e instalar todo? [y/N] " opt
    case $opt in
        'Y'|'y')
            sa_install="sudo apt-get install -y"
            snap_install="sudo snap install -y"
            ;;
        *)
            sa_install="sudo apt-get install"
            snap_install="sudo snap install"
        ;;
    esac
    # read -p "Instalar TODO (nvim, rust, zsh...)? [y/N] " opt
    # case $opt in
    #     'Y'|'y') smorgasbord="1" ;;
    #           *) smorgasbord="0" ;;
    # esac
}

# set_x11(){}

apt_update_install(){
    if [ ! -e "/etc/apt/apt.conf.d/99show-versions" ]; then
        echo 'APT::Get::Show-Versions "true";' | sudo tee /etc/apt/apt.conf.d/99show-versions
    fi

    $sa_update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

    if [ $(systemctl is-enabled ssh) == 'not-found' ]; then
        $sa_install openssh-server
        sudo systemctl enable --now ssh
    elif [ $(systemctl is-enabled ssh) == 'disable' ]; then
        sudo systemctl enable --now ssh
    fi

    $sa_install build-essential
    $sa_install --no-install-recommends neofetch
    $sa_install curl git net-tools wget wl-clipboard xclip xsel
    $sa_install bat btm eza flameshot fzf git-delta grc jq lf nmap ripgrep tmux vim
    # $sa_install --no-install-recommends python3-pip python3-venv oneko
    # $sa_install btop cht.sh devilspie fd-find ipcalc mycli zoxide
    # $snap_install cheat

    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
        sudo mv $(which batcat) /usr/bin/bat
    fi
    if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
        sudo mv $(which fdfind) /usr/bin/fd
    fi

    if ! command -v tldr &>/dev/null; then
        read -p "Instalar tldr [y/N]? " opt_tldr
        if [[ $opt_tldr == 'y' ]]; then
            $sa_install tldr
            if [ ! -d ~/.local/share ]; then
                mkdir ~/.local/share
            fi
            tldr --update
        fi
    fi
}

setup_vbox_additions(){

    # $sa_install virtualbox-guest-utils virtualbox-guest-x11
    # # ...
    # # /etc/gdm3/custom.conf
    # # ...

    # opt_vbox=''
    # while [ $opt_vbox != 'y' ]; do
    # read -p "En la barra de VirtualBox, pincha en 'Devices' y en 'Insert Guest Additions CD Image'. Pulsa 'y' [y/n]"
    # done
    
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
        # sed -i 's/nvim/vim/g' ~/dotfiles/.zshrc
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
    
    chsh -s $(which zsh) $USER
    
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
    git clone --depth 1 https://github.com/wbthomason/packer.nvim \
     ~/.local/share/nvim/site/pack/packer/start/packer.nvim

    if [ ! -L ~/.config/nvim ]; then
        ln -s ~/dotfiles/.config/nvim ~/.config
        sudo mkdir -p /root/.config/nvim &&
            sudo ln -s ~/dotfiles/.vimrc /root/nvim/init.vim
    fi

    cd ~/.config/nvim && {
        read -p "Skip error messages with <Enter>, then do :so :PackerSync :qa " null
        nvim lua/pabloqpacin/packer.lua
        read -p "Skip error messages with <Enter>, then do :Mason " null
        nvim after/plugin/lsp.lua
        cd $HOME
    }
}

install_rust(){
    if ! command -v cargo &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

        $HOME/.cargo/bin/cargo install --locked yazi-fm &&
            sudo cp $HOME/.cargo/yazi /usr/bin/yazi
    fi
}

setup_docker_portainer(){
    sh <(curl -sSL https://get.docker.com)
    sudo usermod -aG docker $USER

    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "portainer"; then
        sudo docker run -d --name portainer --restart=always -p 8000:8000 -p 9443:9443  \
            -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
            portainer/portainer-ce:latest
    fi

    # docker-desktop?
}

install_gui_pkgs(){

    if ! command -v brave-browser &>/dev/null; then
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
            https://brave-browser-apt-release.s3.brave.com/ stable main" \
            | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        $sa_update && $sa_install brave-browser
    fi

    if ! command -v wireshark &>/dev/null; then
        $sa_update && $sa_install wireshark tshark
        sudo usermod -aG wireshark $USER
    fi

    if ! command -v keepassxc &>/dev/null; then
        $sa_install keepassxc
        mkdir ~/KeePassXC
        # yes 'changeme' | head -n 2 | keepassxc-cli db-create ~/KeePassXC/example.kdbx -p
        # keepassxc-cli add -u pablo.quevedo@setesur.com ~/KeePassXC/Passwords.kdbx GoogleWorkspace -p

        # xdg-open https://keepassxc.org/docs/KeePassXC_UserGuide#_setup_browser_integration
    fi

    if true; then
        wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/anydesk-archive-keyring.gpg
        echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
        $sa_update && $sa_install anydesk
        sudo systemctl disable anydesk
    fi

}


# ---

if true; then
    set_variables
    # set_x11                                                                   # anydesk da problemas en Wayland
    apt_update_install
    # setup_vbox_additions
    clone_symlink_dotfiles
    # install_alacritty_nerdfonts

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
    # install_gui_pkgs              # anydesk brave keepassxc nmapsi4 vscodium wireshark
fi


echo "" && neofetch && sudo grc docker ps -a && echo "" && df -h | grep -B1 '/$'
[ -f /var/run/reboot-required ] && echo -e "\nReinicia el contenedor.\n"


# ---

    # apt show neovim => Vesrion: 0.9.5-6ubuntu2 => ¿Soportará mis plugins? ¡Probemos!