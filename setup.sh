#!/bin/bash
TARGET_DIR='/opt/video_face_detect'
echo "## Video Face Detection"
echo "# Author: John Mark Causing - Oct 6, 2022"
echo "# Starting setup..."
echo "#"
# Slack API token
read -p "Enter Slack API Token: " slack_token
# Gmail App passwd
read -p "Enter Gmail APP password:  " gmail_passwd
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
sudo apt-get install -qq -y build-essential cmake gfortran git wget curl graphicsmagick libgraphicsmagick1-dev libavcodec-dev libavformat-dev libboost-all-dev libgtk2.0-dev libjpeg-dev liblapack-dev libswscale-dev pkg-config python3-dev python3-numpy python3-pip zip libopenblas-dev
sudo apt-get clean -y

echo "## Installing PIP packages.."
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
TMPDIR=~/tmp pip3 install -r $TARGET_DIR/requirements.txt

# Setting up systemd for python script
SERVICE_NAME="video_face_detect"
PKG_PATH="/usr/bin/python3"
SERVICE_PATH="/opt/video_face_detect/orangepi_video_face_scan_alert.py"
echo "## Setting up systemd for python script.."
echo "#"
IS_ACTIVE=$(sudo systemctl is-active $SERVICE_NAME)
if [ "$IS_ACTIVE" == "active" ]; then
    # restart the service
    echo "Service is running"
    echo "Restarting service"
    sudo systemctl restart $SERVICE_NAME
    echo "Service restarted"
else
    # create service file
    echo "Creating service file"
    sudo cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Video face detection alert
After=network.target
[Service]
ExecStart=$PKG_PATH $SERVICE_PATH
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo cp /tmp/${SERVICE_NAME}.service /etc/systemd/system/${SERVICE_NAME}.service
    # restart daemon, enable and start service
    echo "Reloading daemon and enabling service"
    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME//'.service'/} # remove the extension
    sudo systemctl start ${SERVICE_NAME//'.service'/}
    echo "Service Started"
fi

exit 0

sed 's/replace_slack_token/replace_slack_tokenxxxxxxx/g' /opt/video_face_detect/orangepi_video_face_scan_alert