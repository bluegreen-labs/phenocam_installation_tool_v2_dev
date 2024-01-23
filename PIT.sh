#!/bin/bash

#--------------------------------------------------------------------
# This script installs all necessary configuration
# files as required to upload images to the PhenoCam server
# (phenocam.nau.edu) on your NetCam Live2 camera REMOTELY with
# minimum interaction with the camera
#
# (c) Koen Hufkens for BlueGreen Labs (BV)
#--------------------------------------------------------------------

tar -cf install files/*.sh
base64 install > install.bin

# subroutines
error_handler(){
  echo " Installation failed, check the IP address!"
  echo ""
  echo " (c) BlueGreen Labs 2024"
  echo "===================================================================="
  exit 1
}

# define usage
usage() { 
 echo "
 Usage: $0
  [-i <camera ip address>]
  [-n <camera name>]
  [-o <time offset>] 
  [-t <time zone>] 
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  [-d <image destination server, default: phenocam.nau.edu>]
  " 1>&2; exit 0;
 }

# grab arguments
while getopts ":hi:n:o:t:s:e:m:d:" option;
do
    case "${option}"
        in
        i) ip=${OPTARG} ;;
        n) name=${OPTARG} ;;
        o) offset=${OPTARG} ;;
        t) tz=${OPTARG} ;;
        s) start=${OPTARG} ;;
        e) end=${OPTARG} ;;
        m) int=${OPTARG} ;;
        d) server=${OPTARG} ;;                
        h | *) usage; exit 0 ;;
    esac
done

# check if the server string is there
# with PhenoCam US as default
if [[ ! -n '${server}' ]]; then
 echo "No server provided, using the default NAU server."
 server="phenocam.nau.edu"
fi

echo ""
echo "===================================================================="
echo ""
echo " Running the installation script on the NetCam Live2 camera!"
echo " -----------------------------------------------------------"
echo ""
echo " Uploading installation files, please approve this transaction by"
echo " by providing a valid password!"
echo ""

command="
 if [ -f '/mnt/cfg1/server.txt' ]; then rm /mnt/cfg1/server.txt; fi &&
 echo TRUE > /mnt/cfg1/update.txt &&
 echo ${name} > /mnt/cfg1/settings.txt &&
 echo ${offset} >> /mnt/cfg1/settings.txt &&
 echo ${tz} >> /mnt/cfg1/settings.txt &&
 echo ${start} >> /mnt/cfg1/settings.txt &&
 echo ${end} >> /mnt/cfg1/settings.txt &&
 echo ${int} >> /mnt/cfg1/settings.txt &&
 echo ${server} > /mnt/cfg1/server.txt &&
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/*.sh /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions!' &&
 echo '' &&
 echo ' --> Please reboot the camera by cycling the power! <-- ' &&
 echo '' &&
 echo ' (c) BlueGreen Labs 2024' &&
 echo '====================================================================' &&
 echo ''
"

# install command
cat install.bin | ssh admin@${ip} ${command} || error_handler

# exit
exit 0
