#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted.
#
#--------------------------------------------------------------------

capture () {

 image=$1
 metafile=$2
 delay=$3
 ir=$4

 # Set the image to non IR i.e. VIS
 /usr/sbin/set_ir.sh $ir

 # adjust exposure
 sleep $delay

 # grab the image from the
 wget http://127.0.0.1/image.jpg -O ${image}

 # grab date and time for `.meta` files
 METADATETIME=`date -Iseconds`

 # grab the exposure time and append to meta-data
 exposure=`/usr/sbin/get_exp` | cut -d ' ' -f4

 cat metadata.txt >> /var/tmp/${metafile}
 echo "exposure=$exposure" >> /var/tmp/${metafile}
 echo "ir_enable=$ir" >> /var/tmp/${metafile}
 echo "datetime_original=\"$METADATETIME\"" >> /var/tmp/${metafile}

}


# -------------- SETTINGS -------------------------------------------

# read in configuration settings
# grab sitename
SITENAME=`awk 'NR==1' /mnt/cfg1/settings.txt`

# how many servers do we upload to
nrservers=`awk 'END {print NR}' /mnt/cfg1/server.txt`
nrservers=`awk -v var=${nrservers} 'BEGIN{ n=1; while (n <= var ) { print n; n++; } }' | tr '\n' ' '`

# Move into temporary directory
# which resides in RAM, not to
# wear out other permanent memory
cd /var/tmp

# sets the delay between the
# RGB and IR image acquisitions
DELAY=30

# grab date - keep fixed for RGB and IR uploads
DATE=`date +"%a %b %d %Y %H:%M:%S"`

# grap date and time string to be inserted into the
# ftp scripts - this coordinates the time stamps
# between the RGB and IR images (otherwise there is a
# slight offset due to the time needed to adjust exposure
DATETIMESTRING=`date +"%Y_%m_%d_%H%M%S"`

# grab metadata using the metadata function
# grab the MAC address
mac_addr=`ifconfig eth0 | grep HWaddr | awk '{print $5}' | sed 's/://g'`

# grab internal ip address
ip_addr=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`

# grab external ip address if there is an external connection
# first test the connection to the google name server
connection=`ping -q -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# grab time zone
tz=`cat /var/TZ`

# grab the colour balance settings!!!

# create base meta-data file from configuration settings
# and the fixed parameters
echo "model=NetCam Live2" > /var/tmp/metadata.txt
 /mnt/cfg1/scripts/chls >> /var/tmp/metadata.txt
echo "ip_addr=$ip_addr" >> /var/tmp/metadata.txt
echo "mac_addr=$mac_addr" >> /var/tmp/metadata.txt
echo "time_zone=$tz" >> /var/tmp/metadata.txt

# -------------- UPLOAD VIS -----------------------------------------

# create filenames
metafile=`echo ${SITENAME}_${DATETIMESTRING}.meta`
image=`echo ${SITENAME}_${DATETIMESTRING}.jpg`

capture $image $metafile $DELAY 0

# run the upload script for the ip data
# and for all servers
for i in $nrservers;
do
 SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt`
 
 echo "uploading to: ${SERVER}"

 # upload image
 echo "uploading VIS image ${image}"
 ftpput ${SERVER} --username anonymous --password anonymous  data/${SITENAME}/${image} ${image}
	
 echo "uploading VIS meta-data ${metafile}"
 ftpput ${SERVER} --username anonymous --password anonymous  data/${SITENAME}/${metafile} ${metafile}

done

# clean up files
rm *.jpg
rm *.meta

# -------------- UPLOAD NIR -----------------------------------------

# create filenames
metafile=`echo ${SITENAME}_IR_${DATETIMESTRING}.meta`
image=`echo ${SITENAME}_IR_${DATETIMESTRING}.jpg`

capture $image $metafile $DELAY 1

# run the upload script for the ip data
# and for all servers
for i in $nrservers;
do
 SERVER=`awk -v p=${i} 'NR==p' /mnt/cfg1/server.txt`

 # upload image
 echo "uploading NIR image ${image}"
 ftpput ${SERVER} -u "anonymous" -p "anonymous"  data/${SITENAME}/${image} ${image}
	
 echo "uploading NIR meta-data ${metafile}"
 ftpput ${SERVER} -u "anonymous" -p "anonymous"  data/${SITENAME}/${metafile} ${metafile}

done

# clean up files
rm *.jpg
rm *.meta

# Reset to VIS
/usr/sbin/set_ir.sh 0

#------- FEEDBACK ON ACTIVITY -----------
cat "last upload at:" >> /var/tmp/log.txt
cat date >> /var/tmp/log.txt

