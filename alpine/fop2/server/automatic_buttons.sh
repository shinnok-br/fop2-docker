#/bin/bash

for EXTEN in `mysql -h 172.17.0.1 -u snep -psneppass snep -e 'select name from peers' | grep -v name`
do

echo "[SIP/$EXTEN]"
echo "type=extension"
echo "extension=$EXTEN"
echo "context=default"
echo "label=Ramal $EXTEN"
done
