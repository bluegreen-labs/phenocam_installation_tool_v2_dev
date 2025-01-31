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

# error handling
error_exit(){
  echo ""
  echo " FAILED TO UPLOAD DATA"
  echo ""
}

#---- feedback on startup ---

echo ""
echo "Starting image uploads ... "
echo ""

#---- subroutines ---

capture() {

 image=$1
 metafile=$2
 delay=$3
 ir=$4

 # Set the image to non IR i.e. VIS
 /usr/sbin/set_ir.sh $ir >/dev/null 2>/dev/null

 # adjust exposure
 sleep $delay

 # grab the image from the
 wget http://127.0.0.1/image.jpg -O ${image} >/dev/null 2>/dev/null

 # grab date and time for `.meta` files
 METADATETIME=`date -Iseconds`

 # grab the exposure time and append to meta-data
 exposure=`/usr/sbin/get_exp | cut -d ' ' -f4`

 # adjust meta-data file
 cat /var/tmp/metadata.txt > /var/tmp/${metafile}
 echo "exposure=${exposure}" >> /var/tmp/${metafile}
 echo "ir_enable=$ir" >> /var/tmp/${metafile}
 echo "datetime_original=\"$METADATETIME\"" >> /var/tmp/${metafile}

}

# error handling
login_success(){
 service="sFTP"
}

# -------------- SETTINGS -------------------------------------------

# read in configuration settings
# grab sitename
SITENAME=`awk 'NR==1' /mnt/cfg1/settings.txt`

# grab time offset / local time zone
# and convert +/- to ascii
time_offset=`awk 'NR==2' /mnt/cfg1/settings.txt`
SIGN=`echo ${time_offset} | cut -c'1'`

if [ "$SIGN" = "+" ]; then
 time_offset=`echo "${time_offset}" | sed 's/+/%2B/g'`
else
 time_offset=`echo "${time_offset}" | sed 's/-/%2D/g'`
fi

# set camera model name
model="NetCam Live2"

# how many servers do we upload to
nrservers=`awk 'END {print NR}' /mnt/cfg1/server.txt`
nrservers=`awk -v var=${nrservers} 'BEGIN{ n=1; while (n <= var ) { print n; n++; } }' | tr '\n' ' '`

# grab password
pass=`awk 'NR==1' /mnt/cfg1/.password`

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
mac_addr=`ifconfig eth0 | grep 'HWaddr' | awk '{print $5}' | sed 's/://g'`

# grab internal ip address
ip_addr=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`

# grab external ip address if there is an external connection
# first test the connection to the google name server
connection=`ping -q -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# grab time zone
tz=`cat /var/TZ`

# get SD card presence
SDCARD=`df | grep "mmc" | wc -l`

# backup to SD card when inserted
# runs on phenocam upload rather than install
# to allow hot-swapping of cards
if [ "$SDCARD" -eq 1 ]; then
 
 # create backup directory
 mkdir -p /mnt/mmc/phenocam_backup/
 
fi

# -------------- SET FIXED DATE TIME HEADER -------------------------

# overlay text
overlay_text=`echo "${SITENAME} - ${model} - ${DATE} - GMT${time_offset}" | sed 's/ /%20/g'`
	
# for now disable the overlay
wget http://admin:${pass}@127.0.0.1/vb.htm?overlaytext1=${overlay_text} >/dev/null 2>/dev/null

# clean up detritus
rm vb*

# -------------- SET FIXED META-DATA -------------------------------

# create base meta-data file from configuration settings
# and the fixed parameters
echo "model=NetCam Live2" > /var/tmp/metadata.txt

# colour balance settings
red=`awk 'NR==7' /mnt/cfg1/settings.txt`
green=`awk 'NR==8' /mnt/cfg1/settings.txt`
blue=`awk 'NR==9' /mnt/cfg1/settings.txt` 
brightness=`awk 'NR==10' /mnt/cfg1/settings.txt`
sharpness=`awk 'NR==11' /mnt/cfg1/settings.txt`
hue=`awk 'NR==12' /mnt/cfg1/settings.txt`
contrast=`awk 'NR==13' /mnt/cfg1/settings.txt`	 
saturation=`awk 'NR==14' /mnt/cfg1/settings.txt`
blc=`awk 'NR==15' /mnt/cfg1/settings.txt`
network=`awk 'NR==16' /mnt/cfg1/settings.txt`

echo "network=$network" >> /var/tmp/metadata.txt
echo "ip_addr=$ip_addr" >> /var/tmp/metadata.txt
echo "mac_addr=$mac_addr" >> /var/tmp/metadata.txt
echo "time_zone=$tz" >> /var/tmp/metadata.txt
echo "overlay_text=$overlay_text" >> /var/tmp/metadata.txt

