#!/usr/bin/env bash

VERSION=0.1

# Filename of this script
SCRIPT=${0##*/}

# Help text for this script
HELP=\
"usage: $SCRIPT [-h] [--version] [arg]
Add more text here
positional arguments:
  arg                  describe the argument
optional arguments:
  -d, --debug          enable verbose output
  -h, --help           show this help message
  --version            program version number "


function _debug() {
        if [ "$SSHD_CONTAINER_DEBUG" = "true" ]; then
                echo 1>&2 "Debug: $@"
        fi
}

function _error() {
        echo 1>&2 "Error: $@"
	exit 1
}

SSHD_CONTAINER_CONFIG=/etc/default/sshd_container

# Parse the command line options
ARGS=$(getopt -o h -l "help,version" -- "$@")
eval set -- "$ARGS"
while true; do
        case "$1" in
        -d|--debug)
                SSHD_CONTAINER_DEBUG=true
                shift
                ;;
        -h|--help)
                echo "$HELP"
                exit 0
                ;;
        --version)
                echo $VERSION
                exit 0
                ;;
        --)
                shift
                break 
                ;;
        *) 
                break 
                ;;
        esac
done

shell=$(getent passwd $USER | cut -d : -f 7)

# load the container default configuration if present
if test -f $SSHD_CONTAINER_CONFIG
then
        source $SSHD_CONTAINER_CONFIG
else
        _debug "$SSHD_CONTAINER_CONFIG configuration file missing"
fi

SINGULARIY_CONTAINER=${SINGULARIY_CONTAINER:-none}

if [ "$SINGULARITY_CONTAINER" == "none" ]
then
        echo "No singularity container defined"
        $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}

# if a singularity container is defined...
else
        PS3="Choose VAE by number: "
        __menu=0
        if [ "$VAE" == "menu" ]
        then
                __menu=1  # remember that menu was presented

                echo "Available Virtual Application Environments (VAE)"

                select VAE in ${VAE_MENU[@]};
                do
                        [ "$VAE" != "menu" -a -n "$VAE" ] && break
                        echo "Invalid input '$REPLY'. Try again!"
                done
        fi

        if [ $__menu -a -z "$VAE" ]
        then
                echo "Menu selection failed, falling back to default VAE (${VAE_DEFAULT})"
                VAE=$VAE_DEFAULT
        fi

        __vae_img="VAE_MENU_IMG_$VAE"
        VAE_IMG=${!__vae_img}

        if [ -n "$VAE_IMG" ]
        then
                export SINGULARITY_CONTAINER=$VAE_IMG

                [ -z "$SSH_ORIGINAL_COMMAND" ] && \
                        echo "Virtual Application Environment launched: $(realpath $VAE_IMG)"
        fi

        exec ${VAE_IMG:+/usr/bin/singularity exec $VAE_IMG} \
                $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}
fi
