#!/bin/bash

if [ -e /etc/freepbx.conf ]; then
DBNAME=`cat /etc/freepbx.conf | sed 's/ //g' | grep ^AMPDBNAME | cut -d= -f2 | tail -n1`
DBUSER=`cat /etc/freepbx.conf | sed 's/ //g' | grep ^AMPDBUSER | cut -d= -f2 | tail -n1`
DBPASSLINE=`cat /etc/freepbx.conf | grep ^AMPDBPASS | tail -n1`
DBSTRIP=`echo $DBPASSLINE | cut -d= -f1`
DBPASS=`echo $DBPASSLINE | sed "s/$DBSTRIP=//g"`
DBHOST=`cat /etc/freepbx.conf | sed 's/ //g' | grep ^AMPDBHOST | cut -d= -f2 | tail -n1`

elif [ -e /etc/amportal.conf ]; then
DBNAME=`cat /etc/amportal.conf | sed 's/ //g' | grep ^AMPDBNAME | cut -d= -f2 | tail -n1`
DBUSER=`cat /etc/amportal.conf | sed 's/ //g' | grep ^AMPDBUSER | cut -d= -f2 | tail -n1`
DBPASSLINE=`cat /etc/amportal.conf | grep ^AMPDBPASS | tail -n1`
DBSTRIP=`echo $DBPASSLINE | cut -d= -f1`
DBPASS=`echo $DBPASSLINE | sed "s/$DBSTRIP=//g"`
DBHOST=`cat /etc/amportal.conf | sed 's/ //g' | grep ^AMPDBHOST | cut -d= -f2 | tail -n1`

elif [ -e /var/thirdlane_load/pbxportal-ast.sysconfig ]; then
DBNAME='pbxconf'
DBHOST='localhost'
DBUSER=`cat /var/thirdlane_load/pbxportal-ast.sysconfig | sed 's/ //g' | grep ^DBUSER | cut -d= -f2 | tail -n1`
DBPASSLINE=`cat /var/thirdlane_load/pbxportal-ast.sysconfig | grep ^DBPASS | tail -n1`
DBSTRIP=`echo $DBPASSLINE | cut -d= -f1`
DBPASS=`echo $DBPASSLINE | sed "s/$DBSTRIP=//g"`

elif [ -e /opt/pbxware/pw/etc/pbxware/pbxware.ini  ]; then

DBNAME='pbxware'
DBHOST=`cat /opt/pbxware/pw/etc/pbxware/pbxware.ini | sed 's/ //g' | grep ^pw_mysql_host | cut -d= -f2 | tail -n1`
DBUSER=`cat /opt/pbxware/pw/etc/pbxware/pbxware.ini | sed 's/ //g' | grep ^pw_mysql_username | cut -d= -f2 | tail -n1`
DBPASSLINE=`cat /opt/pbxware/pw/etc/pbxware/pbxware.ini | grep ^pw_mysql_password | tail -n1`
DBSTRIP=`echo $DBPASSLINE | cut -d= -f1`
DBPASS=`echo $DBPASSLINE | sed "s/$DBSTRIP=//g"`

elif [ -e /etc/kamailio/kamailio-mhomed-elastix.cfg ]; then

DBNAME='elxpbx'
DBHOST='localhost'
DBPASS=`grep mysqlroot /etc/elastix.conf | cut -d= -f2 | tail -n1`
DBUSER='root'

elif [ -e /var/www/html/fop2/admin/config.php ]; then

DBNAME=`cat /var/www/html/fop2/admin/config.php | sed 's/ //g' | grep ^\\$DBNAME | cut -d= -f2 | tail -n1`
DBUSER=`cat /var/www/html/fop2/admin/config.php | sed 's/ //g' | grep ^\\$DBUSER | cut -d= -f2 | tail -n1`
DBPASSLINE=`cat /var/www/html/fop2/admin/config.php | grep ^\\$DBPASS | tail -n1`
DBSTRIP=`echo $DBPASSLINE | cut -d= -f1`
DBPASS=`echo $DBPASSLINE | sed "s/$DBSTRIP=//g"`
DBHOST=`cat /var/www/html/fop2/admin/config.php | sed 's/ //g' | grep ^\\$DBHOST | cut -d= -f2 | tail -n1`
DBNAME=${DBNAME:1}
DBNAME=${DBNAME%??}
DBUSER=${DBUSER:1}
DBUSER=${DBUSER%??}
DBPASS=${DBPASS:1}
DBPASS=${DBPASS%??}
DBHOST=${DBHOST:1}
DBHOST=${DBHOST%??}


else
DBHOST='none'
fi

if [ "x$DBPASS" != "x" ]; then
DBPASS="-p${DBPASS}"
fi

