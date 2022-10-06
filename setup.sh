#!/bin/bash
TARGET_DIR='/opt/video_face_detect'
echo "## Video Face Detection"
echo "# Author: John Mark Causing - Oct 6, 2022"
echo "# Starting setup..."
echo "#"
# Steps to setup video_face_detect.py in  Orange Pi One Armbian 5.15.63-sunxi
# Update repo and upgrade packages
echo "## Apt update and upgrade..."
echo "#"
sudo apt-get update -qq -y && sudo apt-get upgrade -qq -y

# Increase Swap
echo "## Setting up swap file..."
echo "#"
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=4K count=850 
#sudo dd if=/dev/zero of=/swapfile bs=4K count=704850 
sudo mkswap /swapfile``
sudo swapon /swapfile

echo "## Installing required packages.."
echo "#"
# Install required packages
sudo apt-get install -qq -y build-essential cmake gfortran git wget curl graphicsmagick cd libgraphicsmagick1-dev libavcodec-dev libavformat-dev libboost-all-dev libgtk2.0-dev libjpeg-dev liblapack-dev libswscale-dev pkg-config python3-dev python3-numpy python3-pip zip libopenblas-dev
sudo apt-get clean -y

echo "## Installing required packages.."
echo "#"

### Check if a directory does not exist ###
if [ -d "$TARGET_DIR" ] 
then
    echo "Directory $TARGET_DIR exists. Removing.." 
    rm -rf $TARGET_DIR
    git clone https://github.com/jmcausing/video_face_detect.git $TARGET_DIR
else
    git clone https://github.com/jmcausing/video_face_detect.git $TARGET_DIR
fi

# Upgrade pip and install pip requirementts
echo "## Installing required packages.."
echo "#"
mkdir $HOME/tmp
pip3 install --upgrade pip
TMPDIR=~/tmp pip3 install -r $TARGET_DIR/requirements.txt -vv 

