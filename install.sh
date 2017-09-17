#!/bin/bash

# RUN as root with HOME=/etc/skel/ so new users have these dotfiles
# or sudo -u <user> ./install.sh to install as any other user

cd $(dirname $0)

# quit on error
#set -e
CHANGE=$(git rev-list HEAD --count)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
VERSION=$BRANCH-$CHANGE
PLATFORM=$(uname)

cat <<EOF
### naggie/dotfiles, version $VERSION.

Dedpendencies:

  * tmux 1.8+
  * fish 2.0+ (recommended) or bash 3+
  * vim 7.3+
  * Dark 256color terminal with SGR1006 mouse support and UTF-8 character
    encoding for unicode character set

EOF

# this is good for log files
date
echo

function warning {
	# TODO: check PS1, no escape code if not interactive....?
	echo -e "\033[00;31m> $*\033[00m"
}


echo 'Clobbering...'
test -d ~/.vim/ && rm -rf ~/.vim/
test -d ~/.zsh/ && rm -rf ~/.zsh/
# not for fish as it removes generated completions which have to rebuilt which is a pain
#test -d ~/.config/fish/ && rm -rf ~/.config/fish/


echo 'Initialising ssh...'
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
    chmod 700 ~/.ssh
fi

touch ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

test grep github.com ~/.ssh/known_hosts || cat <<EOF >> ~/.ssh/known_hosts
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOF

echo 'Copying dotfiles...'
# copy dotfiles separately , normal glob does not match
cp -r home/.??* ~ 2> /dev/null

if [ $PLATFORM == 'Darwin' ]; then
    echo 'Mac non-hidden...'
    cp -r home/Library ~
fi

echo "Copying ~/etc..."
cp -a etc ~

echo 'Copying scripts...'
cp -a bin ~

if [ ! 0$(tput colors 2>/dev/null) -eq 256 ]; then
	warning "TERM '$TERM' is not a 256 colour type! Please set in terminal emulator. EG: Putty should have putty-256color, xterm should have xterm-256color."
fi

# reload TMUX config if running inside tmux
if [ -n "$TMUX" ]; then
	echo 'Reloading tmux configuration...'
	tmux source-file ~/.tmux.conf >/dev/null
    export SYSTEM_COLOUR=$(~/bin/system-colour.py $HOSTNAME)
    tmux set -g status-left-bg colour${SYSTEM_COLOUR} &>/dev/null
else
	warning "Not inside tmux, so can't tell tmux to reload"
fi

echo Installing/updating fonts...
./etc/powerline-patched/install.sh

if [ $PLATFORM == 'Darwin' ]; then
    echo 'Gah! Darwin!? XQuartz crashes in an annoying focus-stealing loop with this .xinirc. Removing...'
    rm ~/.xinitrc
elif [ -n "$DISPLAY" ] && which xrdb &>/dev/null; then
	echo 'Merging Xresources...'
	xrdb -merge ~/.Xresources
	# kind of forced to put this here. Ubuntu occasionally changes it for absolutely no reason.
	setxkbmap gb
else
	warning "X not configured. Now you can't enjoy the nice urxvt and xterm settings."
fi

# generate help files (well, tags) for the vim plugins
if which vim &>/dev/null; then
	echo 'Generating helptags for vim submodules...'
	# -e : ex mode, -s : silent batch mode, -n : no swap
	# must source vimrc in this mode.
	echo 'source ~/.vimrc | call pathogen#helptags()' | vim -es -n -s
else
	warning 'Vim not found! Is your brain functioning correctly?'
fi

echo $VERSION > ~/.naggie-dotfiles-version

# in case someone forgot...
if [ $BRANCH == 'master' ]; then
	warning "Generic version installed from master branch. Make your own branch for user/host-specific things."
elif [[ $BRANCH =~ "*$USER*" ]]; then
	warning "Branch does not contain user. Sure about this? The convention is to have a custom branch name containing your username."
fi

if [ -f ~/.bash_history ] && [ ! -f ~/.history ]; then
    echo "Migrating history file..."
    cp ~/.bash_history ~/.history
fi

tmux -V | grep -q 'tmux 2.' || warning "tmux 2.x not installed"
vim --version | grep -q 'Vi IMproved 8.' || warning "vim 8.x not installed"

# totally worth it
if which fish > /dev/null; then
    fish -c fish_update_completions
fi

