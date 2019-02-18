#!/bin/sh -x

# execute any pre-init scripts, useful for images
# based on this image
export TZ="America/Sao_Paulo"

for i in /usr/local/fop2/pre-init.d/*sh
do
        if [ -e "${i}" ]; then
                echo "[i] pre-init.d - processing $i"
                . "${i}"
        fi
done


# execute any pre-exec scripts, useful for images
# based on this image
for i in /usr/local/fop2/pre-exec.d/*sh
do
        if [ -e "${i}" ]; then
                echo "[i] pre-exec.d - processing $i"
                . "${i}"
        fi
done


exec "$@"
