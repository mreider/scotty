#!/bin/sh
#
# Update all repositories under 'software'
#

if [ ! -d "software" ]; then
  echo software directory not found.
  exit 1
fi

cd software

for dir in $(ls)
do
  cd ${dir}
  echo Updating ${dir}...
  git pull
  cd ..
done

cd ..
