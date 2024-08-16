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

# dump device info
wget http://admin:${pass}@127.0.0.1/vb.htm?DeviceInfo &>/dev/null

# extract firmware version
version=`cat vb.htm?DeviceInfo | cut -d'-' -f3 | cut -d ' ' -f1 | tr -d 'B' `

# clean up detritus
rm vb*

if [[ $version -lt 9108 ]]; then

 # error statement + triggering
 # the ssh error suffix
 echo " WARNING: your firmware version $version is not supported,"
 echo " please update your camera firmware to version B9108 or later."
 exit 1

else
 
 # clean exit
 exit 0
fi
