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
  echo " Failed task... continuing"
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
  rm -rf /mnt/cfg1/phenocam_key.pub
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

# if the retrieve argument is active retrieve the
# public private keys
if [ "${retrieve}" ]; then

 echo " Checking and retrieving existing private key."
 echo " [Run this command when restoring camera settings]"
 echo ""
 
 # create command
 command="
  if [ -f '/mnt/cfg1/phenocam_key' ]; then cat /mnt/cfg1/phenocam_key; else exit 1; fi
 "

 # execute command
 ssh admin@${ip} ${command} > phenocam_key || error_continued 2>/dev/null

 # sanity checks
 # count lines in private key
 if [ -f 'phenocam_key' ]; then
  line_count=`cat phenocam_key | wc -l`
  if [ ! "${line_count}" -gt 0 ]; then
   echo ""
   echo " no valid private key was found on the camera"
   echo ""
   rm -rf phenocam_key
  else
   echo ""
   echo " A valid key was found and stored in phenocam_key"
   echo "--------------------------------------------------------------------"
   
   # plot the key to file
   cat phenocam_key
   
  fi
 else
  echo ""
  echo " no valid private key was found on the camera"
  echo ""
 fi
 
 # create command
 command="
  if [ -f '/mnt/cfg1/phenocam_key.pub' ]; then cat /mnt/cfg1/phenocam_key.pub; else exit 1; fi
 "

 # execute command
 ssh admin@${ip} ${command} > phenocam_key.pub || error_continued 2>/dev/null

 # sanity checks
 # count lines in private key
 if [ -f 'phenocam_key.pub' ]; then
  line_count=`cat phenocam_key.pub | wc -l`
  if [ ! "${line_count}" -gt 0 ]; then
   echo ""
   echo " no valid public key was found on the camera"
   echo ""
   rm -rf phenocam_key.pub
  else
   echo ""
   echo " A valid key was found and stored in phenocam_key"
   echo "--------------------------------------------------------------------"
   
   # plot the key to file
   cat phenocam_key.pub
   
  fi
 else
  echo ""
  echo " no valid public key was found on the camera"
  echo ""
 fi

 echo "===================================================================="
 exit 0
fi

# generate public-private key pair in the current directory
# warn if the file already exists
if [ "${key}" ]; then
 if [ ! -f "phenocam_key" ]; then
  ssh-keygen -q -t rsa -N '' -f phenocam_key <<<y >/dev/null 2>&1
 else
  echo ""
  echo "An existing private key was previously set or retrieved from the camera."
  echo "If you want to overwrite the exiting key remove the 'phenocam_key' file"
  echo "from the current working directory."
  echo ""
 fi
fi

# Default to GMT time zone
tz="GMT"

if [ "${key}" ]; then
 # print the content of the path to the
 # key and assign to a variable
 echo " Private key provided, using secure SFTP!"
 echo ""
 has_key="TRUE"
 private_key=`awk 'NF {sub(/\r/, ""); printf "%s\\\\n",$0;}' ./phenocam_key`
 public_key=`cat ./phenocam_key.pub`
else
 echo " No private key provided, defaulting to insecure FTP!"
 echo ""
 has_key="FALSE"
fi

# message on confirming the password
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
 echo '125' >> /mnt/cfg1/settings.txt &&
 echo '205' >> /mnt/cfg1/settings.txt &&
 echo ${pass} > /mnt/cfg1/.password &&
 if [ ${has_key} = 'TRUE' ]; then echo '${private_key}' | sed 's/\\\n/\n/g' > /mnt/cfg1/phenocam_key; fi &&
 if [ ${has_key} = 'TRUE' ]; then echo '${public_key}' > /mnt/cfg1/phenocam_key.pub; fi &&
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
 echo 'Using the following settings:' &&
 echo 'Sitename: ${name}' &&
 echo 'GMT timezone offset: ${offset}' &&
 echo 'Upload start: ${start}' &&
 echo 'Upload end: ${end}' &&
 echo 'Upload interval: ${int}' &&
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
