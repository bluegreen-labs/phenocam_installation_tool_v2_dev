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

#---- global login banner ----

echo ""
echo "===================================================================="
echo ""
echo " Phenocam Installation Tool (PIT) V2 for NetCam Live2 cameras"
echo ""
echo " (c) BlueGreen Labs (BV) 2024 - https://bluegreenlabs.org"
echo ""
echo " -----------------------------------------------------------"
echo ""

#---- subroutines ----

# error handling installation subroutines
error_exit(){
  echo ""
  echo " NOTE: If no confirmation of a successful upload is provided,"
  echo " or warnings are shown, check all script parameters."
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling key retrieval routine
error_key(){
  echo ""
  echo " WARNING: No login key (pair) 'phenocam_key' found... "
  echo " (please run the installation routine)"
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling purging routine
error_purge(){
  echo ""
  echo " WARNING: Purging of system settings failed, please try again!"
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling test routine
error_upload(){
  echo ""
  echo " WARNING: Image upload failed, check your network connection"
  echo " and settings!"
  echo ""
  echo "===================================================================="
  exit 0
}

# define usage
usage() { 
 echo "
 
 This scripts covers the installation of your
 Stardot NetCam Live2 PhenoCam
 please use the following arguments.
 
 Arguments which require an additional parameter
 have descriptions enclosed in <> brackets. Other
 arguments are binary choices.
 
 Usage: $0
  [-i <camera ip address>]
  [-p <camera password>]
  [-n <camera name>]
  [-o <time offset from UTC/GMT>]
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  [-f <fix a non-random interval> logical TRUE or FALSE]
  [-d <destination> which network to use, either 'phenocam' or 'icos']
  [-u uploads images if specified, requires -i to be specified]
  [-v validate login credentials for sFTP transfers]
  [-r retrieves login key if specified, requires -i to be specified]
  [-x purges all previous settings and keys if specified, requires -i to be specified]
  [-h calls this menu if specified]
  " 1>&2
  
  exit 0
 }

validate() {
 echo " Trying to validate sFTP login"
 echo ""
 
  # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_upload
 fi
 
 # create command
 command="
  sh /mnt/cfg1/scripts/phenocam_validate.sh
 "
 
 # execute command
 ssh admin@${ip} ${command} 2>/dev/null

 echo ""
 echo "[if no warnings are given your logins were successful]"
 echo ""
 echo "===================================================================="
 exit 0
 }

upload() {
 echo " Trying to upload image to the server"
 echo ""
 
  # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_upload
 fi
 
 # create command
 command="
  sh /mnt/cfg1/scripts/phenocam_upload.sh
 "
 
 # execute command
 ssh admin@${ip} ${command} || error_upload 2> /dev/null
 
 echo ""
 echo "===================================================================="
 exit 0
 }

# if the retrieve the public key
retrieve() {
 
 # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_key
 fi
 
 # create command
 command="
  if [ -f '/mnt/cfg1/phenocam_key' ]; then dropbearkey -t ecdsa -s 521 -f /mnt/cfg1/phenocam_key -y; else exit 1; fi
 "

 echo " Retrieving the public key login credentials"
 echo ""
 
 # execute command
 ssh admin@${ip} ${command} > tmp.pub || error_key 2>/dev/null
 
 # strip out the public key
 # no header or footer
 grep "ecdsa-sha2" tmp.pub > phenocam_key.pub
 rm -rf tmp.pub
 
 echo "" 
 echo " The public key was written to the 'phenocam_key.pub' file"
 echo " in your current working directory!"
 echo ""
 echo " Forward this file to phenocam@nau.edu to finalize your"
 echo " sFTP installation."
 echo ""
 echo "===================================================================="
 exit 0
}

# if the retrieve argument is active retrieve the
# public private keys, check if there are more than
# two arguments given to avoid accidental purging
purge() {

 echo " Purging all previous settings and login credentials"
 echo ""
 
  # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_purge
 fi
 
 # ASK FOR CONFIRMATION!!!
 read -p "Do you wish to perform this action?" yesno
 case $yesno in
        [Yy]* ) 
            echo "Purging the system settings..."
        ;;
        [Nn]* ) 
            echo "You answered no, exiting"
            exit_purge
        ;;
        * ) 
            exit_purge
        ;;
 esac 
 
 # create command
 command="
  rm -rf /mnt/cfg1/settings.txt
  rm -rf /mnt/cfg1/.password
  rm -rf /mnt/cfg1/phenocam_key
  rm -rf /mnt/cfg1/update.txt
  rm -rf /mnt/cfg1/scripts/
 "
 
 # execute command
 ssh admin@${ip} ${command} || error_purge 2>/dev/null
 
 echo ""
 echo " Done, cleaned the camera settings!"
 echo ""
 echo "===================================================================="
 exit 0
}

#---- parse arguments (and/or execute subroutine calls) ----

# grab arguments
while getopts "hi:p:n:o:s:e:m:f:d:uvrx" option;
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
        f) fix=${OPTARG} ;;
        d) dest=${OPTARG} ;;
        u) upload ;;
        v) validate ;;
        r) retrieve ;;
        x) purge ;;
        h | *) usage; exit 0 ;;
    esac
done

#---- installation routine ----

# validating parameters
if [[ -z ${ip} || ${ip} == -* ]]; then
 echo " WARNING: No IP address provided"
 error_exit
fi

if [[ -z ${pass} || ${pass} == -* ]]; then
 echo " WARNING: No password provided"
 error_exit
fi

if [[ -z ${name} || ${name} == -* ]]; then
 echo " WARNING: No camera name provided"
 error_exit
