#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted.
#
#--------------------------------------------------------------------

sleep 30
cd /var/tmp

# get todays date
today=`date +"%Y %m %d %H:%M:%S"`

# set camera model name
model="NetCam Live2 "

# upload / download server - location from which to grab and
# and where to put config files
host='phenocam.nau.edu'

# start logging
echo "----- ${today} -----" > /var/tmp/log.txt

# create default server list if required
if [ ! -f '/mnt/cfg1/server.txt' ]; then
 echo ${host} > /mnt/cfg1/server.txt
 echo "using default host: ${host}" >> /var/tmp/log.txt
 chmod a+rw /mnt/cfg1/server.txt
fi

# update permissions scripts
chmod a+rwx /mnt/cfg1/scripts/*

# Only update the settings if explicitly
# instructed to do so, this file will be
# set to TRUE by the PIT.sh script, which
# upon reboot will then be run.

if [ `cat /mnt/cfg1/update.txt` = "TRUE" ]; then 

	#----- read in settings
	if [ -f '/mnt/cfg1/settings.txt' ]; then
	 camera=`awk 'NR==1' /mnt/cfg1/settings.txt`
	 time_offset=`awk 'NR==2' /mnt/cfg1/settings.txt`
	 TZ=`awk 'NR==3' /mnt/cfg1/settings.txt`
	 cron_start=`awk 'NR==4' /mnt/cfg1/settings.txt`
	 cron_end=`awk 'NR==5' /mnt/cfg1/settings.txt`
	 cron_int=`awk 'NR==6' /mnt/cfg1/settings.txt`
 	 red=`awk 'NR==7' /mnt/cfg1/settings.txt`
	 green=`awk 'NR==8' /mnt/cfg1/settings.txt`
	 blue=`awk 'NR==9' /mnt/cfg1/settings.txt` 
	else
	 echo "Settings file missing, aborting install routine!" >> /var/tmp/log.txt
	fi

	#----- set time zone
	echo ${TZ} > /var/TZ # REQUIRES ROOT PERMISSIONS
	
	#----- set overlay
	
	find . -name vb.htm* -delete
	wget http://admin:admin@127.0.0.1/vb.htm?overlaytext1=TEST
	find . -name vb.htm* -delete
	
	# cycle overlay
	wget http://admin:admin@127.0.0.1/vb.htm?textenable1=0
	find . -name vb.htm* -delete
	wget http://admin:admin@127.0.0.1/vb.htm?textenable1=1
	find . -name vb.htm* -delete
	
	#----- set colour settings
	/usr/sbin/set_rgb.sh 0 ${red} ${green} ${blue}

	#----- generate random number between 0 and the interval value
	rnumber=`awk -v min=0 -v max=${cron_int} 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
	
	# divide 60 min by the interval
	div=`awk -v interval=${cron_int} 'BEGIN {print 59/interval}'`
	int=`echo $div | cut -d'.' -f1`
	
	# generate list of values to iterate over
	values=`awk -v max=${int} 'BEGIN{ for(i=0;i<=max;i++) print i}'`
	
	for i in ${values}; do
	 product=`awk -v interval=${cron_int} -v step=${i} 'BEGIN {print int(interval*step)}'`	
	 sum=`awk -v product=${product} -v nr=${rnumber} 'BEGIN {print int(product+nr)}'`
	 
	 if [ "${i}" -eq "0" ];then 
	  interval=`echo ${sum}`
	 else
	  if [ "$sum" -le "59" ];then
	   interval=`echo ${interval},${sum}`
	  fi
	 fi
	done

	echo $interval
	echo "crontab intervals set to: ${interval}" >> /var/tmp/log.txt

	#----- set root cron jobs
	
	# set the main picture taking routine
	echo "${interval} ${cron_start}-${cron_end} * * * sh /mnt/cfg1/scripts/phenocam_upload.sh" > /mnt/cfg1/schedule/admin
	
	# upload ip address info
	echo "59 11 * * * sh /mnt/cfg1/scripts/phenocam_ip_table.sh" >> /mnt/cfg1/schedule/admin
		
	# reboot at midnight
	echo "59 23 * * * reboot" >> /mnt/cfg1/schedule/admin

fi

# update the state of the update requirement
# i.e. skip if called more than once, unless
# this file is manually set to TRUE which
# would rerun the install routine upon reboot
echo "FALSE" > /mnt/cfg1/update.txt

echo "Finished initial setup" >> /var/tmp/log.txt
echo "----" >> /var/tmp/log.txt

exit 0

