#!/bin/bash
#
# Script:   Deploy 2020
# Author:   Harry Oestreicher
# Email:    harryo1968@gmail.com
# Version:  2020-05-20
# Notes:    This script will recieve staging sites from old platform
#           and deploy them locally.
##############################################################################

EMAIL="email@address.com"
CONFIGS='/home/pusher/conf.d'
QUEUE="/home/pusher/incoming"
DEPLOY="/home/pusher/deploy"
TMP="/home/pusher/tmp"
LOGS="/home/pusher/logs"
LOGFILE=$LOGS"/deploy.log"
LOGLEVEL="INFO"

MUSER="pusher"
MPASS="******"
MHOST="localhost"

MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"
NOW=$(date +"%Y-%m-%d-%T")
TODAY=$(date +"%Y-%m-%d")
YESTERDAY=$(date --date="1 days ago" +"%Y-%m-%d")
DAY=$(date +"%a")

echo [$(date +"%Y-%m-%d %T")] --------------------------- DEPLOY JOB STARTED >> $LOGFILE
################################################################################################################################# METRICS CAPTURE
DEPLOYSTART=$(date +"%s")

CFG=$CONFIGS/*.conf
for c in $CFG
do

################################################################################################################################# METRICS CAPTURE
        SITESTART=$(date +"%s")

        . $c

        if [ "$SITEDEPLOY" != "YES" ]; then
                echo [$(date +"%Y-%m-%d %T")] "Starting: "$SITENAME "- DISABLED" >> $LOGFILE
                continue
        else

                echo [$(date +"%Y-%m-%d %T")] Starting: $SITENAME >> $LOGFILE

                PUSHDONE=$QUEUE"/"$SITENAME"_push.done"
                DEPLOYDONE=$DEPLOY"/"$SITENAME"_deploy.done"
                DEPLOYFAIL=$DEPLOY/$SITENAME"_deploy.failed"

                QUEDIR=$QUEUE/$SITENAME"_push."$TODAY
                YESTERQUEDIR=$QUEUE/$SITENAME"_push."$YESTERDAY
                DEPLOYDIR=$DEPLOY/$SITENAME-$TODAY

                if [ ! -f $PUSHDONE ];  then
                        echo [$(date +"%Y-%m-%d %T")] - last push incomplete...  skipping >> $LOGFILE
                        continue
                else
                        rm -f $PUSHDONE
                        if [ -f $DEPLOYFAIL ]; then
                                echo [$(date +"%Y-%m-%d %T")] ---- Last deplyment failed... skipping >> $LOGFILE
                                echo [$(date +"%Y-%m-%d %T")] ---- Please check QUEDIR and DEPLYDIR >> $LOGFILE
                                continue

                        else
                                echo [$(date +"%Y-%m-%d %T")] - Preparing files for deployment >> $LOGFILE
                                [ ! -d $DEPLOYDIR ] && mkdir -p $DEPLOYDIR || :
                                cd $DEPLOYDIR
                                FILES=$QUEDIR/*

                                if [ $LOGLEVEL = "DEBUG" ]; then
                                        echo [$(date +"%Y-%m-%d %T")] ---- DEBUG info for $SITENAME: >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- DEPLOYDIR: $DEPLOYDIR >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- QUEDIR: $QUEDIR >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEPUSH: $SITEPUSH >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEDEPLOY: $SITEDEPLOY >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEFQDN: $SITEFQDN >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEDB: $SITEDB >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEADMINHOME: $SITEADMINHOME >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEADMINWWW: $SITEADMINWWW >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEROOT: $SITEROOT >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEURI: $SITEURI >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITECONFIG: $SITECONFIG >> $LOGFILE
                                        echo [$(date +"%Y-%m-%d %T")] ---- SITEHTACCESS: $SITEHTACCESS >> $LOGFILE
                                fi

                                for f in $FILES
                                do
                                        if [[ $f = *"website"*".tar.gz" ]]; then
################################################################################################################################# METRICS CAPTURE
                                                WEBSTART=$(date +"%s")

                                                echo [$(date +"%Y-%m-%d %T")] - Extracting website >> $LOGFILE
                                                echo [$(date +"%Y-%m-%d %T")] ---- Preserving Site configuration >> $LOGFILE
                                                if [ ! -z $SITECONFIG ]; then
                                                        [ -f $SITECONFIG ] && cp -f $SITECONFIG $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI".config" || :                                        
                                                fi

                                                if [ ! -z $SITEHTACCESS ]; then
                                                        [ -f $SITEHTACCESS ] && cp -f $SITEHTACCESS $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI".htaccess" || :
                                                fi

######################################## CUSTOM PRESERVES ########################
                                                if [ $SITENAME = "ce9jury" ]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ---- ce9jury custom preserve >> $LOGFILE
                                                        [ -f $SITEROOT"/themes/garland/page.tpl.php" ] && cp -f $SITEROOT"/themes/garland/page.tpl.php" $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_page.tpl.php" || :
                                                        [ -f $SITEROOT"/modules/system/html.tpl.php" ] && cp -f $SITEROOT"/modules/system/html.tpl.php" $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_html.tpl.php" || :
                                                fi

                                                if [ $SITENAME = "ce9feeds" ]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ---- ce9feeds custom preserve >> $LOGFILE
                                                        [ -f $SITEROOT"/sites/all/themes/scraper_bootstrap/templates/system/html.tpl.php" ] && cp -f $SITEROOT"/sites/all/themes/scraper_bootstrap/templates/system/html.tpl.php" $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_html.tpl.php" || :
                                                fi
######################################## CUSTOM PRESERVES ########################

                                                if [[ $f = *"full"* ]]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ---- Full deployment >> $LOGFILE



                                                        if [ $SITEROOT = $SITEADMINWWW ]; then

                                                                [ ! -d $DEPLOYDIR"/public_html" ] && mkdir -p $DEPLOYDIR"/public_html" || :
                                                                tar --strip-components=3 -xzpf $f -C $DEPLOYDIR"/public_html"

                                                                rm -Rf $SITEADMINHOME"/public_html"
                                                                mv $DEPLOYDIR"/public_html" $SITEADMINHOME



                                                        else
                                                                [ ! -d $DEPLOYDIR"/public_html_"$SITEURI ] && mkdir -p $DEPLOYDIR"/public_html_"$SITEURI || :
                                                                #if [ $SITENAME = "ce9recruit" ]; then
                                                                tar --strip-components=3 -xzpf $f -C $DEPLOYDIR"/public_html_"$SITEURI
                                                                #else
                                                                #        tar --strip-components=1 -xzpf $f -C $DEPLOYDIR"/public_html_"$SITEURI
                                                                #fi
                                                                rm -Rf $SITEADMINHOME"/public_html_"$SITEURI
                                                                mv $DEPLOYDIR"/public_html_"$SITEURI $SITEADMINHOME"/public_html_"$SITEURI
                                                        fi




                                                elif [[ $f = *"incr"* ]]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ---- Incremental deployment >> $LOGFILE
                                                        if [ $SITEROOT = $SITEADMINWWW ]; then
                                                                #cd $DEPLOYDIR
                                                                tar --incremental --strip-components=3 -xzpf $f -C $DEPLOYDIR
                                                                cp -Rf $DEPLOYDIR"/public_html/"* $SITEADMINHOME"/"
                                                        else
                                                                [ ! -d $DEPLOYDIR"/public_html_"$SITEURI ] && mkdir -p $DEPLOYDIR"/public_html_"$SITEURI || :
                                                                #if [ $SITENAME = "ce9recruit" ]; then
                                                                tar --incremental --strip-components=3 -xzpf $f -C $DEPLOYDIR"/public_html_"$SITEURI
                                                                #else
                                                                #        tar --incremental --strip-components=1 -xzpf $f -C $DEPLOYDIR"/public_html_"$SITEURI
                                                                #fi 
                                                                cp -Rf $DEPLOYDIR"/public_html_"$SITEURI"/"* $SITEADMINHOME"/public_html_"$SITEURI
                                                        fi
                                                fi


######################################## CUSTOM RESTORES ########################
                                                if [ $SITENAME = "ce9jury" ]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ----  ce9jury custom restore... >> $LOGFILE
                                                        [ -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_page.tpl.php" ] && cp -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_page.tpl.php" $SITEROOT"/themes/garland/page.tpl.php" || :
                                                        [ -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_html.tpl.php" ] && cp -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_html.tpl.php" $SITEROOT"/modules/system/html.tpl.php" || :
                                                fi

                                                if [ $SITENAME = "ce9feeds" ]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ----  ce9feeds custom restore... >> $LOGFILE
                                                        [ -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_html.tpl.php" ] && cp -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI"_html.tpl.php" $SITEROOT"/sites/all/themes/scraper_bootstrap/templates/system/html.tpl.php" || :
                                                fi
######################################## CUSTOM RESTORES ########################


                                                echo [$(date +"%Y-%m-%d %T")] ---- Restoring Site configuration >> $LOGFILE
                                                cd $SITEADMINHOME
                                                if [ ! -z $SITECONFIG ]; then
                                                        [ -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI".config" ] && cp -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI".config" $SITECONFIG || :
                                                fi

                                                if [ ! -z $SITEHTACCESS ]; then
                                                        [ -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI".htaccess" ] && cp -f $DEPLOYDIR"/"$SITEFQDN"_"$SITEURI".htaccess" $SITEHTACCESS || :
                                                fi

################################################################################################################################# METRICS CAPTURE
                                                WEBEND=$(date +"%s")
                                                WEBDURATION="$((WEBEND-WEBSTART))"
                                                echo [$(date +"%Y-%m-%d %T")] ---- Finished - $WEBDURATION seconds >> $LOGFILE

                                        elif [[ $f = *"database"* ]]; then
################################################################################################################################# METRICS CAPTURE
                                                SQLSTART=$(date +"%s")
                                                echo [$(date +"%Y-%m-%d %T")] - Extracting databases >> $LOGFILE
                                                #echo [$(date +"%Y-%m-%d %T")] ---- Copying to DEPLOYDIR >> $LOGFILE
                                                cp $f $DEPLOYDIR
                                                #echo [$(date +"%Y-%m-%d %T")] ---- Unzipping file >> $LOGFILE
                                                $GZIP -d *database*
                                                SQLFILE=$(ls $DEPLOYDIR/*.sql)
                                                echo [$(date +"%Y-%m-%d %T")] ---- Starting MySQL import >> $LOGFILE
                                                $MYSQL -u $MUSER -h $MHOST -p$MPASS < $SQLFILE

################################################################################################################################# METRICS CAPTURE
                                                SQLEND=$(date +"%s")
                                                SQLDURATION="$((SQLEND-SQLSTART))"
                                                if [ "$?" != "0" ]; then
                                                        echo [$(date +"%Y-%m-%d %T")] ---- Error deploying databases >> $LOGFILE
                                                        echo [$(date +"%Y-%m-%d %T")] ---- that mess took $SQLDURATION seconds >> $LOGFILE
                                                        echo [$(date +"%Y-%m-%d %T")] ---- Sending alerts >> $LOGFILE
                                                        S=$TMP"/"$SITENAME"_"$SITEURI"_deploy.failed"
                                                        echo "Date: $(date)">$S
                                                        echo "Hostname: $hostname">>$S
                                                        echo "MySQL deploy failed">>$S
                                                        echo "SQL File: $SQLFILE">>$S
                                                        mail -s "MySQL deploy failed" "$EMAIL" <$S
                                                        rm -f $S
                                                        echo $(date +"%Y-%m-%d-%T") > $DEPLOY"/"$SITEFQDN"_"$SITEURI"_deploy.failed"
                                                        exit
                                                else
                                                        echo [$(date +"%Y-%m-%d %T")] ---- Finished - $SQLDURATION seconds >> $LOGFILE
                                                fi

                                        fi

                                        echo $(date +"%Y-%m-%d-%T") > $DEPLOYDONE

                                        #if [ $SITEROOT = $SITEADMINWWW ]; then
                                        #        echo $(date +"%Y-%m-%d-%T") > $DEPLOY"/"$SITEFQDN"_deploy.done"
                                        #else
                                        #        echo $(date +"%Y-%m-%d-%T") > $DEPLOY"/"$SITEFQDN"_"$SITEURI"_deploy.done"
                                        #fi

                                done

                                echo [$(date +"%Y-%m-%d %T")] - Performing cleanup >> $LOGFILE
                                [ -d $QUEDIR ] && rm -Rf $QUEDIR || :
                                [ -d $YESTERQUEDIR ] && rm -Rf $YESTERQUEDIR || : 
                                rm -Rf $DEPLOYDIR

                                [ -f $PUSHDONE ] && rm -f $PUSHDONE || :


                                #if [ $SITEROOT = $SITEADMINWWW ]; then
                                #        [ -f $DEPLOY"/"$SITEFQDN"_migrate.done" ] && rm -f $DEPLOY"/"$SITEFQDN"_migrate.done" || :
                                #else
                                #        [ -f $DEPLOY"/"$SITEFQDN"_"$SITEURI"_migrate.done" ] && rm -f $DEPLOY"/"$SITEFQDN"_"$SITEURI"_migrate.done" || :
                                #fi

                        fi

                fi

################################################################################################################################# METRICS CAPTURE
                SITEEND=$(date +"%s")
                SITEDURATION="$((SITEEND-SITESTART))"
                echo [$(date +"%Y-%m-%d %T")] Finished $SITENAME - $SITEDURATION seconds >> $LOGFILE
                echo [$(date +"%Y-%m-%d %T")]  >> $LOGFILE


        fi  ### END IF SITEPUSH

done

################################################################################################################################# METRICS CAPTURE
DEPLOYEND=$(date +"%s")
DEPLOYDURATION="$((DEPLOYEND-DEPLOYSTART))"
echo [$(date +"%Y-%m-%d %T")] DEPLOY JOB DURATION: $DEPLOYDURATION seconds >> $LOGFILE
echo [$(date +"%Y-%m-%d %T")] --------------------------- DEPLOY JOB FINISHED >> $LOGFILE
