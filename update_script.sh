#!/bin/bash

tar -cf install files/*

cat PITe.sh > PIT.sh
base64 install >> PIT.sh

rm install*
chmod +x PIT.sh

#exit 0

# move files into public repo
if [ -d "../phenocam_installation_tool_v2/" ];
then

 cd ../phenocam_installation_tool_v2/

 # checkout ICOS branch
 git checkout -b icos
 git push --set-upstream origin icos

 cp ../phenocam_installation_tool_v2_dev/INSTALL.md README.md
 cp ../phenocam_installation_tool_v2_dev/PITpass.sh .
 mv ../phenocam_installation_tool_v2_dev/PIT.sh .
 
 git add PIT.sh
 git add PITpass.sh
 git commit -am "update PIT"
 git push
fi
