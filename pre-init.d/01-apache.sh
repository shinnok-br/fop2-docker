#!/bin/sh

pid=/var/run/apache2/apache2.pid
if [ -f $pid ]
then
        rm -f $pid
fi

/etc/init.d/apache2 start
