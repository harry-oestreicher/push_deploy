#!/bin/sh
#
##############################################################################
### EXPIRE HTTPD LOGS
##
##  Author:   Harry Oestreicher : 9th Circuit Executives Office
##  Email:    hoestreicher@ce9.uscourts.gov
##  Version:  1
##############################################################################

EMAIL="hoestreicher@ce9.uscourts.gov"
SOURCE="/var/log/httpd"

NOW=$(date +"%Y-%m-%d-%T")
TODAY=$(date +"%Y-%m-%d")

for file in ${SOURCE}/*; do
#    file=${file%*/}
    echo ${file##*/}
## find ./my_dir -mtime +10 -type f -delete
done

exit

