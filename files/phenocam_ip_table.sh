#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted.
#
#--------------------------------------------------------------------

# some feedback on the action
echo "uploading IP table"

# how many servers do we upload to
nrservers=`awk 'END {print NR}' /mnt/cfg1/server.txt`
nrservers=`awk -v var=${nrservers} 'BEGIN{ n=1; while (n <= var ) { print n; n++; } }' | tr '\n' ' '`

# grab the name, date and IP of the camera
DATETIME=`date`

# grab internal ip address
IP=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`
SITENAME=`awk 'NR==1' /mnt/cfg1/settings.txt`

# update the IP and time variables
cat /mnt/cfg1/scripts/site_ip.html | sed "s|DATETIME|$DATETIME|g" | sed "s|SITEIP|$IP|g" > /var/tmp/${SITENAME}\_ip.html

# run the upload script for the ip data
# and for all servers
for i in $nrservers ;
do
 SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt` 
	
 # upload image
 echo "uploading NIR image ${image}"
 ftpput ${SERVER} -u "anonymous" -p "anonymous" data/${SITENAME}/${SITENAME}\_ip.html /var/tmp/${SITENAME}\_ip.html

done

# clean up
rm /var/tmp/${SITENAME}\_ip.html
