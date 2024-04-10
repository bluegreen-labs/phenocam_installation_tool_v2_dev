#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted.
#
#--------------------------------------------------------------------

# grab password
pass=`awk 'NR==1' /mnt/cfg1/.password`

# sleep 15 seconds
sleep 15

# move into temporary directory
cd /var/tmp

# reboot
wget http://admin:${pass}@127.0.0.1/vb.htm?ipcamrestartcmd &>/dev/null

