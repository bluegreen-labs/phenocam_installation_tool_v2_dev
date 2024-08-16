#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted.
#
#--------------------------------------------------------------------

# hard code path which are lost in some instances
# when calling the script through ssh 
PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

# grab password
pass=`awk 'NR==1' /mnt/cfg1/.password`

# move into temporary directory
cd /var/tmp

# sleep 30 seconds for last
# command to finish (if any should be running)
sleep 30

# then reboot
wget http://admin:${pass}@127.0.0.1/vb.htm?ipcamrestartcmd &>/dev/null

# don't exit cleanly when the reboot command doesn't stick
# should trigger a warning message
sleep 60

echo " -----------------------------------------------------------"
echo ""
echo " REBOOT FAILED - INSTALL MIGHT NOT BE COMPLETE!"
echo ""
echo "===================================================================="

exit 1
