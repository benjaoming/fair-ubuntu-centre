echo "---------------------------------------"
echo "Configuring the network on eth0"
echo "---------------------------------------"

# We get rid of the automatic network configuration tool to do things ourself
# PDO: The remove is commented out (which I'm thankful for on my development machine), but should the network manager really be removed or not?  Also, I'm not using gnome, but Lubuntu (derrived from LXDE) which has a different network manager...
#apt-get remove -y -q dnsmasq-base network-manager network-manager-gnome

# The network manager conflicts with the dnsmasq package, so if we want to keep it (and I do for development) we have to reconfigure it
# see also: http://sokratisg.net/2012/03/31/ubuntu-precise-12-04-get-rid-of-nms-dnsmasq-and-setup-your-own/
cat ${FAIR_INSTALL_DATA}/etc.NetworkManager.conf > /etc/NetworkManager/NetworkManager.conf
restart network-manager
sleep 5

#PDO: The ifup command fails on my development system, maybe because I'm still using the network manager.
cat ${FAIR_INSTALL_DATA}/etc.network.interfaces > /etc/network/interfaces
ifdown -a
ifup -a


echo "Blacklisting IPv6 modules due to a bug"

sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"/g' /etc/default/grub

echo "Switching off IPv6"
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6


echo "Altering /etc/hosts"
# Here we add a number of hostnames to the 'hosts' file, so we can resolve the various alaises we have for the FAIR server.  Note that the IP address is fixed in the /etc/network/interfaces.

if ! grep "$FAIR_SERVER_HOSTNAME" /etc/hosts -q
then
	echo "127.0.0.1 $FAIR_SERVER_HOSTNAME" >> /etc/hosts
fi

if ! grep "192.168.10.1" /etc/hosts -q
then
	echo 192.168.10.1 intranet intranet.fair fair repo.fair wikipedia.fair repo dvd.fair khan.fair khan >> /etc/hosts
fi

if ! grep "archive.canonical.com" /etc/hosts -q
then
	echo 192.168.10.1 archive.canonical.com >> /etc/hosts
fi


# Set the hostname permenantly
echo "$FAIR_SERVER_HOSTNAME" > /etc/hostname
# Set the hostname right now, so we don't have to wait for a reboot
hostname "$FAIR_SERVER_HOSTNAME"


echo "---------------------------------------"
echo "Installing dnsmasq DHCP & DNS server   "
echo "---------------------------------------"

# remove resolvconf so it doesn't write 127.0.0.1 in /etc/resolv.conf
apt-get remove -y -q resolvconf

# Note: The command is a test of the local Ubuntu repository; it will fail if the server can't find the installation packages.
apt-get install -y -q dnsmasq

echo "Creating configuration file /etc/dnsmasq.d/fair"
# This file configures the DHCP server, including which interface, which range of IP, and the location of the TFTP server
cat ${FAIR_INSTALL_DATA}/etc.dnsmasq.d.fair > /etc/dnsmasq.d/fair

# Create the TFTP dir now, or else DSNMasq complains (the directory is populated later)
mkdir -p /var/tftp

/etc/init.d/dnsmasq restart


echo "---------------------------------------"
echo "Installing NTP time server             "
echo "---------------------------------------"
# Deleting old config prevents prompt when installing ntp.
rm /etc/ntp.conf

apt-get install -y -q ntp
echo "Copying NTP configuration..."
cat ${FAIR_INSTALL_DATA}/etc.ntp.conf > /etc/ntp.conf
/etc/init.d/ntp restart