fi

if [[ -z ${offset} || ${offset} == -* ]]; then
 echo " WARNING: No GMT time offset provided"
 error_exit
fi

if [[ -z ${dest} || ${dest} == -* ]]; then
 echo " WARNING: provided destination argument is empty"
 error_exit
fi

if [[ "${dest}" != "phenocam" && "${dest}" != "icos" ]]; then
 echo " WARNING: network option is not valid (should be 'phenocam' or 'icos')"
 error_exit
fi

if [[ -z ${start} || ${start} == -* ]]; then
 echo " NOTE: No start time (24h format) provided, using the default (9h)"
 start='9'
fi

if [[ -z ${end} || ${end} == -* ]]; then
 echo " NOTE: No end time (24h format) provided, using the default (22h)"
 end='22'
fi

if [[ -z ${int} || ${int} == -* ]]; then
 echo " NOTE: No interval (in minutes) provided, using the default (30 min)"
 int='30'
fi

if [[ -z ${fix} || ${fix} == -* ]]; then
 echo " NOTE: fixed interval randomization not set, using the default (FALSE)"
 fix='FALSE'
fi

# Rename server variables to URLs
if [[ ${dest} == "phenocam" ]]; then
 url="phenocam.nau.edu"
else
 url="icos01.uantwerpen.be"
fi

# Default to GMT time zone
tz="GMT"

# colour settings
red="220"
green="125"
blue="220"
brightness="128"
contrast="128"
sharpness="128"
hue="128"
saturation="100"
backlight="0"

command="
 echo TRUE > /mnt/cfg1/update.txt &&
 echo ${name} > /mnt/cfg1/settings.txt &&
 echo ${offset} >> /mnt/cfg1/settings.txt &&
 echo ${tz} >> /mnt/cfg1/settings.txt &&
 echo ${start} >> /mnt/cfg1/settings.txt &&
 echo ${end} >> /mnt/cfg1/settings.txt &&
 echo ${int} >> /mnt/cfg1/settings.txt &&
 echo ${red} >> /mnt/cfg1/settings.txt &&
 echo ${green} >> /mnt/cfg1/settings.txt &&
 echo ${blue} >> /mnt/cfg1/settings.txt &&
 echo ${brightness} >> /mnt/cfg1/settings.txt &&
 echo ${sharpness} >> /mnt/cfg1/settings.txt &&
 echo ${hue} >> /mnt/cfg1/settings.txt &&
 echo ${contrast} >> /mnt/cfg1/settings.txt &&
 echo ${saturation} >> /mnt/cfg1/settings.txt &&
 echo ${backlight} >> /mnt/cfg1/settings.txt &&
 echo ${dest} >> /mnt/cfg1/settings.txt &&
 echo ${pass} > /mnt/cfg1/.password &&
 echo ${url} > /mnt/cfg1/server.txt &&
 if [ ! -f /mnt/cfg1/phenocam_key ]; then dropbearkey -t ecdsa -s 521 -f /mnt/cfg1/phenocam_key >/dev/null; fi &&
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 sh /mnt/cfg1/scripts/check_firmware.sh || return 1 &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh ${fix}' >> /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_upload.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions.' &&
 echo ' The camera configuration will take effect on reboot.' &&
 echo '' &&
 echo ' The following options have been set:' &&
 echo ' ------------------------------------' &&
 echo '' &&
 echo ' Sitename: ${name} | Timezone: GMT${offset}' &&
 echo ' Upload start - end: ${start} - ${end} (h)' &&
 echo ' Upload interval: every ${int} (min)' &&
 echo ' Fixed (non random) interval: ${fix}' &&
 echo '' &&
 echo ' And the following colour settings:' &&
 echo ' ----------------------------------' &&
 echo '' &&
 echo ' Gain values (R G B): ${red} ${green} ${blue}' &&
 echo ' Brightness: ${brightness} | Sharpness: ${sharpness}' &&
 echo ' Hue: ${hue} | Contrast: ${contrast}' &&
 echo ' Saturation: ${saturation} | Backlight: ${backlight}' &&
 echo '' &&
 echo ' ----------------------------------' &&
 echo '' &&
 echo ' NOTE:' &&
 echo ' A key (pair) exists or was generated, please run:' &&
 echo ' ./PIT.sh -i ${ip} -r' &&
 echo ' to display/retrieve the current login key' &&
 echo ' and send this key to phenocam@nau.edu (Phenocam US) to' &&
 echo ' or phenocam@uantwerpen.be (ICOS) to complete the install.' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 echo ' --> SUCCESSFUL UPLOAD OF THE INSTALLATION SCRIPT' &&
 echo ' --> THE CAMERA WILL REBOOT TO COMPLETE THE INSTALL' &&
 echo ' --> THIS CONFIGURATION USES THE - ${dest} - NETWORK' &&
 echo ' --> USING THE - ${url} - SERVER' &&
 echo '' &&
 echo ' [NOTE: the full install will take several reboot cycles (~5 min !!),' && 
 echo ' please wait before logging in or triggering the script again. The' &&
 echo ' current SSH connection will be closed for reboot in 30 sec.]' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 sh /mnt/cfg1/scripts/reboot_camera.sh
"

echo ""
echo " Please login to execute the installation script."
echo ""


# install command
BINLINE=$(awk '/^__BINARY__/ { print NR + 1; exit 0; }' $0)
tail -n +${BINLINE} $0 | ssh admin@${ip} ${command} || error_exit 2>/dev/null

#---- purge password from history ----

# remove last lines from history
# containing the password
history -d -1--2

# exit
exit 0

__BINARY__
