#!/bin/bash
#
# Script:   Push-Site 2020
# Author:   Harry Oestreicher
# Version:  2020-05-20
# Usage:    ./push-site.sh -c <path-to-config-file> [options]
#
# Changes:  Rewrite for RHEL7 platform. Replaced sFTP with SCP
#           Parameterized if CMS or just static HTML site 
#############################################################################

EMAIL="email@address.com"
CONFIGS='/home/pusher/conf.d'
QUEUE="/home/pusher/outgoing"
LOGS="/home/pusher/logs"
LOGFILE=$LOGS"/push-site.log"

NOW=$(date +"%Y-%m-%d-%T")
TODAY=$(date +"%Y-%m-%d")
YESTERDAY=$(date --date="1 days ago" +"%Y-%m-%d")
DAY=$(date +"%a")

TUNNELCHECK=$(netstat -ntl | grep ":5000")

########################## MySQL Credentials
### 'pusher' account must have Select and Lock Tables privileges

MUSER="pusher"
MPASS="7Miss429~"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

########################## OS Credentials (on remote)
### FYI: The 'pusher' account must be added to each users' group in /etc/group
### Also, all communication uses private key authentication. No passwords.

SCP="$(which scp)"
SCPU="pusher"
SCPH="ce9web.jcn.ao.dcn"
SCPD="/home/pusher/incoming"


### Check that we have a tunnel open on :5000
#if [ -n "$TUNNELCHECK" ]; then
#        echo [$(date +"%Y-%m-%d %T")] - Tunnel is open.  >> $LOGFILE
#else
#        echo [$(date +"%Y-%m-%d %T")] - Tunnel is closed. Can not push website >> $LOGFILE
#fi

helpFunction()
{
   echo "Usage:"
   echo -e "\t $0 -c <path-to-config> [options]"
   echo "Options:"
   echo -e "\t-f Do a Full push."
   exit 1 # Exit script after printing help
}

while getopts "c:f" opt
do
   case "$opt" in
      c ) conf="$OPTARG" ;;
      f ) FULL="Yes" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$conf" ]
then
   echo "The config file must be specified.";
   helpFunction
fi


#########################################################
### Begin Individual site push based on config
echo [$(date +"%Y-%m-%d %T")] --------------------------- SITE-PUSH started >> $LOGFILE

. $conf
if [ -f $conf ]; then

        echo [$(date +"%Y-%m-%d %T")] Starting: $SITENAME >> $LOGFILE
        #echo "$(cat $f)" >> $LOGFILE
        #echo SITEADMIN: $SITEADMIN >> $LOGFILE

        #############################################
        ##  1. First check if previous push has been deployed yet
        echo [$(date +"%Y-%m-%d %T")] - Checking status of last push >> $LOGFILE
        PUSH=$SITENAME"_push.done"
        $SCP $SCPU@$SCPH:$SCPD/$PUSH $QUEUE/
        if [ -f $QUEUE"/"$SITENAME"_push.done" ]; then
                echo [$(date +"%Y-%m-%d %T")] - "Not deployed yet. Waiting for next push" >> $LOGFILE
                rm -f $QUEUE"/"$SITENAME"_push.done"
                echo [$(date +"%Y-%m-%d %T")] Finished processing: $SITENAME >> $LOGFILE
                echo [$(date +"%Y-%m-%d %T")] --------------------------- SITE-PUSH ended >> $LOGFILE
                exit
        fi

        #############################################
        ##  2. Begin processing site and database

        BUCKET=$QUEUE"/"$SITENAME"_push."$TODAY
        BUCKET_OLD=$QUEUE"/"$SITENAME"_push."$YESTERDAY
        FILE1=$SITENAME-website-$TODAY
        FILE2=$SITENAME-database-$TODAY.sql.gz

        #echo [$(date +"%Y-%m-%d %T")] Archiving: $SITENAME >> $LOGFILE
        if [ "$FULL" == "Yes" ]; then
                echo [$(date +"%Y-%m-%d %T")] - Creating FULL archive >> $LOGFILE
                rm -Rf $BUCKET
                mkdir -p $BUCKET
                tar -p --listed-incremental $BUCKET/$FILE1.snar --exclude-from=$SITEEXCLUDE -czpf $BUCKET/$FILE1"_full.tar.gz" -C $SITEADMINHOME $SITEROOT >> $LOGFILE
                FILE1=$BUCKET/$FILE1"_full.tar.gz"
        else
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

        if [ ! -z "$SITEDB" ]; then
                echo [$(date +"%Y-%m-%d %T")] - Dumping db: $SITEDB >> $LOGFILE
                SQL1=$(date +"%s")
                sudo $MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS --databases $SITEDB | $GZIP -9 > $BUCKET/$FILE2
                SQL2=$(date +"%s")
                SQL3="$((SQL2-SQL1))"

                if [ "$?" != "0" ]; then
                        echo [$(date +"%Y-%m-%d %T")] - Error dumping db >> $LOGFILE
                        echo [$(date +"%Y-%m-%d %T")] - MySQLDump took: $SQL3 seconds >> $LOGFILE
                        T=$QUEUE"/"$SITENAME"_mysqldump.failed"
                        echo "Date: $(date)">$T
                        echo "Hostname: $(hostname)" >>$T
                        echo "MySQL dump failed for $SITENAME" >>$T
                        mail  -s "MySQL FAILED for $SITENAME:$SITEDB" "$EMAIL" <$T
                else
                        echo [$(date +"%Y-%m-%d %T")] - MySQLDump took: $SQL3 seconds >> $LOGFILE
                fi

        fi
        FILE2=$BUCKET/$FILE2


        #############################################
        ##  3. Send file to remote system
        echo $(date +"%Y-%m-%d-%T") > $QUEUE"/"$SITENAME"_push.done"
        STAMP=$QUEUE"/"$SITENAME"_push.done"
        echo [$(date +"%Y-%m-%d %T")] - Sending files to DMZ >> $LOGFILE

        if [ "$FULL" == "Yes" ]; then
                $SCP -pr $BUCKET $SCPU@$SCPH:$SCPD/
                $SCP $STAMP $SCPU@$SCPH:$SCPD/
        else
                $SCP -pr $BUCKET $SCPU@$SCPH:$SCPD/
                $SCP $STAMP $SCPU@$SCPH:$SCPD/
        fi

        echo [$(date +"%Y-%m-%d %T")] Finishing: $SITENAME >> $LOGFILE
	rm -f $STAMP
else
        echo [$(date +"%Y-%m-%d %T")] There is a problem with the site push config file. >> $LOGFILE
        echo [$(date +"%Y-%m-%d %T")] --------------------------- SITE-PUSH ended >> $LOGFILE
        exit
fi

echo [$(date +"%Y-%m-%d %T")] --------------------------- SITE-PUSH ended >> $LOGFILE

rm -f 1
exit 0
