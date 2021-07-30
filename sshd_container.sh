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


# Load the container default configuration if present
#
SSHD_CONTAINER_CONFIG=${SSHD_CONTAINER_CONFIG:-/etc/default/sshd_container}
if test -f $SSHD_CONTAINER_CONFIG
then
        source $SSHD_CONTAINER_CONFIG
else
        _debug "$SSHD_CONTAINER_CONFIG configuration file missing"
fi

# Process the SINGULARITY_CONTAINER environment variable
#
case ${SINGULARITY_CONTAINER+x$SINGULARITY_CONTAINER} in
        # if the variable is set...
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
                if ! test -z "$SSHD_CONTAINER_DEFAULT"
                then
                        _debug "Using default container..."
                        SINGULARITY_CONTAINER=$SSHD_CONTAINER_DEFAULT
                # ...otherwise launch without a container
                else
                        _debug "No default container configuration..."
                        SINGULARITY_CONTAINER=none
                fi
                ;;
esac
_debug SINGULARITY_CONTAINER=$SINGULARITY_CONTAINER


# Present a menu if requested by the user...
#
if [ "$SINGULARITY_CONTAINER" == "menu" ]
then

        echo "Available containers"
        PS3="Select: "
        select opt in "${SSHD_CONTAINER_MENU[@]}"
        do
                SINGULARITY_CONTAINER=$opt
                break
        done
fi

# Determine the shell used by the user
shell=$(getent passwd $USER | cut -d : -f 7)

# If no container was selected or a container is not existing...
#
if [ "$SINGULARITY_CONTAINER" == "none" ]
then
        if [ -n "$SSH_ORIGINAL_COMMAND" ] 
        then
                _debug "User command line $SSH_ORIGINAL_COMMAND"
                exec $shell -l -c "$SSH_ORIGINAL_COMMAND"
        else
                # print the login banner
                cat /etc/motd
                exec $shell -l
        fi

#...launched into a containers
#
else
        if [ -n "$SSH_ORIGINAL_COMMAND" ] 
        then
                _debug "User command line $SSH_ORIGINAL_COMMAND"
                exec singularity exec \
                     $SSHD_CONTAINER_OPTIONS \
                     $SINGULARITY_CONTAINER $shell -l -c "$SSH_ORIGINAL_COMMAND"
        #...otherwise spawn a shell
        else
                # define a prompt for Bash users
                export SINGULARITYENV_PS1="\u@\h:\w > "
                # print the login banner
                cat /etc/motd
                echo Container launched: $(realpath $SINGULARITY_CONTAINER)
                exec singularity exec \
                     $SSHD_CONTAINER_OPTIONS \
                     $SINGULARITY_CONTAINER $shell -l
        fi
fi
