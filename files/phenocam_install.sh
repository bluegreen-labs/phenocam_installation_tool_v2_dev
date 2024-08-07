#!/bin/sh

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# Unauthorized changes to this script are considered a copyright
# violation and will be prosecuted. If you came this far think
# twice about what you are about to do. As this means that you
# reverse engineered protection through obfuscation
# which would constitute a first copyright offense.
#
#--------------------------------------------------------------------

sleep 30
cd /var/tmp

# update permissions scripts
chmod a+rwx /mnt/cfg1/scripts/*

# get todays date
today=`date +"%Y %m %d %H:%M:%S"`

# set camera model name
model="NetCam Live2"

# upload / download server - location from which to grab and
# and where to put config files
host='phenocam.nau.edu'

# create default server
if [ ! -f '/mnt/cfg1/server.txt' ]; then
  echo ${host} > /mnt/cfg1/server.txt
  echo "using default host: ${host}" >> /var/tmp/log.txt
  chmod a+rw /mnt/cfg1/server.txt
fi

# Only update the settings if explicitly
# instructed to do so, this file will be
# set to TRUE by the PIT.sh script, which
# upon reboot will then be run.

if [ `cat /mnt/cfg1/update.txt` = "TRUE" ]; then 

	# start logging
	echo "----- ${today} -----" >> /var/tmp/log.txt

	#----- read in settings
	if [ -f '/mnt/cfg1/settings.txt' ]; then
	 camera=`awk 'NR==1' /mnt/cfg1/settings.txt`
	 time_offset=`awk 'NR==2' /mnt/cfg1/settings.txt`
	 cron_start=`awk 'NR==4' /mnt/cfg1/settings.txt`
	 cron_end=`awk 'NR==5' /mnt/cfg1/settings.txt`
	 cron_int=`awk 'NR==6' /mnt/cfg1/settings.txt`
	 
	 # colour balance
 	 red=`awk 'NR==7' /mnt/cfg1/settings.txt`
	 green=`awk 'NR==8' /mnt/cfg1/settings.txt`
	 blue=`awk 'NR==9' /mnt/cfg1/settings.txt`
	 
	 # read in the brightness/sharpness/hue/saturation values
	 brightness=`awk 'NR==10' /mnt/cfg1/settings.txt`
	 sharpness=`awk 'NR==11' /mnt/cfg1/settings.txt`
	 hue=`awk 'NR==12' /mnt/cfg1/settings.txt`
	 contrast=`awk 'NR==13' /mnt/cfg1/settings.txt`	 
	 saturation=`awk 'NR==14' /mnt/cfg1/settings.txt`
	 blc=`awk 'NR==15' /mnt/cfg1/settings.txt`
	else
	 echo "Settings file missing, aborting install routine!" >> /var/tmp/log.txt
	fi
	
        pass=`awk 'NR==1' /mnt/cfg1/.password`

	#----- set time zone offset (from GMT)
	
	# set sign time zone
	SIGN=`echo ${time_offset} | cut -c'1'`

	# note the weird flip in the netcam cameras
	if [ "$SIGN" = "+" ]; then
	 TZ=`echo "GMT${time_offset}" | sed 's/+/%2D/g'`
	else
	 TZ=`echo "GMT${time_offset}" | sed 's/-/%2B/g'`
	fi

	# call API to set the time 
	wget http://admin:${pass}@127.0.0.1/vb.htm?timezone=${TZ}
	
	# clean up detritus
	rm vb*
	
	echo "time set to (ascii format): ${TZ}" >> /var/tmp/log.txt
	
	#----- set overlay
	
	# convert to ascii
	if [ "$SIGN" = "+" ]; then
	 time_offset=`echo "${time_offset}" | sed 's/+/%2B/g'`
	else
	 time_offset=`echo "${time_offset}" | sed 's/-/%2D/g'`
	fi
	
	# overlay text
	overlay_text=`echo "${camera} - ${model} - %a %b %d %Y %H:%M:%S - GMT${time_offset}" | sed 's/ /%20/g'`
	
	# for now disable the overlay
	wget http://admin:${pass}@127.0.0.1/vb.htm?overlaytext1=${overlay_text}
	
	# clean up detritus
	rm vb*
	
	echo "header set to: ${overlay_text}" >> /var/tmp/log.txt
	
	#----- set colour settings
	
	# call API to set the time 
	wget http://admin:${pass}@127.0.0.1/vb.htm?brightness=${brightness}
	wget http://admin:${pass}@127.0.0.1/vb.htm?contrast=${contrast}
	wget http://admin:${pass}@127.0.0.1/vb.htm?sharpness=${sharpness}
	wget http://admin:${pass}@127.0.0.1/vb.htm?hue=${hue}
	wget http://admin:${pass}@127.0.0.1/vb.htm?saturation=${saturation}
	
	# clean up detritus
	rm vb*
		
	# set RGB balance
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

	echo "crontab intervals set to: ${interval}" >> /var/tmp/log.txt

	#----- set root cron jobs
	
	# set the main picture taking routine
	echo "${interval} ${cron_start}-${cron_end} * * * sh /mnt/cfg1/scripts/phenocam_upload.sh" > /mnt/cfg1/schedule/admin
		
	# upload ip address info at midday
	echo "59 11 * * * sh /mnt/cfg1/scripts/phenocam_ip_table.sh" >> /mnt/cfg1/schedule/admin
		
	# reboot at midnight on root account
	echo "59 23 * * * sh /mnt/cfg1/scripts/reboot_camera.sh" > /mnt/cfg1/schedule/root
	
	# info
	echo "Finished initial setup" >> /var/tmp/log.txt

	#----- finalize the setup + reboot

	# update the state of the update requirement
	# i.e. skip if called more than once, unless
	# this file is manually set to TRUE which
	# would rerun the install routine upon reboot
	echo "FALSE" > /mnt/cfg1/update.txt

	# rebooting camera to make sure all
	# the settings stick
	sh /mnt/cfg1/scripts/reboot_camera.sh
fi

# clean exit
exit 0

