#!/bin/bash
#
# Script:   Push 2020
# Author:   Harry Oestreicher
# Version:  2020-05-20
# Usage:    ./push.sh [ -full | incremenal(default) ]
# Changes:  Rewrite for RHEL7 platform. Replaced sFTP with SCP
#           Parameterized if CMS or just static HTML site
#############################################################################

EMAIL="email@address.com"
CONFIGS='/home/pusher/conf.d'
QUEUE="/home/pusher/outgoing"
LOGS="/home/pusher/logs"
LOGFILE=$LOGS"/push.log"

NOW=$(date +"%Y-%m-%d-%T")
TODAY=$(date +"%Y-%m-%d")
YESTERDAY=$(date --date="1 days ago" +"%Y-%m-%d")
DAY=$(date +"%a")

TUNNELCHECK=$(netstat -ntl | grep ":5000")

MUSER="pusher"
MPASS="******"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

SCP="$(which scp)"
SCPU="pusher"
SCPH="cloud-endpoint.aws.com"
SCPD="/home/pusher/incoming"

while [ $# -gt 0 ]
do
        case "$1" in
        -f) FULL="Yes";;
        -*) FULL="No"
                echo >&2 
                "usage: $0 [-f for full push] "
                exit 1;;
        *) FULL="No" break;;
        esac       
        shift
done

#if [ -n "$TUNNELCHECK" ]; then
#        echo [$(date +"%Y-%m-%d %T")] - Tunnel is open.  >> $LOGFILE
#else
#        echo [$(date +"%Y-%m-%d %T")] - Tunnel is closed. Can not push website >> $LOGFILE
#fi


echo [$(date +"%Y-%m-%d %T")] --------------------------- PUSH JOB STARTED >> $LOGFILE
################################################################################################################################# METRICS CAPTURE
PUSHSTART=$(date +"%s")