if [ -d /var/www/html/admin/modules/fop2admin/plugins ]; then
PLUGINDIR=/var/www/html/admin/modules/fop2admin/plugins
fi

if [ -d /var/www/html/fop2/admin/plugins ]; then
PLUGINDIR=/var/www/html/fop2/admin/plugins
fi

hash_insert () {
local name=$1 key=$2 val=$3
eval __hash_${name}_${key}=$val
}

hash_find () {
local name=$1 key=$2
local var=__hash_${name}_${key}
MICLAVE=${!var}
}

eval `cat /etc/asterisk/voicemail.conf | grep -v "^\;" | grep "=>" | cut -d, -f1 | sed 's/ //g' | sed  's/\([^=]*\)=>\(.*\)/hash_insert claves "\1" "\2";/g'`

# For multi server setups, reading groups from remote servers
# eval `ssh root@10.0.0.1 /usr/local/fop2/autoconfig-users.sh | grep group | sed 's/ /_/g' | sed  's/\([^=]*\)=\([^:]*\):\(.*\)/hash_insert grupos "\2" "\3";/g'`

FOP2ADMIN=0
FOP2PLUGIN=0

# Only check for table presence if mysql connection is ok
mysql -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "SELECT now()" &>/dev/null
if [ $? == 0 ]; then
# Verify if the fop2admin table exists for fop2manager/fop2admin
while read line; do
let FOP2ADMIN=FOP2ADMIN+1
done < <( mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "SHOW tables FROM \`$DBNAME\` LIKE 'fop2users'";  )

# Verify if the fop2 plugins table exists
while read line; do
let FOP2PLUGIN=FOP2PLUGIN+1
done < <( mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "SHOW tables FROM \`$DBNAME\` LIKE 'fop2plugins'" )
else
echo "; Problem connecting to mysql, using voicemail.conf as base user config"
echo
fi


if [ "$FOP2PLUGIN" -gt 0 ]; then
# Query including plugins from latest fop2manager/fop2admin
MAINQUERY="set @@group_concat_max_len=32768; SELECT CONCAT('user=',fop2users.exten,':',if(secret='','EMPTYSECRET',secret),':',permissions,':',(select IF(group_concat(fop2groups.name) is NULL,'',group_concat(fop2groups.name)) from fop2UserGroup LEFT OUTER JOIN fop2groups on fop2groups.id=fop2UserGroup.id_group where fop2UserGroup.exten=fop2users.exten),':') as user, (select IF(group_concat(fop2plugins.rawname) is NULL,'',group_concat(fop2plugins.rawname)) from fop2UserPlugin LEFT OUTER JOIN fop2plugins on fop2plugins.rawname=fop2UserPlugin.id_plugin WHERE fop2UserPlugin.exten=fop2users.exten) as plg1, (SELECT concat('aapa',IF(group_concat(rawname) is NULL,'',group_concat(rawname))) FROM fop2plugins WHERE global=1 limit 1) as plg2 FROM fop2users LEFT JOIN fop2contexts ON context_id=fop2contexts.id WHERE %CONDITION%"
else
# Query without including plugins from latest fop2manager/fop2admin
MAINQUERY="set @@group_concat_max_len=32768; SELECT CONCAT('user=',fop2users.exten,':',if(secret='','EMPTYSECRET',secret),':',permissions,':',(select IF(group_concat(fop2groups.name) is NULL,'',group_concat(fop2groups.name)) from fop2UserGroup left outer join fop2groups on fop2groups.id=fop2UserGroup.id_group where fop2UserGroup.exten=fop2users.exten),':') FROM fop2users"
fi

if [ "$FOP2ADMIN" -gt 0 ]; then
# We have the fop2manager tables, use sql queries to retrieve user conf
mysql -NB --raw -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "SELECT value FROM fop2settings" | while read LINEA
do
echo $LINEA
done

echo "; Plugins"
echo

