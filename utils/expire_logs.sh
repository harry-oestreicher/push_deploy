#!/bin/sh
#
##############################################################################
### EXPIRE HTTPD LOGS
##
##  Author:   Harry Oestreicher : 9th Circuit Executives Office
##  Email:    harry.oestreicher@gmail.com
##  Version:  1
##############################################################################

EMAIL="admin@email.com"
SOURCE="/var/log/httpd"

NOW=$(date +"%Y-%m-%d-%T")
TODAY=$(date +"%Y-%m-%d")

for file in ${SOURCE}/*; do
#    file=${file%*/}
    echo ${file##*/}
## find ./my_dir -mtime +10 -type f -delete
done

exit