echo "red=$red" >> /var/tmp/metadata.txt
echo "green=$green" >> /var/tmp/metadata.txt
echo "blue=$blue" >> /var/tmp/metadata.txt
echo "brightness=$brightness" >> /var/tmp/metadata.txt
echo "contrast=$contrast" >> /var/tmp/metadata.txt
echo "hue=$hue" >> /var/tmp/metadata.txt
echo "sharpness=$sharpness" >> /var/tmp/metadata.txt
echo "saturation=$saturation" >> /var/tmp/metadata.txt
echo "backlight=$blc" >> /var/tmp/metadata.txt

# -------------- UPLOAD DATA ----------------------------------------

# we use two states to indicate VIS (0) and NIR (1) states
# and use a for loop to cycle through these states and
# upload the data
states="0 1"

for state in $states;
do

 if [ "$state" -eq 0 ]; then

  # create VIS filenames
  metafile=`echo ${SITENAME}_${DATETIMESTRING}.meta`
  image=`echo ${SITENAME}_${DATETIMESTRING}.jpg`
  capture $image $metafile $DELAY 0

 else

  # create NIR filenames
  metafile=`echo ${SITENAME}_IR_${DATETIMESTRING}.meta`
  image=`echo ${SITENAME}_IR_${DATETIMESTRING}.jpg`
  capture $image $metafile $DELAY 1
 
 fi

 # run the upload script for the ip data
 # and for all servers
 for i in $nrservers;
 do
  SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt`
  echo "uploading to: ${SERVER}"
  echo ""
  
  # -------------- VALIDATE SERVICE --------------------------------
  # check if sFTP is reachable

  # set the default service
  service="FTP"

  if [ -f "/mnt/cfg1/phenocam_key" ]; then

   echo "An sFTP key was found, checking login credentials..."

   echo "exit" > batchfile
   sftp -b batchfile -i "/mnt/cfg1/phenocam_key" phenosftp@${SERVER} >/dev/null 2>/dev/null

   # if status output last command was
   # 0 set service to sFTP
   if [ $? -eq 0 ]; then
    echo "SUCCES... using secure sFTP"
    echo ""
    service="sFTP"
   else
    echo "FAILED... falling back to FTP!"
    echo ""
   fi
 
   # clean up
   rm batchfile
  fi
  # -------------- VALIDATE SERVICE END -----------------------------

  # if key file exists use SFTP
  if [ "${service}" != "FTP" ]; then
   echo "using sFTP"
  
   echo "PUT ${image} data/${SITENAME}/${image}" > batchfile
   echo "PUT ${metafile} data/${SITENAME}/${metafile}" >> batchfile
  
   # upload the data
   echo "Uploading (state: ${state})"
   echo " - image file: ${image}"
   echo " - meta-data file: ${metafile}"
   sftp -b batchfile -i "/mnt/cfg1/phenocam_key" phenosftp@${SERVER} >/dev/null 2>/dev/null || error_exit
   
   # remove batch file
   rm batchfile
   
  else
   echo "Using FTP [check your install and key credentials to use sFTP]"
  
   # upload image
   echo "Uploading (state: ${state})"
   echo " - image file: ${image}"
   ftpput ${SERVER} --username anonymous --password anonymous  data/${SITENAME}/${image} ${image} >/dev/null 2>/dev/null || error_exit
	
   echo " - meta-data file: ${metafile}"
   ftpput ${SERVER} --username anonymous --password anonymous  data/${SITENAME}/${metafile} ${metafile} >/dev/null 2>/dev/null || error_exit

  fi
 done

 # backup to SD card when inserted
 if [ "$SDCARD" -eq 1 ]; then 
  cp ${image} /mnt/mmc/phenocam_backup/${image}
  cp ${metafile} /mnt/mmc/phenocam_backup/${metafile}
 fi

 # clean up files
 rm *.jpg
 rm *.meta

done

# Reset to VIS as default
/usr/sbin/set_ir.sh 0

#-------------- RESET NORMAL HEADER --------------------------------

# overlay text
overlay_text=`echo "${SITENAME} - ${model} - %a %b %d %Y %H:%M:%S - GMT${time_offset}" | sed 's/ /%20/g'`
	
# for now disable the overlay
wget http://admin:${pass}@127.0.0.1/vb.htm?overlaytext1=${overlay_text} >/dev/null 2>/dev/null

# clean up detritus
rm vb*

#------- FEEDBACK ON ACTIVITY ---------------------------------------
if [ ! -f "/var/tmp/image_log.txt" ]; then
 touch /var/tmp/image_log.txt
 chmod a+rw /var/tmp/image_log.txt
fi

echo "last uploads at:" >> /var/tmp/image_log.txt
echo $DATE >> /var/tmp/image_log.txt
tail /var/tmp/image_log.txt

#------- FILE PERMISSIONS AND CLEANUP -------------------------------
rm -f /var/tmp/metadata.txt

