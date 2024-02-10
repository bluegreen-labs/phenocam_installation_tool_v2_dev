#!/bin/bash

tar -cf install files/*.sh
base64 install > install.bin

cat PITe.sh > PIT.sh
cat install.bin >> PIT.sh

rm install*

chmod +x PIT.sh
