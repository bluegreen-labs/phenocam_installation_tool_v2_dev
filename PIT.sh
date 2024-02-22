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
 echo '125' >> /mnt/cfg1/settings.txt &&
 echo '205' >> /mnt/cfg1/settings.txt &&
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
BINLINE=$(awk '/^__BINARY__/ { print NR + 1; exit 0; }' $0)
tail -n +${BINLINE} $0 | ssh admin@${ip} ${command} || error_handler 2>/dev/null

# remove last lines from history
# containing the password
history -d -1--2

# exit
exit 0

__BINARY__
ZmlsZXMvY2hscwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NzUAMDAwMTc1
MAAwMDAxNzUwADAwMDAwMDAwNzQ0ADE0NTYyMTUwNDU3ADAxMzI3NQAgMAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAj
IS9iaW4vc2gKCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBM
YWJzIChCVikKIwojIFVuYXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25z
aWRlcmVkIGEgY29weXJpZ2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMK
Iy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tCgpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmludCBOUn0nIC9tbnQvY2ZnMS9z
ZXJ2ZXIudHh0YAphbGw9Im5hdSIKbWF0Y2g9YGdyZXAgLUUgJHthbGx9IC9tbnQvY2ZnMS9zZXJ2
ZXIudHh0IHwgd2MgLWxgCgppZiBbICR7bnJzZXJ2ZXJzfSAtZXEgJHttYXRjaH0gXTsKdGhlbgog
ZWNobyAibmV0d29yaz1waGVub2NhbSIKZmkKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZp
bGVzL3BoZW5vY2FtX2luc3RhbGwuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzU1ADAwMDE3NTAA
MDAwMTc1MAAwMDAwMDAwNzUxMQAxNDU2Mzc0NjA2NAAwMTYzMDAAIDAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEv
YmluL3NoCgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0KIyAoYykgS29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFi
cyAoQlYpCiMKIyBVbmF1dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lk
ZXJlZCBhIGNvcHlyaWdodAojIHZpb2xhdGlvbiBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLiBJZiB5
b3UgY2FtZSB0aGlzIGZhciB0aGluawojIHR3aWNlIGFib3V0IHdoYXQgeW91IGFyZSBhYm91dCB0
byBkby4gQXMgdGhpcyBtZWFucyB0aGF0IHlvdQojIHJldmVyc2UgZW5naW5lZXJlZCBwcm90ZWN0
aW9uIHRocm91Z2ggb2JmdXNjYXRpb24KIyB3aGljaCB3b3VsZCBjb25zdGl0dXRlIGEgZmlyc3Qg
Y29weXJpZ2h0IG9mZmVuc2UuCiMKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgpzbGVlcCAzMApjZCAvdmFyL3RtcAoK
IyB1cGRhdGUgcGVybWlzc2lvbnMgc2NyaXB0cwpjaG1vZCBhK3J3eCAvbW50L2NmZzEvc2NyaXB0
cy8qCgojIGdldCB0b2RheXMgZGF0ZQp0b2RheT1gZGF0ZSArIiVZICVtICVkICVIOiVNOiVTImAK
CiMgc2V0IGNhbWVyYSBtb2RlbCBuYW1lCm1vZGVsPSJOZXRDYW0gTGl2ZTIgIgoKIyB1cGxvYWQg
LyBkb3dubG9hZCBzZXJ2ZXIgLSBsb2NhdGlvbiBmcm9tIHdoaWNoIHRvIGdyYWIgYW5kCiMgYW5k
IHdoZXJlIHRvIHB1dCBjb25maWcgZmlsZXMKaG9zdD0ncGhlbm9jYW0ubmF1LmVkdScKCiMgc3Rh
cnQgbG9nZ2luZwplY2hvICItLS0tLSAke3RvZGF5fSAtLS0tLSIgPiAvdmFyL3RtcC9sb2cudHh0
CgojIGNyZWF0ZSBkZWZhdWx0IHNlcnZlcgppZiBbICEgLWYgJy9tbnQvY2ZnMS9zZXJ2ZXIudHh0
JyBdOyB0aGVuCiAgZWNobyAke2hvc3R9ID4gL21udC9jZmcxL3NlcnZlci50eHQKICBlY2hvICJ1
c2luZyBkZWZhdWx0IGhvc3Q6ICR7aG9zdH0iID4+IC92YXIvdG1wL2xvZy50eHQKICBjaG1vZCBh
K3J3IC9tbnQvY2ZnMS9zZXJ2ZXIudHh0CmZpCgojIE9ubHkgdXBkYXRlIHRoZSBzZXR0aW5ncyBp
ZiBleHBsaWNpdGx5CiMgaW5zdHJ1Y3RlZCB0byBkbyBzbywgdGhpcyBmaWxlIHdpbGwgYmUKIyBz
ZXQgdG8gVFJVRSBieSB0aGUgUElULnNoIHNjcmlwdCwgd2hpY2gKIyB1cG9uIHJlYm9vdCB3aWxs
IHRoZW4gYmUgcnVuLgoKaWYgWyBgY2F0IC9tbnQvY2ZnMS91cGRhdGUudHh0YCA9ICJUUlVFIiBd
OyB0aGVuIAoKCSMtLS0tLSByZWFkIGluIHNldHRpbmdzCglpZiBbIC1mICcvbW50L2NmZzEvc2V0
dGluZ3MudHh0JyBdOyB0aGVuCgkgY2FtZXJhPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvc2V0dGlu
Z3MudHh0YAoJIHRpbWVfb2Zmc2V0PWBhd2sgJ05SPT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0
YAoJIGNyb25fc3RhcnQ9YGF3ayAnTlI9PTQnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jv
bl9lbmQ9YGF3ayAnTlI9PTUnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9pbnQ9YGF3
ayAnTlI9PTYnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCiAJIHJlZD1gYXdrICdOUj09NycgL21u
dC9jZmcxL3NldHRpbmdzLnR4dGAKCSBncmVlbj1gYXdrICdOUj09OCcgL21udC9jZmcxL3NldHRp
bmdzLnR4dGAKCSBibHVlPWBhd2sgJ05SPT05JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YCAKCWVs
c2UKCSBlY2hvICJTZXR0aW5ncyBmaWxlIG1pc3NpbmcsIGFib3J0aW5nIGluc3RhbGwgcm91dGlu
ZSEiID4+IC92YXIvdG1wL2xvZy50eHQKCWZpCgkKICAgICAgICBwYXNzPWBhd2sgJ05SPT0xJyAv
bW50L2NmZzEvLnBhc3N3b3JkYAoKCSMtLS0tLSBzZXQgdGltZSB6b25lIG9mZnNldCAoZnJvbSBH
TVQpCgkKCS9tbnQvY2ZnMS9zY3JpcHRzLy4vc2V0X3RpbWVfem9uZS5zaAoJCgkjLS0tLS0gc2V0
IG92ZXJsYXkKCQoJIyBmb3Igbm93IGRpc2FibGUgdGhlIG92ZXJsYXkKCXdnZXQgaHR0cDovL2Fk
bWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT90ZXh0ZW5hYmxlMT0wCglmaW5kIC4gLW5hbWUg
dmIuaHRtKiAtZGVsZXRlCgkKCSMtLS0tLSBzZXQgY29sb3VyIHNldHRpbmdzCgkvdXNyL3NiaW4v
c2V0X3JnYi5zaCAwICR7cmVkfSAke2dyZWVufSAke2JsdWV9CgoJIy0tLS0tIGdlbmVyYXRlIHJh
bmRvbSBudW1iZXIgYmV0d2VlbiAwIGFuZCB0aGUgaW50ZXJ2YWwgdmFsdWUKCXJudW1iZXI9YGF3
ayAtdiBtaW49MCAtdiBtYXg9JHtjcm9uX2ludH0gJ0JFR0lOe3NyYW5kKCk7IHByaW50IGludCht
aW4rcmFuZCgpKihtYXgtbWluKzEpKX0nYAoJCgkjIGRpdmlkZSA2MCBtaW4gYnkgdGhlIGludGVy
dmFsCglkaXY9YGF3ayAtdiBpbnRlcnZhbD0ke2Nyb25faW50fSAnQkVHSU4ge3ByaW50IDU5L2lu
dGVydmFsfSdgCglpbnQ9YGVjaG8gJGRpdiB8IGN1dCAtZCcuJyAtZjFgCgkKCSMgZ2VuZXJhdGUg
bGlzdCBvZiB2YWx1ZXMgdG8gaXRlcmF0ZSBvdmVyCgl2YWx1ZXM9YGF3ayAtdiBtYXg9JHtpbnR9
ICdCRUdJTnsgZm9yKGk9MDtpPD1tYXg7aSsrKSBwcmludCBpfSdgCgkKCWZvciBpIGluICR7dmFs
dWVzfTsgZG8KCSBwcm9kdWN0PWBhd2sgLXYgaW50ZXJ2YWw9JHtjcm9uX2ludH0gLXYgc3RlcD0k
e2l9ICdCRUdJTiB7cHJpbnQgaW50KGludGVydmFsKnN0ZXApfSdgCQoJIHN1bT1gYXdrIC12IHBy
b2R1Y3Q9JHtwcm9kdWN0fSAtdiBucj0ke3JudW1iZXJ9ICdCRUdJTiB7cHJpbnQgaW50KHByb2R1
Y3QrbnIpfSdgCgkgCgkgaWYgWyAiJHtpfSIgLWVxICIwIiBdO3RoZW4KCSAgaW50ZXJ2YWw9YGVj
aG8gJHtzdW19YAoJIGVsc2UKCSAgaWYgWyAiJHN1bSIgLWxlICI1OSIgXTt0aGVuCgkgICBpbnRl
cnZhbD1gZWNobyAke2ludGVydmFsfSwke3N1bX1gCgkgIGZpCgkgZmkKCWRvbmUKCgllY2hvICJj
cm9udGFiIGludGVydmFscyBzZXQgdG86ICR7aW50ZXJ2YWx9IiA+PiAvdmFyL3RtcC9sb2cudHh0
CgoJIy0tLS0tIHNldCByb290IGNyb24gam9icwoJCgkjIHNldCB0aGUgbWFpbiBwaWN0dXJlIHRh
a2luZyByb3V0aW5lCgllY2hvICIke2ludGVydmFsfSAke2Nyb25fc3RhcnR9LSR7Y3Jvbl9lbmR9
ICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3BoZW5vY2FtX3VwbG9hZC5zaCIgPiAvbW50L2Nm
ZzEvc2NoZWR1bGUvYWRtaW4KCQoJIyB1cG9uIHJlYm9vdCBzZXQgdGltZSB6b25lCgllY2hvICJA
cmVib290IHNsZWVwIDYwICYmIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3NldF90aW1lX3pvbmUuc2gi
ID4gL21udC9jZmcxL3NjaGVkdWxlL3Jvb3QKCQoJIyB0YWtlIHBpY3R1cmUgb24gcmVib290Cgll
Y2hvICJAcmVib290IHNsZWVwIDEyMCAmJiBzaCAvbW50L2NmZzEvc2NyaXB0cy9waGVub2NhbV91
cGxvYWQuc2giID4+IC9tbnQvY2ZnMS9zY2hlZHVsZS9hZG1pbgoJCgkjIHVwbG9hZCBpcCBhZGRy
ZXNzIGluZm8KCWVjaG8gIjU5IDExICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3BoZW5vY2Ft
X2lwX3RhYmxlLnNoIiA+PiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkKCSMgcmVib290IGF0
IG1pZG5pZ2h0CgllY2hvICI1OSAyMyAqICogKiByZWJvb3QiID4+IC9tbnQvY2ZnMS9zY2hlZHVs
ZS9hZG1pbgoKZmkKCiMgdXBkYXRlIHRoZSBzdGF0ZSBvZiB0aGUgdXBkYXRlIHJlcXVpcmVtZW50
CiMgaS5lLiBza2lwIGlmIGNhbGxlZCBtb3JlIHRoYW4gb25jZSwgdW5sZXNzCiMgdGhpcyBmaWxl
IGlzIG1hbnVhbGx5IHNldCB0byBUUlVFIHdoaWNoCiMgd291bGQgcmVydW4gdGhlIGluc3RhbGwg
cm91dGluZSB1cG9uIHJlYm9vdAplY2hvICJGQUxTRSIgPiAvbW50L2NmZzEvdXBkYXRlLnR4dAoK
ZWNobyAiRmluaXNoZWQgaW5pdGlhbCBzZXR1cCIgPj4gL3Zhci90bXAvbG9nLnR4dAplY2hvICIt
LS0tIiA+PiAvdmFyL3RtcC9sb2cudHh0CgpleGl0IDAKCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVzL3BoZW5v
Y2FtX2lwX3RhYmxlLnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzU1ADAwMDE3NTAAMDAwMTc1MAAw
MDAwMDAwMjM1NAAxNDU2MTc2NzYyNAAwMTY0MTQAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEvYmluL3NoCgoj
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0KIyAoYykgS29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFicyAoQlYpCiMK
IyBVbmF1dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lkZXJlZCBhIGNv
cHlyaWdodAojIHZpb2xhdGlvbiBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLgojCiMtLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LQoKIyBzb21lIGZlZWRiYWNrIG9uIHRoZSBhY3Rpb24KZWNobyAidXBsb2FkaW5nIElQIHRhYmxl
IgoKIyBob3cgbWFueSBzZXJ2ZXJzIGRvIHdlIHVwbG9hZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5E
IHtwcmludCBOUn0nIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9
JHtucnNlcnZlcnN9ICdCRUdJTnsgbj0xOyB3aGlsZSAobiA8PSB2YXIgKSB7IHByaW50IG47IG4r
KzsgfSB9JyB8IHRyICdcbicgJyAnYAoKIyBncmFiIHRoZSBuYW1lLCBkYXRlIGFuZCBJUCBvZiB0
aGUgY2FtZXJhCkRBVEVUSU1FPWBkYXRlYAoKIyBncmFiIGludGVybmFsIGlwIGFkZHJlc3MKSVA9
YGlmY29uZmlnIGV0aDAgfCBhd2sgJy9pbmV0IGFkZHIve3ByaW50IHN1YnN0cigkMiw2KX0nYApT
SVRFTkFNRT1gYXdrICdOUj09MScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCiMgdXBkYXRlIHRo
ZSBJUCBhbmQgdGltZSB2YXJpYWJsZXMKY2F0IC9tbnQvY2ZnMS9zY3JpcHRzL3NpdGVfaXAuaHRt
bCB8IHNlZCAic3xEQVRFVElNRXwkREFURVRJTUV8ZyIgfCBzZWQgInN8U0lURUlQfCRJUHxnIiA+
IC92YXIvdG1wLyR7U0lURU5BTUV9XF9pcC5odG1sCgojIHJ1biB0aGUgdXBsb2FkIHNjcmlwdCBm
b3IgdGhlIGlwIGRhdGEKIyBhbmQgZm9yIGFsbCBzZXJ2ZXJzCmZvciBpIGluICRucnNlcnZlcnMg
OwpkbwogU0VSVkVSPWBhd2sgLXYgcD0kaSAnTlI9PXAnIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YCAK
CQogIyB1cGxvYWQgaW1hZ2UKIGVjaG8gInVwbG9hZGluZyBOSVIgaW1hZ2UgJHtpbWFnZX0iCiBm
dHBwdXQgJHtTRVJWRVJ9IC11ICJhbm9ueW1vdXMiIC1wICJhbm9ueW1vdXMiIGRhdGEvJHtTSVRF
TkFNRX0vJHtTSVRFTkFNRX1cX2lwLmh0bWwgL3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwK
CmRvbmUKCiMgY2xlYW4gdXAKcm0gL3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwKAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9jYW1f
dXBsb2FkLnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAxNzUwADAwMDAw
MDEwMTEyADE0NTYzNzQ1NTM0ADAxNjEwNgAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1
ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMtLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBMYWJzIChCVikKIwojIFVu
YXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25zaWRlcmVkIGEgY29weXJp
Z2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMKIy0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgpj
YXB0dXJlICgpIHsKCiBpbWFnZT0kMQogbWV0YWZpbGU9JDIKIGRlbGF5PSQzCiBpcj0kNAoKICMg
U2V0IHRoZSBpbWFnZSB0byBub24gSVIgaS5lLiBWSVMKIC91c3Ivc2Jpbi9zZXRfaXIuc2ggJGly
CgogIyBhZGp1c3QgZXhwb3N1cmUKIHNsZWVwICRkZWxheQoKICMgZ3JhYiB0aGUgaW1hZ2UgZnJv
bSB0aGUKIHdnZXQgaHR0cDovLzEyNy4wLjAuMS9pbWFnZS5qcGcgLU8gJHtpbWFnZX0KCiAjIGdy
YWIgZGF0ZSBhbmQgdGltZSBmb3IgYC5tZXRhYCBmaWxlcwogTUVUQURBVEVUSU1FPWBkYXRlIC1J
c2Vjb25kc2AKCiAjIGdyYWIgdGhlIGV4cG9zdXJlIHRpbWUgYW5kIGFwcGVuZCB0byBtZXRhLWRh
dGEKIGV4cG9zdXJlPWAvdXNyL3NiaW4vZ2V0X2V4cGAKCiBjYXQgbWV0YWRhdGEudHh0ID4+IC92
YXIvdG1wLyR7bWV0YWZpbGV9CiBlY2hvICJleHBvc3VyZT0kZXhwb3N1cmUiID4+IC92YXIvdG1w
LyR7bWV0YWZpbGV9CiBlY2hvICJpcl9lbmFibGU9JGlyIiA+PiAvdmFyL3RtcC8ke21ldGFmaWxl
fQogZWNobyAiZGF0ZXRpbWVfb3JpZ2luYWw9XCIkTUVUQURBVEVUSU1FXCIiID4+IC92YXIvdG1w
LyR7bWV0YWZpbGV9Cgp9CgoKIyAtLS0tLS0tLS0tLS0tLSBTRVRUSU5HUyAtLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIHJlYWQgaW4gY29uZmlndXJhdGlvbiBz
ZXR0aW5ncwojIGdyYWIgc2l0ZW5hbWUKU0lURU5BTUU9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS9z
ZXR0aW5ncy50eHRgCgojIGhvdyBtYW55IHNlcnZlcnMgZG8gd2UgdXBsb2FkIHRvCm5yc2VydmVy
cz1gYXdrICdFTkQge3ByaW50IE5SfScgL21udC9jZmcxL3NlcnZlci50eHRgCm5yc2VydmVycz1g
YXdrIC12IHZhcj0ke25yc2VydmVyc30gJ0JFR0lOeyBuPTE7IHdoaWxlIChuIDw9IHZhciApIHsg
cHJpbnQgbjsgbisrOyB9IH0nIHwgdHIgJ1xuJyAnICdgCgojIE1vdmUgaW50byB0ZW1wb3Jhcnkg
ZGlyZWN0b3J5CiMgd2hpY2ggcmVzaWRlcyBpbiBSQU0sIG5vdCB0bwojIHdlYXIgb3V0IG90aGVy
IHBlcm1hbmVudCBtZW1vcnkKY2QgL3Zhci90bXAKCiMgc2V0cyB0aGUgZGVsYXkgYmV0d2VlbiB0
aGUKIyBSR0IgYW5kIElSIGltYWdlIGFjcXVpc2l0aW9ucwpERUxBWT0zMAoKIyBncmFiIGRhdGUg
LSBrZWVwIGZpeGVkIGZvciBSR0IgYW5kIElSIHVwbG9hZHMKREFURT1gZGF0ZSArIiVhICViICVk
ICVZICVIOiVNOiVTImAKCiMgZ3JhcCBkYXRlIGFuZCB0aW1lIHN0cmluZyB0byBiZSBpbnNlcnRl
ZCBpbnRvIHRoZQojIGZ0cCBzY3JpcHRzIC0gdGhpcyBjb29yZGluYXRlcyB0aGUgdGltZSBzdGFt
cHMKIyBiZXR3ZWVuIHRoZSBSR0IgYW5kIElSIGltYWdlcyAob3RoZXJ3aXNlIHRoZXJlIGlzIGEK
IyBzbGlnaHQgb2Zmc2V0IGR1ZSB0byB0aGUgdGltZSBuZWVkZWQgdG8gYWRqdXN0IGV4cG9zdXJl
CkRBVEVUSU1FU1RSSU5HPWBkYXRlICsiJVlfJW1fJWRfJUglTSVTImAKCiMgZ3JhYiBtZXRhZGF0
YSB1c2luZyB0aGUgbWV0YWRhdGEgZnVuY3Rpb24KIyBncmFiIHRoZSBNQUMgYWRkcmVzcwptYWNf
YWRkcj1gaWZjb25maWcgZXRoMCB8IGdyZXAgSFdhZGRyIHwgYXdrICd7cHJpbnQgJDV9JyB8IHNl
ZCAncy86Ly9nJ2AKCiMgZ3JhYiBpbnRlcm5hbCBpcCBhZGRyZXNzCmlwX2FkZHI9YGlmY29uZmln
IGV0aDAgfCBhd2sgJy9pbmV0IGFkZHIve3ByaW50IHN1YnN0cigkMiw2KX0nYAoKIyBncmFiIGV4
dGVybmFsIGlwIGFkZHJlc3MgaWYgdGhlcmUgaXMgYW4gZXh0ZXJuYWwgY29ubmVjdGlvbgojIGZp
cnN0IHRlc3QgdGhlIGNvbm5lY3Rpb24gdG8gdGhlIGdvb2dsZSBuYW1lIHNlcnZlcgpjb25uZWN0
aW9uPWBwaW5nIC1xIC1jIDEgOC44LjguOCA+IC9kZXYvbnVsbCAmJiBlY2hvIG9rIHx8IGVjaG8g
ZXJyb3JgCgojIGdyYWIgdGltZSB6b25lCnR6PWBjYXQgL3Zhci9UWmAKCiMgZ3JhYiB0aGUgY29s
b3VyIGJhbGFuY2Ugc2V0dGluZ3MhISEKCiMgY3JlYXRlIGJhc2UgbWV0YS1kYXRhIGZpbGUgZnJv
bSBjb25maWd1cmF0aW9uIHNldHRpbmdzCiMgYW5kIHRoZSBmaXhlZCBwYXJhbWV0ZXJzCmVjaG8g
Im1vZGVsPU5ldENhbSBMaXZlMiIgPiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKIC9tbnQvY2ZnMS9z
Y3JpcHRzL2NobHMgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gImlwX2FkZHI9JGlwX2Fk
ZHIiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJtYWNfYWRkcj0kbWFjX2FkZHIiID4+
IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJ0aW1lX3pvbmU9JHR6IiA+PiAvdmFyL3RtcC9t
ZXRhZGF0YS50eHQKCiMgLS0tLS0tLS0tLS0tLS0gVVBMT0FEIFZJUyAtLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBjcmVhdGUgZmlsZW5hbWVzCm1ldGFmaWxlPWBl
Y2hvICR7U0lURU5BTUV9XyR7REFURVRJTUVTVFJJTkd9Lm1ldGFgCmltYWdlPWBlY2hvICR7U0lU
RU5BTUV9XyR7REFURVRJTUVTVFJJTkd9LmpwZ2AKCmNhcHR1cmUgJGltYWdlICRtZXRhZmlsZSAk
REVMQVkgMAoKIyBydW4gdGhlIHVwbG9hZCBzY3JpcHQgZm9yIHRoZSBpcCBkYXRhCiMgYW5kIGZv
ciBhbGwgc2VydmVycwpmb3IgaSBpbiAkbnJzZXJ2ZXJzOwpkbwogU0VSVkVSPWBhd2sgLXYgcD0k
aSAnTlI9PXAnIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YAogCiBlY2hvICJ1cGxvYWRpbmcgdG86ICR7
U0VSVkVSfSIKCiAjIHVwbG9hZCBpbWFnZQogZWNobyAidXBsb2FkaW5nIFZJUyBpbWFnZSAke2lt
YWdlfSIKIGZ0cHB1dCAke1NFUlZFUn0gLS11c2VybmFtZSBhbm9ueW1vdXMgLS1wYXNzd29yZCBh
bm9ueW1vdXMgIGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFnZX0gJHtpbWFnZX0KCQogZWNobyAidXBs
b2FkaW5nIFZJUyBtZXRhLWRhdGEgJHttZXRhZmlsZX0iCiBmdHBwdXQgJHtTRVJWRVJ9IC0tdXNl
cm5hbWUgYW5vbnltb3VzIC0tcGFzc3dvcmQgYW5vbnltb3VzICBkYXRhLyR7U0lURU5BTUV9LyR7
bWV0YWZpbGV9ICR7bWV0YWZpbGV9Cgpkb25lCgojIGNsZWFuIHVwIGZpbGVzCnJtICouanBnCnJt
ICoubWV0YQoKIyAtLS0tLS0tLS0tLS0tLSBVUExPQUQgTklSIC0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIGNyZWF0ZSBmaWxlbmFtZXMKbWV0YWZpbGU9YGVjaG8g
JHtTSVRFTkFNRX1fSVJfJHtEQVRFVElNRVNUUklOR30ubWV0YWAKaW1hZ2U9YGVjaG8gJHtTSVRF
TkFNRX1fSVJfJHtEQVRFVElNRVNUUklOR30uanBnYAoKY2FwdHVyZSAkaW1hZ2UgJG1ldGFmaWxl
ICRERUxBWSAxCgojIHJ1biB0aGUgdXBsb2FkIHNjcmlwdCBmb3IgdGhlIGlwIGRhdGEKIyBhbmQg
Zm9yIGFsbCBzZXJ2ZXJzCmZvciBpIGluICRucnNlcnZlcnM7CmRvCiBTRVJWRVI9YGF3ayAtdiBw
PSR7aX0gJ05SPT1wJyAvbW50L2NmZzEvc2VydmVyLnR4dGAKCiAjIHVwbG9hZCBpbWFnZQogZWNo
byAidXBsb2FkaW5nIE5JUiBpbWFnZSAke2ltYWdlfSIKIGZ0cHB1dCAke1NFUlZFUn0gLXUgImFu
b255bW91cyIgLXAgImFub255bW91cyIgIGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFnZX0gJHtpbWFn
ZX0KCQogZWNobyAidXBsb2FkaW5nIE5JUiBtZXRhLWRhdGEgJHttZXRhZmlsZX0iCiBmdHBwdXQg
JHtTRVJWRVJ9IC11ICJhbm9ueW1vdXMiIC1wICJhbm9ueW1vdXMiICBkYXRhLyR7U0lURU5BTUV9
LyR7bWV0YWZpbGV9ICR7bWV0YWZpbGV9Cgpkb25lCgojIGNsZWFuIHVwIGZpbGVzCnJtICouanBn
CnJtICoubWV0YQoKIyBSZXNldCB0byBWSVMKL3Vzci9zYmluL3NldF9pci5zaCAwCgojLS0tLS0t
LSBGRUVEQkFDSyBPTiBBQ1RJVklUWSAtLS0tLS0tLS0tLQpjYXQgImxhc3QgdXBsb2FkIGF0OiIg
Pj4gL3Zhci90bXAvbG9nLnR4dApjYXQgZGF0ZSA+PiAvdmFyL3RtcC9sb2cudHh0CgoAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9yZWJvb3RfY2FtZXJhLnNoAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAMDAwMDY2NAAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDA3NDMAMTQ1
NjE3NTA1MzYAMDE1NTU2ACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiMg
KGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5hdXRob3JpemVk
IGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmlnaHQKIyB2aW9s
YXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCnBhc3M9JDEKCiMg
c2xlZXAgMTUgc2Vjb25kcyBhbmQgdHJpZ2dlciByZWJvb3QKc2xlZXAgMTIKCiMgbW92ZSBpbnRv
IHRlbXBvcmFyeSBkaXJlY3RvcnkKY2QgL3Zhci90bXAKCiMgcmVib290CndnZXQgaHR0cDovL2Fk
bWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9pcGNhbXJlc3RhcnRjbWQgJj4vZGV2L251bGwK
CgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvc2V0X3RpbWVfem9uZS5zaAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAxMjQzADE0NTYz
NzQzNzA0ADAxNTYxNgAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMtLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIChj
KSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBMYWJzIChCVikKIwojLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMt
LS0tLSByZWFkIGluIHNldHRpbmdzCmlmIFsgLWYgJy9tbnQvY2ZnMS9zZXR0aW5ncy50eHQnIF07
IHRoZW4KIHRpbWVfb2Zmc2V0PWBhd2sgJ05SPT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApl
bHNlCiBlY2hvICJTZXR0aW5ncyBmaWxlIG1pc3NpbmcsIGFib3J0aW5nIGluc3RhbGwgcm91dGlu
ZSEiID4+IC92YXIvdG1wL2xvZy50eHQKZmkKCQojLS0tLS0gc2V0IHRpbWUgem9uZSBvZmZzZXQg
KGZyb20gVVRDKQoJCiMgc2V0IHRpbWUgem9uZQojIGR1bXAgc2V0dGluZyB0byBjb25maWcgZmls
ZQpTSUdOPWBlY2hvICR7dGltZV9vZmZzZXR9IHwgY3V0IC1jJzEnYAoKaWYgWyAiJFNJR04iID0g
IisiIF07IHRoZW4KIGVjaG8gIkdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8rLy0vZycgPiAv
dmFyL1RaCmVsc2UKIGVjaG8gIkdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8tLysvZycgPiAv
dmFyL1RaCmZpCgkKZXhpdCAwCgoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvc2l0ZV9pcC5odG1sAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAADAwMDA2NjQAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAwNTYwADE0NTM2NTUy
NTAwADAxNDczMAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1
c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8IURPQ1RZUEUgaHRtbCBQVUJMSUMgIi0vL1czQy8v
RFREIEhUTUwgNC4wIFRyYW5zaXRpb25hbC8vRU4iPgo8aHRtbD4KPGhlYWQ+CjxtZXRhIGh0dHAt
ZXF1aXY9IkNvbnRlbnQtVHlwZSIgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PWlzby04ODU5
LTEiPgo8dGl0bGU+TmV0Q2FtU0MgSVAgQWRkcmVzczwvdGl0bGU+CjwvaGVhZD4KPGJvZHk+ClRp
bWUgb2YgTGFzdCBJUCBVcGxvYWQ6IERBVEVUSU1FPGJyPgpJUCBBZGRyZXNzOiBTSVRFSVAKJmJ1
bGw7IDxhIGhyZWY9Imh0dHA6Ly9TSVRFSVAvIj5WaWV3PC9hPgomYnVsbDsgPGEgaHJlZj0iaHR0
cDovL1NJVEVJUC9hZG1pbi5jZ2kiPkNvbmZpZ3VyZTwvYT4KPC9ib2R5Pgo8L2h0bWw+CgAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAA=