#!/usr/bin/env bash

VERSION=0.1

_debug() {
        if [ "$SSHD_CONTAINER_DEBUG" = "true" ]; then
                echo 1>&2 "Debug: $@"
        fi
}

_error() {
        echo 1>&2 "Error: $@"
	exit 1
}

SSHD_CONTAINER_CONFIG={SSHD_CONTAINER_CONFIG:-/etc/default/sshd_container}

# load the container default configuration if present
if test -f $SSHD_CONTAINER_CONFIG
then
        source $SSHD_CONTAINER_CONFIG
else
        _debug "$SSHD_CONTAINER_CONFIG configuration file missing"
fi

case ${SINGULARITY_CONTAINER+x$SINGULARITY_CONTAINER} in
        # is set...
	(x*[![:blank:]]*)
                case "$SINGULARITY_CONTAINER" in
                (none|menu)
                        _debug "User explicitly selects none|menu"
                        ;;
                (*)
                        # check if container exits
                        if ! test -f $SINGULARITY_CONTAINER
                        then
                                echo "Container $SINGULARITY_CONTAINER missing"
                                SINGULARITY_CONTAINER=none
                        fi
                        ;;
                esac
                ;;
        # if empty, unset or blank use the default container if possible
	(x|""|*)
                # if the default is set...
                if ! test -z "$SINGULARITY_CONTAINER_DEFAULT"
                then
                        _debug "Using default container..."
                        SINGULARITY_CONTAINER=$SINGULARITY_CONTAINER_DEFAULT
                else
                        _debug "No default container configuration..."
                        SINGULARITY_CONTAINER=none
                fi
                ;;
esac
_debug SINGULARITY_CONTAINER=$SINGULARITY_CONTAINER

shell=$(getent passwd $USER | cut -d : -f 7)

if [ "$SINGULARITY_CONTAINER" == "none" ]
then
        echo "No singularity container defined"
        $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}

# if a singularity container is defined...
else
        if test -f $SINGULARITY_CONTAINER
        then
                echo exec singularity exec $SINGULARITY_CONTAINER \
                        $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}
        else
                _error "Container $SINGULARITY_CONTAINER missing"
        fi
fi
