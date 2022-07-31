#!/bin/sh
#
##############################################################################
### BACKUP WEBSITES
##
##  Author:   Harry Oestreicher : 9th Circuit Executives Office
##  Email:    hoestreicher@ce9.uscourts.gov
##  Version:  1.1
##############################################################################

## Define Parameters
#EMAIL="hoestreicher@ce9.uscourts.gov"
MYSQLUSER="root"
MYSQLPASS="0aksF429"
MYSQLHOST="localhost"
DBLIST=""

SOURCE="/home"

NOW=$(date +"%Y-%m-%d-%T")
TODAY=$(date +"%Y-%m-%d")
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"
HOST="$(hostname)"
TMP=${HOME}/tmp
TARGET=${HOME}/archive
LOG=${TARGET}/log
LOGFILE=${LOG}/${HOST}_website-backup.log
BUCKET=${TARGET}/website_archives/${TODAY}

echo [$(date +"%Y-%m-%d %T")] --Starting website backup >> $LOGFILE

## Create working directory if it doesn't exist
[ ! -d $BUCKET ] && mkdir $BUCKET || :

##############################################################################
### 1. Get users, groups and passwords

#echo [$(date +"%Y-%m-%d %T")] - creating backups of passwd, group and shadow files >> $LOGFILE
#export UGIDLIMIT=500
#awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/passwd > $TEMP/move/$HOSTNAME-passwd.mig
#awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/group > $TEMP/move/$HOSTNAME-group.mig
#awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534) {print $1}' /etc/passwd | tee - |egrep -f - /etc/s
#echo [$(date +"%Y-%m-%d %T")] - done >> $LOGFILE

##############################################################################
### 2. Put content into archives

for DIR in ${SOURCE}/*/
do
    if [ $DIR != "/home/lost+found/" ]; then
        DIR=${DIR%*/}
        DIR=${DIR##*/}
        echo [$(date +"%Y-%m-%d %T")] - backing up ${DIR} >> $LOGFILE
        tar -zcvpf ${BUCKET}/${DIR}_website-backup_${TODAY}.tar.gz ${SOURCE}/${DIR}
#        echo ${DIR} > ${BUCKET}/${DIR}_${HOST}_${TODAY}.test
#        echo [$(date +"%Y-%m-%d %T")] - done >> $LOGFILE

    fi
done

##############################################################################
### 3. Backup all MySQL databases to .sql script

echo [$(date +"%Y-%m-%d %T")] - backing up ALL databases >> $LOGFILE
$MYSQLDUMP -u $MYSQLUSER -h $MYSQLHOST -p$MYSQLPASS --all-databases --events | $GZIP -9 > ${BUCKET}/${HOST}
if [ "$?" != "0" ]; then
  echo [$(date +"%Y-%m-%d %T")] - mysql dump FAILED. Sending notifications. >> $LOGFILE
  T=${TMP}/${HOST}-mysqldump.fail
  echo "Date: $(date)">$T
  echo "Hostname: ${HOST}" >>$T
#  echo "MySQL dump failed for $ID" >>$T
  mail  -s "MySQL website backup dump failed for ${HOST}" "$EMAIL" <$T
  rm -f $T
fi
echo [$(date +"%Y-%m-%d %T")] - mysql backup done >> $LOGFILE

##############################################################################
### 4. Get entire apache and pure-ftpd configuration

echo [$(date +"%Y-%m-%d %T")] - backing up apache configs >> $LOGFILE
#/etc/init.d/httpd stop
tar -zcvpf ${BUCKET}/${HOST}_apache-config.tar.gz /etc/httpd
#/etc/init.d/httpd start
echo [$(date +"%Y-%m-%d %T")] - finished backing up apache configs >> $LOGFILE


echo [$(date +"%Y-%m-%d %T")] --Finished website backup >> $LOGFILE

exit

