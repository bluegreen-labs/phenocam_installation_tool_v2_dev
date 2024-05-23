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

# error handling subroutines
error_exit(){
  echo ""
  echo " NOTE: If no confirmation of a successful upload is provided,"
  echo " check all script parameters!"
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling subroutines
error_continued(){
  echo ""
  echo " No private key 'phenocam_key' found... (please run the installation routine)"
  echo ""
}

# define usage
usage() { 
 echo "
 Usage: $0
  [-i <camera ip address>]
  [-p <camera password>]
  [-n <camera name>]
  [-o <time offset from UTC/GMT>]
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  [-k <set private key>]
  [-r <retrieve private key>]
  [-x <purge all previous settings and keys>]
  " 1>&2; exit 0;
 }

# grab arguments
while getopts ":hi:p:n:o:t:s:e:m:k:r:x:d:" option;
do
    case "${option}"
        in
        i) ip=${OPTARG} ;;
        p) pass=${OPTARG} ;;
        n) name=${OPTARG} ;;
        o) offset=${OPTARG} ;;
        s) start=${OPTARG} ;;
        e) end=${OPTARG} ;;
        m) int=${OPTARG} ;;
        k) key=${OPTARG} ;;
        r) retrieve=${OPTARG} ;;
        x) purge=${OPTARG} ;;
        h | *) usage; exit 0 ;;
    esac
done

echo ""
echo "===================================================================="
echo ""
echo " Running the installation script on the NetCam Live2 camera!"
echo ""
echo " (c) BlueGreen Labs (BV) 2024 - https://bluegreenlabs.org"
echo " -----------------------------------------------------------"
echo ""

# if the retrieve argument is active retrieve the
# public private keys
if [ "${purge}" ]; then

 echo " Purging all previous settings and login credentials"
 echo ""
 
 # create command
 command="
  rm -rf /mnt/cfg1/settings.txt
  rm -rf /mnt/cfg1/.password
  rm -rf /mnt/cfg1/phenocam_key
  rm -rf /mnt/cfg1/update.txt
  rm -rf /mnt/cfg1/scripts/
 "
 
 # execute command
 ssh admin@${ip} ${command} || error_handler 2>/dev/null
 
 echo ""
 echo " Done, cleaned the camera!"
  echo ""
 echo "===================================================================="
 exit 0
fi

# if the retrieve the public key
if [ "${retrieve}" ]; then
 
 # create command
 command="
  if [ -f '/mnt/cfg1/phenocam_key' ]; then dropbearkey -t rsa -f /mnt/cfg1/phenocam_key -y; else exit 1; fi
 "

 echo " Retrieving the public key login credentials"
 echo ""
 
 # execute command
 ssh admin@${ip} ${command} > tmp.pub || error_continued 2>/dev/null
 
 # strip out the public key
 # no header or footer
 grep "ssh-rsa" tmp.pub > phenocam_key.pub
 rm -rf tmp.pub
 
 echo "" 
 echo " The public key was written to the 'phenocam_key.pub' file"
 echo " in the current working directory!"
 echo ""
 echo " Forward this file to phenocam@nau.edu to finalize your"
 echo " sFTP installation."
 echo ""
 echo "===================================================================="
 exit 0
fi

# Default to GMT time zone
tz="GMT"

if [ "${key}" ]; then
 # print the content of the path to the
 # key and assign to a variable
 echo " Using secure SFTP!"
 echo ""
 has_key="TRUE"
else
 echo " No key will be generated, defaulting to insecure FTP!"
 echo ""
 has_key="FALSE"
fi

# message on confirming the password
echo " Uploading installation files, please approve this"
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
 echo '125' >> /mnt/cfg1/settings.txt &&
 echo '205' >> /mnt/cfg1/settings.txt &&
 echo ${pass} > /mnt/cfg1/.password &&
 if [[ ${has_key} = 'TRUE' && ! -f /mnt/cfg1/phenocam_key ]]; then dropbearkey -t rsa -f /mnt/cfg1/phenocam_key >/dev/null; fi &&
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_upload.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions!' &&
 echo '' &&
 echo ' Using the following settings:' &&
 echo ' Sitename: ${name}' &&
 echo ' GMT timezone offset: ${offset}' &&
 echo ' Upload start: ${start}' &&
 echo ' Upload end: ${end}' &&
 echo ' Upload interval: ${int}' &&
 echo '' &&
 if [ -f /mnt/cfg1/phenocam_key ]; then echo ' A private key exists or was generated, please run:'; fi &&
 if [ -f /mnt/cfg1/phenocam_key ]; then echo ' ./PIT.sh ${ip} -r TRUE'; fi &&
 echo '' &&
 echo ' --> Reboot the camera by cycling the power or wait 20 seconds! <-- ' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 sh /mnt/cfg1/scripts/reboot_camera.sh
"

# install command
BINLINE=$(awk '/^__BINARY__/ { print NR + 1; exit 0; }' $0)
tail -n +${BINLINE} $0 | ssh admin@${ip} ${command} || error_exit 2>/dev/null

# remove last lines from history
# containing the password
history -d -1--2

# exit
exit 0

__BINARY__
