#!/bin/bash

if [ $1 ]
then
	tag=":$1"
else
	tag=":latest"
fi

options=$2

echo -en "Building docker image ..."
docker build -t shinnok/fop2-docker${tag} $options .
echo done
