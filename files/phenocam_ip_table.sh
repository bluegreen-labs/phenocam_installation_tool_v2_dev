#!/bin/bash
# crontab script to update the ip table
# for each site, for validation of uptime

# some feedback on the action
echo "uploading IP table"

# how many servers do we upload to
nrservers=`awk 'END {print NR}' server.txt`

# grab the name, date and IP of the camera
DATETIME=`date`
IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
SITENAME=`awk 'NR==1' /mnt/cfg1/settings.txt`

# update the IP and time variables
cat /mnt/cfg1/scripts/site_ip.html | sed "s|DATETIME|$DATETIME|g" | sed "s|SITEIP|$IP|g" > /var/tmp/${SITENAME}\_ip.html

# run the upload script for the ip data
# and for all servers
for i in `seq 1 $nrservers` ;
do
	SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt` 
	
	# upload to server
	# ftp ...
done

# clean up
rm /var/tmp/${SITENAME}\_ip.html
