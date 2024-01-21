#!/bin/sh

#--------------------------------------------------------------------
# This script is cued up in the crontab file and called every
# x min to upload two images, a standard RGB image and an infra-
# red (IR) image (if available) to the PhenoCam server.
#
# (c) Koen Hufkens for BlueGreen Labs
#--------------------------------------------------------------------

# -------------- SETTINGS -------------------------------------------

# read in configuration settings
# grab sitename
SITENAME=`awk 'NR==1' /mnt/cfg1/settings.txt`

# how many servers do we upload to
nrservers=`awk 'END {print NR}' /mnt/cfg1/server.txt`
nrservers=`awk -v var=$nrservers 'BEGIN{ n=1; while (n <= var ) { print n; n++; } }' | tr '\n' ' '`

# Move into temporary directory
# which resides in RAM, not to
# wear out other permanent memory

cd /var/tmp

# sets the delay between the
# RGB and IR image acquisitions
DELAY=30

# -------------- UPLOAD IMAGES --------------------------------------

# grab date - keep fixed for RGB and IR uploads
DATE=`date +"%a %b %d %Y %H:%M:%S"`

# grap date and time string to be inserted into the
# ftp scripts - this coordinates the time stamps
# between the RGB and IR images (otherwise there is a
# slight offset due to the time needed to adjust exposure
DATETIMESTRING=`date +"%Y_%m_%d_%H%M%S"`

# grab date and time for `.meta` files
METADATETIME=`date -Iseconds`

# grab metadata using the metadata function
# grab the MAC address
mac_addr=`ifconfig eth0 | grep HWaddr | awk '{print $5}' | sed 's/://g'`

# grab internal ip address
ip_addr=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`

# grab external ip address if there is an external connection
# first test the connection to the google name server
connection=`ping -q -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# -------------- UPLOAD VIS -----------------------------------------

# create filenames
metafile=`echo ${SITENAME}_${DATETIMESTRING}.meta`
image=`echo ${SITENAME}_${DATETIMESTRING}.jpg`

# create base meta-data file from configuration settings
cat /mnt/cfg1/settings.txt > /var/tmp/${metafile}

# append meta-data
echo "ip_addr=$ip_addr" >> /var/tmp/${metafile}
echo "mac_addr=$mac_addr" >> /var/tmp/${metafile}
echo "datetime_original=\"$METADATETIME\"" >> /var/tmp/${metafile}

# Set the image to non IR i.e. VIS
/usr/sbin/set_ir.sh 0

# adjust exposure
sleep $DELAY

# grab the image from the
wget http://127.0.0.1/image.jpg -O ${image}

# grab the exposure time and append to meta-data
exposure=`/usr/sbin/get_exp`
echo $exposure >> /var/tmp/${metafile}

# run the upload script for the ip data
# and for all servers
for i in $nrservers;
do
	SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt`
	
	# upload image
	echo "uploading VIS image ${image}"
	ftpput ${SERVER} -u anonymous -p "anonymous"  data/${SITENAME}/${image} ${image}
	
	echo "uploading VIS meta-data ${metafile}"
	# upload meta-file
	ftpput ${SERVER} -u anonymous -p "anonymous"  data/${SITENAME}/${metafile} ${metafile}
done

# clean up files
rm *.jpg
rm *.meta

# -------------- UPLOAD NIR -----------------------------------------

# create filenames
metafile=`echo ${SITENAME}_IR_${DATETIMESTRING}.meta`
image=`echo ${SITENAME}_IR_${DATETIMESTRING}.jpg`

# create base meta-data file from configuration settings
cat /mnt/cfg1/settings.txt > /var/tmp/${metafile}

# append meta-data
echo "ip_addr=$ip_addr" >> /var/tmp/${metafile}
echo "mac_addr=$mac_addr" >> /var/tmp/${metafile}
echo "datetime_original=\"$METADATETIME\"" >> /var/tmp/${metafile}

# Set the image to NIR
/usr/sbin/set_ir.sh 1

# adjust exposure 
sleep $DELAY

# grab the image from the
wget http://127.0.0.1/image.jpg -O ${image}

# grab the exposure time and append to meta-data
exposure=`/usr/sbin/get_exp`
echo $exposure >> /var/tmp/${metafile}

# run the upload script for the ip data
# and for all servers
for i in $nrservers;
do
	SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt`

	# upload image
	echo "uploading NIR image ${image}"
	ftpput ${SERVER} -u anonymous -p "anonymous"  data/${SITENAME}/${image} ${image}
	
	echo "uploading NIR meta-data ${metafile}"
	# upload meta-file
	ftpput ${SERVER} -u anonymous -p "anonymous"  data/${SITENAME}/${metafile} ${metafile}
done

# clean up files
rm *.jpg
rm *.meta

# Reset to VIS
/usr/sbin/set_ir.sh 0