CFG=$CONFIGS/*.conf
for c in $CFG
do

################################################################################################################################# METRICS CAPTURE
        SITESTART=$(date +"%s")

        . $c

        if [ "$SITEPUSH" != "YES" ]; then
                echo [$(date +"%Y-%m-%d %T")] "Starting: "$SITENAME "- DISABLED" >> $LOGFILE
                echo [$(date +"%Y-%m-%d %T")]  >> $LOGFILE
                continue

        else
 
                echo [$(date +"%Y-%m-%d %T")] Starting: $SITENAME >> $LOGFILE
                PUSHDONE=$QUEUE"/"$SITENAME"_push.done"
                $SCP $SCPU@$SCPH:$SCPD/$PUSHDONE $QUEUE/

                if [ -f $PUSHDONE ]; then
                        echo [$(date +"%Y-%m-%d %T")] - last push incomplete... skipping >> $LOGFILE
                        rm -f $PUSHDONE
                        continue
                else
                        BUCKET=$QUEUE"/"$SITENAME"_push."$TODAY
                        BUCKET_OLD=$QUEUE"/"$SITENAME"_push."$YESTERDAY
                        FILE1=$SITENAME-website-$TODAY
                        FILE2=$SITENAME-database-$TODAY.sql.gz

                        [ -d $BUCKET_OLD ] && rm -Rf $BUCKET_OLD || :

                        if [ "$FULL" == "Yes" ]; then
################################################################################################################################# METRICS CAPTURE
                                FILESSTART=$(date +"%s")

                                echo [$(date +"%Y-%m-%d %T")] - Creating FULL archive >> $LOGFILE
                                rm -Rf $BUCKET
                                mkdir -p $BUCKET
                                tar -p --listed-incremental $BUCKET/$FILE1.snar --exclude-from=$SITEEXCLUDE -czpf $BUCKET/$FILE1"_full.tar.gz" -C $SITEADMINHOME $SITEROOT >> $LOGFILE
                                FILE1=$BUCKET/$FILE1"_full.tar.gz"
                        else
################################################################################################################################# METRICS CAPTURE
                                FILESSTART=$(date +"%s")

                                if [ ! -d $BUCKET ]; then
                                        mkdir -p $BUCKET
                                        echo [$(date +"%Y-%m-%d %T")] - Creating FULL archive >> $LOGFILE
                                        tar -p --listed-incremental $BUCKET/$FILE1.snar --exclude-from=$SITEEXCLUDE -czpf $BUCKET/$FILE1"_full.tar.gz" -C $SITEADMINHOME $SITEROOT >> $LOGFILE
                                        FILE1=$BUCKET/$FILE1"_full.tar.gz"

                                elif [ -f $BUCKET/$FILE1"_full.tar.gz" ]; then
                                        echo [$(date +"%Y-%m-%d %T")] - Creating first INCREMENTAL archive >> $LOGFILE
                                        rm -f $BUCKET/$FILE1"_full.tar.gz"
                                        rm -f $QUEUE"/"$SITENAME"_push.done"
                                        cp -f $BUCKET/$FILE1.snar $BUCKET/$FILE1.snar.bak
                                        tar -p --listed-incremental $BUCKET/$FILE1.snar.bak --exclude-from=$SITEEXCLUDE -czpf $BUCKET/$FILE1"_incr.tar.gz" -C $SITEADMINHOME $SITEROOT >> $LOGFILE
                                        FILE1=$BUCKET/$FILE1"_incr.tar.gz"

                                elif [ -f $BUCKET/$FILE1"_incr.tar.gz" ]; then
                                        echo [$(date +"%Y-%m-%d %T")] - Creating an INCREMENTAL archive >> $LOGFILE
                                        rm -f $BUCKET/$FILE1"_incr.tar.gz"
                                        rm -f $QUEUE"/"$SITENAME"_push.done"
                                        tar -p --listed-incremental $BUCKET/$FILE1.snar.bak --exclude-from=$SITEEXCLUDE -czpf $BUCKET/$FILE1"_incr.tar.gz" -C $SITEADMINHOME $SITEROOT >> $LOGFILE
                                        FILE1=$BUCKET/$FILE1"_incr.tar.gz"
                                else
                                        echo [$(date +"%Y-%m-%d %T")] - No updates since last push. >> $LOGFILE
                                        tar -p --listed-incremental $BUCKET/$FILE1.snar.bak --exclude-from=$SITEEXCLUDE -czpf $BUCKET/$FILE1"_incr.tar.gz" -C $SITEADMINHOME $SITEROOT >> $LOGFILE
                                        FILE1=$BUCKET/$FILE1"_incr.tar.gz"
                                fi

                        fi

################################################################################################################################# METRICS CAPTURE
                        FILESEND=$(date +"%s")
                        FILESDURATION="$((FILESEND-FILESSTART))"
                        echo [$(date +"%Y-%m-%d %T")] ---- Finished Files - $FILESDURATION seconds >> $LOGFILE


                        if [ ! -z "$SITEDB" ]; then
################################################################################################################################# METRICS CAPTURE
                                SQLSTART=$(date +"%s")
                                echo [$(date +"%Y-%m-%d %T")] - Dumping db: $SITEDB >> $LOGFILE
                                sudo $MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS --databases $SITEDB | $GZIP -9 > $BUCKET/$FILE2
################################################################################################################################# METRICS CAPTURE
                                SQLEND=$(date +"%s")
                                SQLDURATION="$((SQLEND-SQLSTART))"
                                if [ "$?" != "0" ]; then
                                        echo [$(date +"%Y-%m-%d %T")] - Error dumping db >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- DB Finished in $SQLDURATION seconds >> $LOGFILE
                                        T=$QUEUE"/"$SITENAME"_mysqldump.failed"
                                        echo "Date: $(date)">$T
                                        echo "Hostname: $(hostname)" >>$T
                                        echo "MySQL dump failed for $SITENAME" >>$T
                                        mail  -s "MySQL FAILED for $SITENAME:$SITEDB" "$EMAIL" <$T
                                else
                                        echo [$(date +"%Y-%m-%d %T")] ---- DB Finished in $SQLDURATION seconds >> $LOGFILE
                                fi

                        fi

                        FILE2=$BUCKET/$FILE2
                        echo $(date +"%Y-%m-%d-%T") > $PUSHDONE
                        echo [$(date +"%Y-%m-%d %T")] - Sending files to DMZ >> $LOGFILE

                        if [ "$FULL" == "Yes" ]; then
                                $SCP -pr $BUCKET $SCPU@$SCPH:$SCPD/
                                $SCP $PUSHDONE $SCPU@$SCPH:$SCPD/
                        else
                                $SCP -pr $BUCKET $SCPU@$SCPH:$SCPD/
                                $SCP $PUSHDONE $SCPU@$SCPH:$SCPD/
                        fi

                        rm -f $PUSHDONE

                fi

################################################################################################################################# METRICS CAPTURE
                SITEEND=$(date +"%s")
                SITEDURATION="$((SITEEND-SITESTART))"
                echo [$(date +"%Y-%m-%d %T")] Finished $SITENAME - $SITEDURATION seconds >> $LOGFILE
                echo [$(date +"%Y-%m-%d %T")]  >> $LOGFILE

        fi

done

################################################################################################################################# METRICS CAPTURE
PUSHEND=$(date +"%s")
PUSHDURATION="$((PUSHEND-PUSHSTART))"
echo [$(date +"%Y-%m-%d %T")] PUSH JOB DURATION: $PUSHDURATION seconds >> $LOGFILE
echo [$(date +"%Y-%m-%d %T")] --------------------------- PUSH JOB FINISHED >> $LOGFILE
