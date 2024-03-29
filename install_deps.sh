#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Update and Upgrade Ubuntu Packages
apt-get update && apt-get upgrade -y

# Install Docker
#apt-get install -y docker.io

# Add the current user to the Docker group
#usermod -aG docker $SUDO_USER

# Install necessary packages for Vagrant and VirtualBox
apt-get install -y software-properties-common
add-apt-repository -y multiverse
apt-get update

# Install VirtualBox
apt-get install -y virtualbox

# Install Vagrant
apt-get install -y vagrant

# Restart to ensure all changes take effect
echo "Setup is complete. A reboot is recommended."

# Uncomment the following line to automatically reboot
# reboot
