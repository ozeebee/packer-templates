#!/bin/bash

echo "Fix slow DNS"
echo "  (PACKER_BUILDER_TYPE = '$PACKER_BUILDER_TYPE')"
if [[ "$PACKER_BUILDER_TYPE" == "virtualbox-iso" ]]; then
	## https://access.redhat.com/site/solutions/58625 (subscription required)
	# add 'single-request-reopen' so it is included when /etc/resolv.conf is generated
	echo 'RES_OPTIONS="single-request-reopen"' >> /etc/sysconfig/network
	service network restart
	echo 'Slow DNS fix applied (single-request-reopen)'
else
	echo 'Slow DNS fix not required for this platform, skipping'
fi

echo "Installing VirutalBox Guest additions..."
yum -y install kernel-uek-devel
mkdir -p /media/dvd
mount -o loop VBoxGuestAdditions*.iso /media/dvd
sh /media/dvd/VBoxLinuxAdditions.run --nox11
umount /media/dvd
rm VBoxGuestAdditions*.iso

echo "Creating vagrant user..."
groupadd admin
useradd -G admin -m -s /bin/bash vagrant
echo "vagrant" | passwd vagrant > /dev/null 2>&1

echo "Enabling password-less sudo..."
cp /etc/sudoers /etc/sudoers.orig
sed -i -e 's/Defaults\s*requiretty$/#Defaults\trequiretty/' /etc/sudoers
sed -i -e '/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/a %admin\tALL=(ALL)\tNOPASSWD: ALL' /etc/sudoers
sed -i -e '/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/a Defaults env_keep=\"SSH_AUTH_SOCK\"' /etc/sudoers

echo "Installing vagrant insecure public key..."
mkdir /home/vagrant/.ssh
wget --no-check-certificate \
    'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub' \
    -O /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh
chmod -R go-rwsx /home/vagrant/.ssh

echo "Disabling ssh reverse dns lookup..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.ori
echo "UseDNS no" >> /etc/ssh/sshd_config
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config

echo "Change boot timeout to 1 second..."
cp /boot/grub/grub.conf /boot/grub/grub.conf.ori
sed -i -e "s/timeout=5/timeout=1/" /boot/grub/grub.conf

# clean up redhat interface persistence
echo "Clean up udev rules:"
ls -l /etc/udev/rules.d/70*
rm -f /etc/udev/rules.d/70*

for ndev in $(ls /etc/sysconfig/network-scripts/ifcfg-*); do
	if [ "$(basename ${ndev})" != "ifcfg-lo" ]; then
		sed -i '/^HWADDR/d' ${ndev}
		sed -i '/^UUID/d' ${ndev}
	fi
done

echo "list devices:"
ls -l /etc/sysconfig/network-scripts/

echo "Performing VM cleanup..."
# These were only needed for building VMware/Virtualbox extensions:
yum -y remove gcc cpp kernel-devel kernel-headers perl
rm -rf VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?

yum -y clean all
rm -rf /tmp/*
rm -rf /var/tmp/*
