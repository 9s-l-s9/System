source ~/.profile
source ~/.guix-home/setup-environment
GUIX_LOCPATH=$HOME_ENVIRONMENT/profile/lib/locales


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
