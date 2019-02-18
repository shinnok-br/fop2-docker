#!/bin/bash
MANAGERUSER=fop2
MANAGERSECRET=supersecret
MANAGERHOST=localhost
/usr/local/fop2/astcli -u $MANAGERUSER -s $MANAGERSECRET -h $MANAGERHOST "sip show peers" |  sed '/Monitored/d' |sed '/Name\/username/d' | sort | while read LINEA
do
EXTEN=`echo $LINEA | cut -d\/ -f 1`
EXTEN=`echo $EXTEN | awk '{ print $1}'`
CONTEXT=`/usr/local/fop2/astcli -u $MANAGERUSER -s $MANAGERSECRET -h $MANAGERHOST "sip show peer $EXTEN" | grep Context | cut  -d: -f 2 | sed 's/ //g'` 
CIDNAME=`/usr/local/fop2/astcli -u $MANAGERUSER -s $MANAGERSECRET -h $MANAGERHOST "sip show peer $EXTEN" | grep Callerid | cut  -d: -f 2 | cut -d\< -f 1 | sed 's/ "//g' | sed 's/"//g'`
MAILBOX=`/usr/local/fop2/astcli -u $MANAGERUSER -s $MANAGERSECRET -h $MANAGERHOST "sip show peer $EXTEN" | grep Mailbox | cut  -d: -f 2 | sed 's/ //g'` 
echo "[SIP/$EXTEN]"
echo "type=extension"
echo "extension=$EXTEN"
echo "context=$CONTEXT"
echo "label=$CIDNAME"
echo "mailbox=$MAILBOX"
echo
done

for A in `cat /etc/asterisk/queues.conf  | grep "^\[" | grep -v general |sed 's/\[//' | sed 's/\]//'`
do
echo "[QUEUE/$A]"
echo "type=queue"
echo "extension=0"
echo "context=context"
echo "label=$A"
echo
done

