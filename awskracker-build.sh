#!/bin/sh

if [ -x /var/lib/dpkg/lock-frontend ]; then
    echo "dpkg running come back in a few mins"
    exit 255
fi

if [ ! -e ~/.updated ]; then 
    sudo apt update
    sudo apt -y upgrade
    sudo apt -y install clinfo unzip p7zip-full
    sudo apt -y install build-essential linux-headers-$(uname -r) # Optional
    sudo apt-get install -yq python3-pip
    sudo -H pip3 install psutil
    touch ~/.updated

    echo "Please reboot Server"
    exit 1
fi 

rm ~/.updated

echo "Downloading hashcat"
wget https://hashcat.net/files/hashcat-5.1.0.7z
7z x hashcat-5.1.0.7z

echo "Downloading Work lists"
mkdir ~/wordlists
git clone https://github.com/danielmiessler/SecLists.git ~/wordlists/seclists
wget -nH http://downloads.skullsecurity.org/passwords/rockyou.txt.bz2 -O ~/wordlists/rockyou.txt.bz2
cd ~/wordlists
bunzip2 ./rockyou.txt.bz2

echo "Cleaning up Home Dir"
cd ~
mkdir ARCHIVE
mv awscracker-build.sh hashcat-5.1.0.7z Nvidia_Cloud_EULA.pdf README ARCHIVE/
