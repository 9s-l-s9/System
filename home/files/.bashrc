source ~/.profile
source ~/.guix-home/setup-environment
GUIX_LOCPATH=$HOME_ENVIRONMENT/profile/lib/locales

export SHELL

if [[ $- != *i* ]]
then
    # We are being invoked from a non-interactive shell.  If this
    # is an SSH session (as in "ssh host command"), source
    # /etc/profile so we get PATH and other essential variables.
    [[ -n "$SSH_CLIENT" ]] && source /etc/profile

    # Don't do anything else.
    return
fi

# Source the system-wide file.
[ -f /etc/bashrc ] && source /etc/bashrc

alias ls='ls -p --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'

alias gh='guix home reconfigure ~/Projects/System/home/home-configuration.scm'
alias gs='sudo guix system reconfigure ~/Projects/System/systems/$(hostname).scm'

alias alire-shell='guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=$HOME=$HOME'


deno () {
  docker run \
    --interactive \
    --tty \
    --rm \
    --volume $PWD:/app \
    --volume $HOME/.deno:/deno-dir \
    --workdir /app \
    --publish 8000:8000 \
    denoland/deno:1.39.1 \
    "$@"
}

# Additional Apps
export PATH="$HOME/Apps:$PATH"
#export PATH="$HOME/Apps/node-v20.14.0-linux-x64/bin/:$PATH"
# Set the GEM_PATH to the user-specific gem installation directory
export GEM_PATH="$HOME/.local/share/gem/ruby/3.3.0"

# Ensure the GEM_PATH/bin directory is included in the PATH
export PATH="$GEM_PATH/bin:$PATH"

export PATH=/usr/lib/cuda-11.2/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib/cuda-11.2/lib64:$LD_LIBRARY_PATH
