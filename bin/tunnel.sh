#!/bin/bash
#
# Title:    TUNNEL CONTROLLER
# Author:   Harry Oestreicher
# Email:    harry.oestreicher@gmail.com
# Version:  1.0 beta
# Calling:  <this script> {open|close|status|pid}

JUMP_USER="pusher"  # <== LOCAL ACCT ALSO NEEDS A JUMPHOST ACCT...
JUMP_PASS="******"
JUMP_HOST="jumphost.domain.com"
JUMP_PORT="5000"
JUMP_TARGET="156.128.26.0.164.10.22"
JUMP_TARGET_PORT="22"
SSH_IDENTITY_FILE=/home/pusher/.ssh/id_rsa.jmphst
GET_TUNNEL_PID=$(lsof -t -i :${JUMP_PORT})
GET_TUNNEL_STATUS=$(netstat -ntlp | grep ":${JUMP_PORT}")
LOGFILE=/home/pusher/bin/logs/tunnel.log

if [ ! -f $LOGFILE ]; then
  touch $LOGFILE
  chown pusher:wheel $LOGFILE
  echo [$(date +"%Y-%m-%d %T")] - NEW LOG FILE CREATED >> $LOGFILE
fi

case "$1" in
  open)
    if [ "$GET_TUNNEL_PID" > "1" ] ; then
      echo [$(date +"%Y-%m-%d %T")] - open: Tunnel is already established for $JUMP_PORT:$JUMP_TARGET:$JUMP_TARGET_PORT >> $LOGFILE
      echo "exists"
    else
      ssh -f $JUMP_USER@$JUMP_HOST -i $SSH_IDENTITY_FILE -L $JUMP_PORT:$JUMP_TARGET:$JUMP_TARGET_PORT -N
      if [ "$?" != "0" ]; then
        echo [$(date +"%Y-%m-%d %T")] - open: Tunnel creation failed. >> $LOGFILE
        echo "failed"
        exit 1
      else 
        echo [$(date +"%Y-%m-%d %T")] - open: Tunnel established for $JUMP_PORT:$JUMP_TARGET:$JUMP_TARGET_PORT >> $LOGFILE
        echo "open"
      fi
    fi
    ;;
  close)
    if [ "$GET_TUNNEL_PID" > "1" ] ; then
      kill $GET_TUNNEL_PID
      echo [$(date +"%Y-%m-%d %T")] - close: Tunnel disconnected >> $LOGFILE
      echo "closed"
    else
      echo [$(date +"%Y-%m-%d %T")] - close: No tunnel established. >> $LOGFILE
      echo "closed"
    fi
    ;;
  status)
    if [ "$GET_TUNNEL_PID" > "1" ] ; then
      echo [$(date +"%Y-%m-%d %T")] - status: Open  >> $LOGFILE
      echo "open"
    else
      echo [$(date +"%Y-%m-%d %T")] - status: No tunnel established. >> $LOGFILE
      echo "closed"
    fi
    ;;
  pid)
    if [ "$GET_TUNNEL_PID" > "1" ] ; then
      echo [$(date +"%Y-%m-%d %T")] - pid: $GET_TUNNEL_PID >> $LOGFILE
      echo $GET_TUNNEL_PID
    else
      echo [$(date +"%Y-%m-%d %T")] - pid: No tunnel established. >> $LOGFILE
      echo "0"
    fi
    ;;
  *)
  echo >&2 "usage: $0 {open|close|status|pid}"
  exit 1
esac
rm -f 1
