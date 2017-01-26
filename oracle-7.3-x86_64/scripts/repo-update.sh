#!/bin/bash

echo "Installing EPEL repository..."
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

echo "Performing system update..."
yum -y update
yum -y clean all 
reboot
sleep 60

#
# NOTE: there should be no more commands after the reboot otherwise Packer will just fail
#       (and that's why we have 2 separate scripts as suggested in https://github.com/mitchellh/packer/issues/1029)
# 
