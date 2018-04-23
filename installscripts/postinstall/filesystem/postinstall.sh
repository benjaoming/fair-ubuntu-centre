#!/bin/bash

if [ "$1" == '--no-reboot' ]
then
	NO_REBOOT="yes"
else
	NO_REBOOT="no"
fi

# Create a utility script that will re-download the postinstall
echo "#!/bin/sh" > "/root/rerun-postinstall.sh"
echo "rm -Rf /root/postinstall" >> "/root/rerun-postinstall.sh"
echo "mkdir -p /root/postinstall" >> "/root/rerun-postinstall.sh"
echo "cd /root/postinstall" >> "/root/rerun-postinstall.sh"
echo "wget -O postinstall.tar.gz http://192.168.10.1/postinstall.tar.gz" >> "/root/rerun-postinstall.sh"
echo "tar xfz postinstall.tar.gz" >> "/root/rerun-postinstall.sh"
echo "./postinstall.sh" >> "/root/rerun-postinstall.sh"

# WHY DOES THIS NOT WORK???
export DEBCONF_FRONTEND=noninteractive

# Stop lightdm
/etc/init.d/lightdm stop

# Fix old fstab
#sed -i 's/^.*nfs.*$//g' /etc/fstab

# TODO: Possibly remove this when figured out that it's not a bug anymore
# Ensure correct permissions on /root
chown -R root.root /root

cd /root/postinstall

# If we are running on a previous installation, the computer has an ID
if [ -f /etc/computer_label_id ]
then
	label=`cat /etc/computer_label_id`
	echo "$label-fair-client" > /etc/hostname
else
	echo "fair-client" > /etc/hostname
fi

# Remove student from admin group
deluser student sudo
deluser student lpadmin
deluser student sambashare
adduser student floppy
adduser student cdrom
echo "student:student" | chpasswd

# Create a teacher account
useradd -m -U -s /bin/bash teacher
usermod teacher --comment "Teacher"
echo "teacher:ilovestudents" | chpasswd
adduser teacher sudo
adduser teacher adm
adduser teacher dialout
adduser teacher fax
adduser teacher cdrom
adduser teacher floppy
adduser teacher tape
adduser teacher dip
adduser teacher video
adduser teacher plugdev
adduser teacher fuse
adduser teacher lpadmin
adduser teacher sambashare
adduser teacher epoptes

mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat server_id_rsa.pub > /root/.ssh/authorized_keys
cat teacher/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

if [ -f local/interfaces ]
then
	cp local/interfaces /etc/network/interfaces
else
	# Detect main ethernet device, it is not always eth0
	main_ethernet_device=`ifconfig -a | grep ":Ethernet" | egrep -m 1 -o "^\w+"`
	echo "auto lo" > /etc/network/interfaces
	echo "iface lo inet loopback" >> /etc/network/interfaces
	echo "" >> /etc/network/interfaces
	echo "auto $main_ethernet_device" >> /etc/network/interfaces
	echo "iface $main_ethernet_device inet dhcp" >> /etc/network/interfaces
fi

/etc/init.d/networking restart

cp sources.list /etc/apt/

# Make sure previous abn. terminated instances of DPKG are fixed
echo "Ensuring constency of package installation"
dpkg --configure -a
apt-get -y -f install

echo "Update repositories from server"
apt-get update

# Install extra packages
echo "Install extra software"
apt-get install -q -y `cat packages.install.lst | egrep "^[^#]+$"`

# These ones do not support noninteractive mode
echo "Retry some package configurations that do not allow noninteractive mode"
dpkg --configure -a

# Remove packages - do this AFTER installing, because some meta packages
# like edubuntu-desktop will install Thunderbird and the likes...
echo "Remove unwanted packages"
apt-get remove -q -y `cat packages.remove.lst | egrep "^[^#]+$"`

echo "Remove unecessary packages"
apt-get -q -y autoremove

# Removing programs from autostart
#rm -f /etc/xdg/autostart/update-notifier.desktop
#rm -f /etc/xdg/autostart/nm-applet.desktop
rm -f /etc/xdg/autostart/gnome-keyring-pkcs11.desktop
#rm -f /etc/xdg/autostart/gnome-power-manager.desktop
#rm -f /etc/xdg/autostart/bluetooth-applet.desktop
rm -f /etc/xdg/autostart/evolution-alarm-notify.desktop
rm -f /etc/xdg/autostart/ubuntuone-launch.desktop

# Disable annoying and useless HUD service
chmod -x /usr/lib/i386-linux-gnu/hud/hud-service

bash install_create_homes.sh

mkdir -p /var/movies/
mkdir -p /var/materials/

cp mount_shares /etc/init.d/
chmod +x /etc/init.d/mount_shares
update-rc.d -f mount_shares remove
update-rc.d mount_shares defaults
/etc/init.d/mount_shares start


# Make student the default login
#sudo /usr/lib/lightdm/lightdm-set-defaults --autologin student
gpasswd -a student nopasswdlogin

# Do not require any further permissions for mounting and unmounting
# filesystems, affects USB fash
cp -f org.freedesktop.udisks2.policy /usr/share/polkit-1/actions/org.freedesktop.udisks2.policy


#############################
# local/ folder instructions
#############################

# Remove extra packages for center
if [ -f local/packages.remove.lst ]
then
	apt-get remove -q -y `cat local/packages.remove.lst | egrep "^[^#]+$"`
	apt-get -q -y autoremove
fi
# Install extra packages for center
if [ -f local/packages.install.lst ]
then
	apt-get install -q -y `cat local/packages.install.lst | egrep "^[^#]+$"`
fi

# Copy etc structure over the existing one.
cp -rf etc/* /etc/
mkdir -p /opt
cp -rf opt/* /opt/

# Make LightDM scripts executalbe
chmod +x /etc/lightdm/*sh

# A utility script that adds a configuration to force X to use VESA
cp force_vesa* /root/
chmod +x /root/force_vesa*.sh

# After copying in the /etc structure, a new keyboard layout may have been set
# and because of a weird bug, we need to re-run this configuration to
# regenerate some init image for kernel and then it will work after reboot
dpkg-reconfigure -phigh keyboard-configuration

# Execute final local configuration script
cd local
cp -Rf filesystem/* /
bash final.sh
cd ..

# Create home directories for teachers and students
/etc/init.d/create_homes start
/etc/init.d/mount_shares start

# DONE! --remove from rc.local

sleep 1s

# Remove edubuntu theme because it doesn't work fully
# with plymouth

apt-get remove -y -q plymouth-theme-edubuntu

cp register_computer /root/register_computer

echo ". /root/register_computer" > /etc/rc.local

if [ ! $NO_REBOOT = "yes" ]
then
	reboot
fi
