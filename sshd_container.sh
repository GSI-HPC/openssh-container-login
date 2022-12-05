#
# Copyright 2021-2022 Victor Penso
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

VERSION=2.0

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

# ...Apptainer is not in PATH
if ! command -v apptainer >/dev/null
then
        SSHD_CONTAINER=none
fi

# Login to the root account...
#
if [ "$USER" == "root" ]
then
        # ...without launching a container
        SSHD_CONTAINER=none
fi

_debug "User defined APPTAINER_CONTAINER=$APPTAINER_CONTAINER"
# Process the SINGULARITY_CONTAINER environment variable
#
case ${APPTAINER_CONTAINER+x$APPTAINER_CONTAINER} in
        # if the variable is set...
	(x*[![:blank:]]*)
                case "$APPTAINER_CONTAINER" in
                (none|menu)
                        _debug "User explicitly selects none|menu"
                        ;;
                (*)
                        # check if container exits
                        if ! test -f $APPTAINER_CONTAINER
                        then
                                echo "Container $APPTAINER_CONTAINER missing"
                                SSHD_CONTAINER=none
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
                        SSHD_CONTAINER=$SSHD_CONTAINER_DEFAULT
                # ...otherwise launch without a container
                else
                        _debug "No default container configuration..."
                        SSHD_CONTAINER=none
                fi
                ;;
esac
_debug "Using container SSHD_CONTAINER=$SSHD_CONTAINER"


# Present a menu if requested by the user...
#
if [ "$SSHD_CONTAINER" == "menu" ]
then

        echo "Available containers"
        PS3="Select: "
        select opt in "${SSHD_CONTAINER_MENU[@]}"
        do
                SSHD_CONTAINER=$opt
                break
        done
fi

# Determine the shell used by the user
shell=$(getent passwd $USER | cut -d : -f 7)

# If no container was selected or a container is not existing...
#
if [ "$SSHD_CONTAINER" == "none" ]
then
        if [ -n "$SSH_ORIGINAL_COMMAND" ] 
        then
                _debug "User command line ## $SSH_ORIGINAL_COMMAND"
                exec $shell -l -c "$SSH_ORIGINAL_COMMAND"
        else
                # print the login banner
                test -f /etc/motd && cat /etc/motd
                exec $shell -l
        fi

#...launched into a containers
#
else
        # define a prompt for Bash users
        export APPTAINERENV_PS1="\u@\h:\w > "

        if [ -n "$SSH_ORIGINAL_COMMAND" ] 
        then
                _debug "User command line ## $SSH_ORIGINAL_COMMAND"
                exec $container_runtime exec \
                     $SSHD_CONTAINER_OPTIONS \
                     $SSHD_CONTAINER $shell -l -c "$SSH_ORIGINAL_COMMAND"

        #...otherwise spawn a shell
        else
                # print the login banner
                test -f /etc/motd && cat /etc/motd
                echo Container launched: $(realpath $SSHD_CONTAINER)
                exec $container_runtime exec \
                     $SSHD_CONTAINER_OPTIONS \
                     $SSHD_CONTAINER $shell -l
        fi
fi

