status --is-interactive; or exit 0

set -x PATH ~/bin /usr/local/bin /usr/local/share/npm/bin $PATH

# SET TERM TYPE
# Bad idea, according to most people. However, all of the terminals I use
# support 256color and most terminals don't set the appropriate term type. Also
# see http://snk.tuxfamily.org/log/vim-256color-bce.html bce = background color
# erase = more efficient background. Not all combinations of terminal emulators
# and tmux support it, so don't use it.
#
# Interestingly, xterm-256color results in a working vim background outside
# tmux but not within. screen-256color works inside and outside of tmux.
set -x TERM screen-256color


# AUTOMATIC TMUX
# must not launch tmux inside tmux (no memes please)
test -z $TMUX
	# installed?
	and which tmux > /dev/null
	# only attach if single session
	and test (tmux list-sessions | wc -l ^ /dev/null) -eq 1
	# don't attach if already attached elsewhere
	and test (tmux list-clients | wc -l ^ /dev/null) -eq 0
	# terminal must be wide enough
	and test (tput cols) -gt 119
	# only then is is safe to assume it's OK to jump in
	and tmux attach


# totally worth it
if not test -d ~/.config/fish/generated_completions/
	echo "One moment..."
	fish_update_completions
end


set -x EDITOR vim

set -x HOSTNAME (hostname)


# if you call a different shell, this does not happen automatically. WTF?
set -x SHELL (which fish)


# alias is just a wrapper for creating a function
# aliases shared between fish and bash
. ~/.aliases

# fish specific aliases
alias tm 'test -z $TMUX; and tmux a ; or tmux'

function cd
	builtin cd $argv
	ls
end

test -x /usr/bin/keychain
	and test -r ~/.ssh/id_rsa
	and eval (keychain --quiet --eval ~/.ssh/id_rsa)

# these functions are too small to warrant a separate file
function fish_greeting
	echo \n\> Welcome to $HOSTNAME, $USER. Files in $PWD are:\n
	ls
end


function fish_title --description 'Set terminal (not tmux) title'
	# title of terminal
	echo $HOSTNAME
end

function fish_tmux_title --description "Set the tmux window title"
	# to a clever shorthand representation of the current dir
	echo $PWD | sed s-^$HOME/-- | sed s-^$HOME-$USER- | grep -oE '[^\/]*\/?[^\/]+$'
end

function fish_set_tmux_title --description "Sets tmux pane title to output of fish_tmux_title, with padding" --on-variable PWD
	# title of tmux pane, must be separate to fish_title
	# only run this if tmux is also running
	test -z $TMUX
		or printf "\\033k%s\\033\\\\" ' '(fish_tmux_title)' '
end

function fish_prompt --description 'Write out the prompt'
	echo -n -s \n (set_color green) $USER @ $HOSTNAME (set_color normal)\
	' ' (set_color --bold blue) (pwd) (set_color normal)\
	(set_color yellow) (__fish_git_prompt) (set_color normal)\
	\n\$ ' '
end

function fish_right_prompt --description 'Reminds user of fish'
	set_color 111
	echo FISH
	set_color normal
end

# initially set title
fish_set_tmux_title

