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

# move into temporary directory
cd /var/tmp

# sleep 60 seconds for last
# command to finish (if any should be running)
sleep 60

# then reboot
wget http://admin:${pass}@127.0.0.1/vb.htm?ipcamrestartcmd &>/dev/null

# should this fail always fall back to a hard reboot
sleep 10
reboot

