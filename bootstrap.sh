#!/bin/bash

app_name="cli-auto-deployment"

msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ]; then
        msg "\33[32m[✔]\33[0m ${1}${2}"
    fi
}

error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

install_vim_plugin() {
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ret="$?"
    success "installed vim-plug"
}

install_vundle() {
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    success "installed vundle"
}

sync_repo() {
	repo_path="$HOME/.$app_name"
	if [ ! -e "$repo_path" ]; then
		git clone https://github.com/adon988/cli-auto-deployment.git $repo_path
		ret="$?"
		success "clone cli-auto-deployment success."
	else
		cd $repo_path && git pull origin master
		ret="$?"
		success "update cli-auto-deployment success."
	fi
}

create_symlinks() {
	repo_path="$HOME/.$app_name"
	ln -sf "$repo_path/.vimrc"         "$HOME/.vimrc"
	ln -sf "$repo_path/.vimrc.bundles" "$HOME/.vimrc.bundles"
	touch "$HOME/.vimrc.local"
	touch "$HOME/.vimrc.bundles.local"
	mkdir -p $HOME/.vim/undodir
	ret="$?"
	success "setting up vim symlinks."
}

setup_plugin() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'
    
    vim -u $HOME/.vimrc.bundles \
        "+PluginInstall" \
        "+qall"

    export SHELL="$system_shell"

    success "Now updating/installing plugins using Vundle"
}

home_variable_check() {
    if [ -z "$HOME" ]; then
        error "You must have your HOME environmental variable set to continue."
    fi
    return 0
}

program_exists() {
    local ret='0'
    command -v $1 >/dev/null 2>&1 || { local ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 1
    fi

    return 0
}

check_program_exist() {
    program_exists $1

    # throw error on non-zero return value
    if [ "$?" -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
    return 0
}

backup() {
    backup_target=$HOME/.vimrc
    # if backup_target exists
    if [ -e "$backup_target" ]; then
        backup_path=$HOME/.backup-vim
        mkdir -p $backup_path
        mv $HOME/.vimrc $backup_path
        ret="$?"
        success "~/.vimrc already backup to ${backup_path}."
    fi
    return 0
}

################# main()

# Checkout $HOME
home_variable_check

# Checkout local environment has installed or not
check_program_exist "vim"
check_program_exist "git"

#Backup
backup

# Install vim plugin
install_vim_plugin

# Install vundle
install_vundle

# Download repository
sync_repo

# Create relative path
create_symlinks

# Setup plugin
setup_plugin

echo "Done! $app_name installation is finished!"
