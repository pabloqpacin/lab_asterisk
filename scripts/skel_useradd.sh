#!/usr/bin/env bash

prep_skel(){
    skel_dirs=('.config/nvim' '.local/share' 'Descargas' 'Documentos' 'Escritorio' 'Imágenes' 'Música' 'Plantillas' 'Público' 'Vídeos')
    for dir in ${skel_dirs[@]}; do
        if [ ! -d "/etc/skel/$dir" ]; then
            sudo mkdir -p "/etc/skel/$dir"
        fi
    done

    custom_dirs=('.oh-my-zsh' 'dotfiles' '.local/share/tldr')                   # '.nvm'
    for dir in ${custom_dirs[@]}; do
        if [ -d "$HOME/$dir" ] && [ ! -d "/etc/skel/$dir" ]; then
            sudo cp -r "$HOME/$dir" "/etc/skel/$dir"
        fi
    done
}

create_user_pass_home(){
    declare -A users
    users=(
        # ["josu"]="prueba12"         # tiene que ser de 8 o más chars
        # ["prueba"]="changeme"       # no puede coincidir name y pass
        ["setesur"]="prueba1234"
        # ["pablo.quevedo"]="changeme"
    )

    for username in "${!users[@]}"; do
        if ! grep -q "$username" /etc/passwd; then
            password="${users[$username]}"
            echo -e "\nUsuario: $username (Contra: $password)"

            if ! grep -q "$username" /etc/group; then
                sudo groupadd "$username"
            fi
            case "$username" in
                setesur) sudo useradd -mg "$username" -G docker,sudo -s $(which zsh) "$username" ;;
                    *) sudo useradd -mg "$username" -G docker -s $(which zsh) "$username" ;;
            esac
            sudo passwd "$username"

            sudo su - "$username" -c "{
                sed -i s/pabloqpacin/$username/ /home/$username/dotfiles/.config/alacritty/alacritty.toml

                ln -s /home/$username/dotfiles/.zshrc /home/$username/.zshrc
                ln -s /home/$username/dotfiles/.vimrc /home/$username/.vimrc
                ln -s /home/$username/dotfiles/.vimrc /home/$username/.config/nvim/init.vim
                ln -s /home/$username/dotfiles/.config/alacritty /home/$username/.config
                ln -s /home/$username/dotfiles/.config/bottom /home/$username/.config
                ln -s /home/$username/dotfiles/.config/tmux /home/$username/.config
                ln -s /home/$username/dotfiles/.config/bat /home/$username/.config
                ln -s /home/$username/dotfiles/.config/lf /home/$username/.config
            }"
        fi
    done
}

# ---

prep_skel
create_user_pass_home
# https://askubuntu.com/questions/1066239/how-to-change-default-dock-applications-for-new-users
