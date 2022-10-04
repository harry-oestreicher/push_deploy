# Secure Synchronization for LAMP CMS Sytems

### push>deploy

## Overview

This repository contains files used to setup a staging environment for scheduled and on-demand content publishing. The application environment is a multi-homed LAMP stack, hosted on RedHat Enterprise Linux.  This package will use secure tunnel and jump host to push content to the public websites which reside in a DMZ.

Each client web app has an account and manages content changes on the staging environment. Loacl CRON jobs create an incremental backup of the file systems and a database snapshot. These two files are sent via encryted tunnel to the public server in the DMZ where they're extracted and deployed in place.  Basic on-way content push.

### Push >>> Deploy

The files in this repo are mostly configuration files (for each site) except for the `/bin/push.sh` `/bin/tunnel.sh` and `/bin/deploy.sh` which are either called via cron, CLI or PHP call.

