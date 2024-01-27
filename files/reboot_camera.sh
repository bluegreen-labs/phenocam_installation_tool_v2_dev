#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted.
#
#--------------------------------------------------------------------

pass=$1

# sleep 15 seconds and trigger reboot
sleep 15

# move into temporary directory
cd /var/tmp

# reboot
wget http://admin:${pass}@127.0.0.1/vb.htm?ipcamrestartcmd &>/dev/null

