#!/bin/bash

# Here we set up the NFS server, and the directories that it depends on.
# We also create the teacher account here.

# Include variables defined externally

if [ -n "${SCRIPT_ROOT}" ]; then

        echo "Globals already defined"
else
        SCRIPT="`readlink -e $0`"
        SCRIPTPATH="`dirname $SCRIPT`"
        echo "Including global variables"
        export SCRIPT_ROOT=$SCRIPTPATH/..
        . $SCRIPTPATH/../config/default_cfg.sh
fi


echo "---------------------------------------"
echo "Installing NFS server                  "
echo "---------------------------------------"

if [ ! /home/teacher ]
then
	echo "Creating a teacher account and a shared NFS folder"
	useradd -m -U -s /bin/bash teacher
	echo "teacher:${TEACHER_PASSWORD}" | chpasswd
	mkdir -p /home/teacher/materials
	chown teacher.teacher /home/teacher/materials
fi

# The server should be installed BEFORE modifying /etc/exports, otherwise a prompt appears with no automatic way to circumvent it...
apt-get install -y -q nfs-kernel-server

# Define which folders to share
#cat etc.exports > /etc/exports

echo "${FAIR_ARCHIVE_PATH}/ubuntu/ *(ro,no_subtree_check,no_root_squash)
${FAIR_ARCHIVE_PATH}/data/movies/ *(ro,no_subtree_check,no_root_squash)
/home/teacher/materials/ *(rw,no_subtree_check,no_root_squash)" > /etc/exports

/etc/init.d/nfs-kernel-server restart