if [ -d $PLUGINDIR ]; then
for PDIR in $PLUGINDIR/*
do
if [ -d $PDIR ]; then
subdir=`basename ${PDIR}`
echo "plugin=$subdir:$PDIR"
fi
done
fi
echo

CONT=0
while read CONTEXT; do
let CONT=CONT+1
echo "[$CONTEXT]"

echo
echo "; Permissions"
echo

PERMQUERY="set @@group_concat_max_len=32768; SELECT CONCAT('perm=',fop2permissions.name,':',permissions,':',IF(isnull(GROUP_CONCAT(device)),'',GROUP_CONCAT(device))) FROM fop2permissions LEFT JOIN fop2PermGroup ON fop2permissions.name=fop2PermGroup.name LEFT JOIN fop2GroupButton ON fop2GroupButton.group_name=name_group left join fop2buttons ON id_button=fop2buttons.id LEFT JOIN fop2contexts ON fop2permissions.context_id=fop2contexts.id WHERE %CONDITION% GROUP BY fop2permissions.name" 
mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "${PERMQUERY/\%CONDITION\%/fop2contexts.context='$CONTEXT'}" | while read LINEA
do
echo $LINEA
done

echo
echo "; Groups"
echo

GROUPQUERY="set @@group_concat_max_len=32768; SELECT CONCAT('group=',group_name,':',GROUP_CONCAT(device)) FROM fop2GroupButton JOIN fop2buttons ON id_button=fop2buttons.id LEFT JOIN fop2contexts ON fop2buttons.context_id=fop2contexts.id WHERE id_button IS NOT NULL AND %CONDITION% GROUP BY group_name"
mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "${GROUPQUERY/\%CONDITION\%/fop2contexts.context='$CONTEXT'}" | while read LINEA
do
# For multi server setups, read group
# MYEXTEN=`echo $LINEA | cut -d= -f2 | cut -d:  -f1| sed 's/ /_/g'`
# hash_find grupos "${MYEXTEN}" 
# echo $LINEA,$MICLAVE
echo $LINEA
done

echo
echo "; Users"
echo

mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "${MAINQUERY/\%CONDITION\%/context='$CONTEXT'}" | while read LINEA
do
MYEXTEN=`echo $LINEA | cut -d: -f1 | cut -d\= -f2`
hash_find claves "${MYEXTEN}" 
echo -n $LINEA | sed -e 's/EMPTYSECRET/'${MICLAVE}'/g' -e 's/ aapa/,/g' -e 's/: /:/g' -e 's/:,/:/g' -e 's/,$//g'
echo
done
echo
echo "buttonfile=autobuttons.cfg $CONTEXT"
echo ";----------------------------------------------"
echo
done < <(mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "SELECT context FROM fop2contexts ORDER BY context")

# For single tenant setups (no panel context defined)
if [ $CONT == 0 ]; then

    echo
    echo "; Permissions"
    echo
 
    PERMQUERY="set @@group_concat_max_len=32768; SELECT CONCAT('perm=',fop2permissions.name,':',permissions,':',IF(isnull(GROUP_CONCAT(device)),'',GROUP_CONCAT(device))) FROM fop2permissions LEFT JOIN fop2PermGroup ON fop2permissions.name=fop2PermGroup.name LEFT JOIN fop2GroupButton ON fop2GroupButton.group_name=name_group left join fop2buttons ON id_button=fop2buttons.id LEFT JOIN fop2contexts ON fop2permissions.context_id=fop2contexts.id WHERE %CONDITION% GROUP BY fop2permissions.name" 

    mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "${PERMQUERY/\%CONDITION\%/1=1}" | while read LINEA
    do
    echo $LINEA
    done

    echo
    echo "; Groups"
    echo


    GROUPQUERY="set @@group_concat_max_len=32768; SELECT CONCAT('group=',group_name,':',GROUP_CONCAT(device)) FROM fop2GroupButton JOIN fop2buttons ON id_button=fop2buttons.id LEFT JOIN fop2contexts ON fop2buttons.context_id=fop2contexts.id WHERE id_button IS NOT NULL AND %CONDITION% GROUP BY group_name"
    mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "${GROUPQUERY/\%CONDITION\%/1=1}" | while read LINEA
    do
    # For multi server setups, read group
    # MYEXTEN=`echo $LINEA | cut -d= -f2 | cut -d:  -f1| sed 's/ /_/g'`
    # hash_find grupos "${MYEXTEN}" 
    # echo $LINEA,$MICLAVE
    echo $LINEA
    done

    echo
    echo "; Users"
    echo

    mysql -NB -u $DBUSER $DBPASS -h $DBHOST $DBNAME -e "${MAINQUERY/\%CONDITION\%/1=1}" | while read LINEA
    do
    MYEXTEN=`echo $LINEA | cut -d: -f1 | cut -d\= -f2`
    hash_find claves "${MYEXTEN}" 
    echo -n $LINEA | sed -e 's/EMPTYSECRET/'${MICLAVE}'/g' -e 's/ aapa/,/g' -e 's/: /:/g' -e 's/:,/:/g' -e 's/,$//g'
    echo
    done
    echo
    echo "buttonfile=autobuttons.cfg $CONTEXT"
fi

else
# We do not have mysql tables for fop2manager/fop2admin, reads voicemail conf and uses that as users
# with full permissions
for A in `cat /etc/asterisk/voicemail.conf | grep "=>" | grep -v "^\;" | cut -d, -f1 | sed 's/ => /:/g'`; do echo user=$A:all; done

fi

