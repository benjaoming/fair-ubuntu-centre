#!/bin/bash

# Enable tracebacks
# Save my own path
MY_DIR=`pwd .`

set -eu
bash $MY_DIR/installscripts/traceback.sh

BRANCH=${1:-"master"}

if ! [ -d build ]
then
	mkdir -p build
fi

git archive $BRANCH installscripts/ | tar x -C build/

cd build/installscripts/data/intranet/
if [ ! -d virtualenv ]
then
	echo "Getting wagtail build dependencies"
	sudo apt-get install python-dev python-pip g++ libjpeg62-dev zlib1g-dev python-virtualenv
	virtualenv virtualenv
	virtualenv --relocatable virtualenv
fi

echo "Installing requirements.txt..."
source virtualenv/bin/activate
pip install -r fairintranet/requirements.txt
cd fairintranet
python manage.py collectstatic --noinput
cd ../

cd ../../../

echo "Creating tarball..."
tar cfz installscripts.tar.gz installscripts
