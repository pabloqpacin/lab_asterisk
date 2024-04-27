#!/usr/bin/env

prep_skel(){
    skel_dirs=('.config/nvim' 'Descargas' 'Documentos' 'Escritorio' 'Imágenes' 'Música' 'Plantillas' 'Público' 'Vídeos')
    for dir in ${skel_dirs[@]}; do
        if [ ! -d /etc/skel/$dir ]; then
            sudo mkdir -p /etc/skel/$dir
        fi
    done
    sudo cp -r $HOME/.oh-my-zsh /etc/skel
    sudo cp -r $HOME/dotfiles /etc/skel
}

create_user_pass(){
    declare -A users
    users=(
        ["josu"]="prueba12"     # tiene que ser más de 8 chars
        ["prueba"]="changeme"   # no puede coincidir name y pass
        ["pablo.quevedo"]="changeme"
    )

    for username in "${!users[@]}"; do
        password="${users[$username]}"
        echo "Usuario: $username (Contra: $password)"

        sudo useradd -mg users -s $(which zsh) $username
        sudo passwd $username

        sudo ln -s /home/$username/dotfiles/.zshrc /home/$username
        sudo ln -s /home/$username/dotfiles/.vimrc /home/$username
        sudo ln -s /home/$username/dotfiles/.vimrc /home/$username/.config/nvim/init.vim
        sudo ln -s /home/$username/dotfiles/.config/tmux /home/$username/.config
        sudo ln -s /home/$username/dotfiles/.config/bat /home/$username/.config
        sudo ln -s /home/$username/dotfiles/.config/lf /home/$username/.config
    done
}

# ---

prep_skel
create_user_pass
