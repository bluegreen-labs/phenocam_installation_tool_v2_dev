#!/bin/bash

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# This script installs all necessary configuration
# files as required to upload images to the PhenoCam server
# (phenocam.nau.edu) on your NetCam Live2 camera REMOTELY with
# minimum interaction with the camera.
#
# Use is permitted within the context of the PhenoCam US network,
# in its standard configuration. For all exceptions contact
# BlueGreen Labs
#
#--------------------------------------------------------------------

tar -cf install files/*
base64 install > install.bin

# subroutines
error_handler(){
  echo ""
  echo " NOTE: If no confirmation of a successful upload is provided,"
  echo " check all script parameters!"
  echo ""
  echo "===================================================================="
  exit 1
}

# define usage
usage() { 
 echo "
 Usage: $0
  [-i <camera ip address>]
  [-p <camera password>]
  [-n <camera name>]
  [-o <time offset from UTC>] 
  [-t <time zone>] 
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  " 1>&2; exit 0;
 }

# grab arguments
while getopts ":hi:p:n:o:t:s:e:m:d:" option;
do
    case "${option}"
        in
        i) ip=${OPTARG} ;;
        p) pass=${OPTARG} ;;
        n) name=${OPTARG} ;;
        o) offset=${OPTARG} ;;
        t) tz=${OPTARG} ;;
        s) start=${OPTARG} ;;
        e) end=${OPTARG} ;;
        m) int=${OPTARG} ;;                
        h | *) usage; exit 0 ;;
    esac
done

echo ""
echo "===================================================================="
echo ""
echo " Running the installation script on the NetCam Live2 camera!"
echo ""
echo " (c) BlueGreen Labs 2024"
echo " -----------------------------------------------------------"
echo ""
echo " Uploading installation files, please approve this transaction by"
echo " by confirming the password!"
echo ""

command="
 echo TRUE > /mnt/cfg1/update.txt &&
 echo ${name} > /mnt/cfg1/settings.txt &&
 echo ${offset} >> /mnt/cfg1/settings.txt &&
 echo ${tz} >> /mnt/cfg1/settings.txt &&
 echo ${start} >> /mnt/cfg1/settings.txt &&
 echo ${end} >> /mnt/cfg1/settings.txt &&
 echo ${int} >> /mnt/cfg1/settings.txt &&
 echo '225' >> /mnt/cfg1/settings.txt &&
 echo '130' >> /mnt/cfg1/settings.txt &&
 echo '230' >> /mnt/cfg1/settings.txt &&
 echo ${pass} > /mnt/cfg1/.password &&
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions!' &&
 echo '' &&
 echo ' --> Reboot the camera by cycling the power or wait 10 seconds! <-- ' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 sh /mnt/cfg1/scripts/reboot_camera.sh ${pass}
"

# install command
cat install.bin | ssh admin@${ip} ${command} || error_handler 2>/dev/null

# remove last line from history
# containing the password
history -d -1

# exit
exit 0
