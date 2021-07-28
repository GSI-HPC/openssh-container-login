shell=$(getent passwd $USER | cut -d : -f 7)

test -f /etc/default/sshd-container && source /etc/default/sshd-container

VAE=${VAE:-$VAE_DEFAULT}

if [ "$VAE" == "none" ]
then
        $shell -l ${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}
fi

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
