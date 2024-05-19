#!/bin/bash

tar -cf install files/*

cat PITe.sh > PIT.sh
base64 install >> PIT.sh

rm install*
chmod +x PIT.sh

exit 0

# move files into public repo
if [ -d "../phenocam_installation_tool_v2/" ];
then
 cp README.md ../phenocam_installation_tool_v2/
 mv PIT.sh ../phenocam_installation_tool_v2/

 cd ../phenocam_installation_tool_v2/
 git add PIT.sh
 git commit -am "update PIT"
 git push
fi
