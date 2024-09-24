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

# -------------- SETTINGS -------------------------------------------

# Move into temporary directory
# which resides in RAM, not to
# wear out other permanent memory
cd /var/tmp

# how many servers do we upload to
nrservers=`awk 'END {print NR}' /mnt/cfg1/server.txt`
nrservers=`awk -v var=${nrservers} 'BEGIN{ n=1; while (n <= var ) { print n; n++; } }' | tr '\n' ' '`

# -------------- VALIDATE LOGIN --------------------------------------

if [ ! -f "/mnt/cfg1/phenocam_key" ]; then
 echo "no sFTP key found, nothing to be done..."
 exit 0
fi

# run the upload script for the ip data
# and for all servers
for i in $nrservers;
do
  SERVER=`awk -v p=$i 'NR==p' /mnt/cfg1/server.txt`
 
  echo "" 
  echo "Checking server: ${SERVER}"
  echo ""

  echo "exit" > batchfile
  sftp -b batchfile -i "/mnt/cfg1/phenocam_key" phenosftp@${SERVER} >/dev/null 2>/dev/null

  # if status output last command was
  # 0 set service to sFTP
  if [ $? -eq 0 ]; then
    echo "SUCCES... secure sFTP login worked"
    echo ""
  else
    echo "FAILED... secure sFTP login did not work"
    echo ""
  fi
  
  # cleanup
  rm batchfile
done

exit 0
