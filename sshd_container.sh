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


_debug() {
        if [ "$SSHD_CONTAINER_DEBUG" = "true" ]; then
                echo 1>&2 "Debug: $@"
        fi
}

_error() {
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


# load the container default configuration if present
if test -f $SSHD_CONTAINER_CONFIG
then
        source $SSHD_CONTAINER_CONFIG
else
        _debug "$SSHD_CONTAINER_CONFIG configuration file missing"
fi

shell=$(getent passwd $USER | cut -d : -f 7)

case ${SINGULARITY_CONTAINER+x$SINGULARITY_CONTAINER} in
	(x*[![:blank:]]*)
                # is set...
                ;;
	(x|""|*)
                # if empty, unset or blank set the default
                SINGULARIY_CONTAINER=${SINGULARIY_CONTAINER:-none}
                ;;
esac

if [ "$SINGULARITY_CONTAINER" == "none" ]
then
        echo "No singularity container defined"
        $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}

# if a singularity container is defined...
else
        if test -f $SINGULARITY_CONTAINER
        then
                echo $SINGULARITY_CONTAINER
                echo exec singularity exec $SINGULARITY_CONTAINER \
                        $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}
        else
                _error "Container $SINGULARITY_CONTAINER missing"
        fi
fi
