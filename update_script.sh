#!/bin/bash

tar -cf install files/*

cat PITe.sh > PIT.sh
cat install >> PIT.sh

rm install*

chmod +x PIT.sh

git add PIT.sh
git commit -am "update PIT"
git push

