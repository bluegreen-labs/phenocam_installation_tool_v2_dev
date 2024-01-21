#!/bin/bash

#--------------------------------------------------------------------
# This script installs all necessary configuration
# files as required to upload images to the PhenoCam server
# (phenocam.nau.edu) on your NetCam Live2 camera REMOTELY with
# minimum interaction with the camera
#
# Koen Hufkens (January 2023) koen.hufkens@gmail.com
#--------------------------------------------------------------------

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Running the installation script on the NetCam Live2 camera!"
echo "#"

# grab command line variables
camera_ip=$1
camera=$2
time_offset=$3
TZ=$4
cron_start=$5
cron_end=$6
cron_int=$7
server=$8

tar -cf install_files.tar files/*.sh

echo "#"
echo "# Uploading installation files, please approve this transaction by"
echo "# by providing a valid password!"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""

# crontab settings in
# /mnt/cfg1/schedule/admin

# Move installation files to the remote system
# and execute for install

command=`echo "
 cd /var/tmp &&
 cat >> /var/tmp/install_files.tar &&
 tar xf install_files.tar &&
 rm install_files.tar &&

 echo TRUE > /mnt/cfg1/update.txt &&
 
 echo ${camera} > /mnt/cfg1/settings.txt &&
 echo ${time_offset} >> /mnt/cfg1/settings.txt &&
 echo ${TZ} >> /mnt/cfg1/settings.txt &&
 echo ${cron_start} >> /mnt/cfg1/settings.txt &&
 echo ${cron_end} >> /mnt/cfg1/settings.txt &&
 echo ${cron_int} >> /mnt/cfg1/settings.txt &&
 echo ${server} > /mnt/cfg1/server.txt &&
 
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi &&
 
 cp /var/tmp/files/*.sh /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
  
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 
 echo '' &&
 echo '#--------------------------------------------------------------------' &&
 echo '# Successfully uploaded install instructions' &&
 echo '# Please reboot the camera by cycling the power' &&
 echo '#--------------------------------------------------------------------' &&
 echo ''
 "`

# install command
cat install_files.tar | ssh admin@${camera_ip} ${command}

exit 0
