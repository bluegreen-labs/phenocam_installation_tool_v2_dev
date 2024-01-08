#!/bin/sh

echo "Trying to capture a raw image" >> /var/tmp/log.txt

debugmode="yes"
loopaddr="admin:phen0cam@127.0.0.1"

tempdir=/var/tmp  #our temporary working folder.
mkdir -p $tempdir #This folder likely exists, but make sure.
cd $tempdir       #use the dram, don't wear out flash. /var/tmp most space

getEXIF()
{
 i2cset -yf 0 0x21 0x20 1 #buffer sequential bytes of EXIF info. 
 swl=`i2cget -yf 0 0x21 0x20 | cut -b3-4 2>> /var/tmp/log.txt` #low exposure (shut width)
 swh=`i2cget -yf 0 0x21 0x20 2>> /var/tmp/log.txt` #high exposure number of rows
 shutwidth=$swh$swl #Full exposure in ascii hex (e.g. 0x0464)
 rpsl=`i2cget -yf 0 0x21 0x20 | cut -b3-4 2>> /var/tmp/log.txt` #low
 rpsh=`i2cget -yf 0 0x21 0x20 2>> /var/tmp/log.txt` #high 
 rowspersec=$rpsh$rpsl #rows per second in ascii hex (e.g. 0x83D6)
 bll=`i2cget -yf 0 0x21 0x20 | cut -b3-4 2>> /var/tmp/log.txt` #low black level
 blh=`i2cget -yf 0 0x21 0x20 2>> /var/tmp/log.txt` #high 
 blacklev=$blh$bll #blacklevel (pedestal e.g. 0x0048)
}

#Shows EXIF info, after it's gathered. Only in debugmode=yes.
showEXIF()
{
if [ $debugmode = "yes" ]; then
 echo Shutter width ${shutwidth}
 echo Rows per second ${rowspersec}
 echo Black level ${blacklev}
fi
}

#Capture a raw dump (It's not a DNG yet). 
# Returns $rawname= file made, or "none"

getDUMP()
{ 
 echo vcap0_0_0_2 o $tempdir > /proc/videograph/gs/dump #make raw pic
 datetimestring=`date +"%Y_%m_%d_%H%M%S"`
 for i in 1 2 3 #if it goes over 3 secs, abort!
 do
  sleep 1s  #1s should do it for dump, most of the time.
  dumpfile=`ls vcap0_0_0_2* 2>> /var/tmp/log.txt`  
  if [ -z "$dumpfile" ]
  then
   echo Extra sleep needed for vcap.
   rawname="none"
  else
   rawname=mycamera_${datetimestring}.dng
   mv $dumpfile $rawname  
   break
  fi
 done
}

#Start of script to upload 2 images, one with IR closed, one open.
#First clean oldd files, save IR state, make open and closed values
find . -name "vcap0_0_0_2*" -delete #delete leftovers
oldreg7=`i2cget -yf 0 0x21 7 2>> /var/tmp/log.txt` #save IR reg contents
irclose=`echo $oldreg7 | sed s/./0/3` #Replace top nibble with IR closed 
iropen=`echo $oldreg7 | sed s/./1/3` #Replace top nibble with IR open bits

echo $oldreg7 >> /var/tmp/log.txt
echo $irclose >> /var/tmp/log.txt
echo $iropen >> /var/tmp/log.txt

#Close IR so it can settle before we lock exposure with raw mode.
i2cset -yf 0 0x21 7 $irclose 2>> /var/tmp/log.txt #IR closed
sleep 1s #needs time to close and adjust exposure. 
#raw mode increases H.264 size and we need time to expand buffers
#if it's the first time this ran. 

echo Entering raw mode...
i2cset -y -f 0 0x21 0x1F 1 2>> /var/tmp/log.txt #trigger raw mode, lock exposure
find . -name vb.htm* -delete #clean up possible leftovers: wget won't overwrite.
wget http://${loopaddr}/vb.htm?EnableTextForRaw=0 #Overlay off. Note: causes output on concole of 0, 0 and 0 on console.
find . -name "vb.*" -delete
sleep 4 #overlay goes off in < 2 sec, but raw mode causes need for buffer increases, so wait.

#grab EXIF info for these pics.  shutwdth,exprows wont change. blklv can. 
getEXIF
showEXIF >> /var/tmp/log.txt
getDUMP

if [ $rawname = "none" ]; then
 echo FAILED to make first raw picture! >> /var/tmp/log.txt
 exit 1 #oops. didnt make first pic.
fi

echo Exiting raw mode...
i2cset -y -f 0 0x21 0x1F 2 2>> /var/tmp/log.txt #exit raw mode, free up visual images mode and exposure.
wget http://${loopaddr}/vb.htm?textenable1
overlaystate=`cat vb.htm?textenable1 | grep -o '.\{1\}$'` #Get config's overlay state
find . -name vb.htm* -delete  
wget http://$loopaddr/vb.htm?EnableTextForRaw=$overlaystate #Set it, without flash write.
find . -name "vb.*" -delete


echo First raw picture! >> /var/tmp/log.txt
#ftpput $vb -u anonymous -p "anonymous"  ${uploadfolder}/${rawname} ${rawname}
rm ${rawname}

