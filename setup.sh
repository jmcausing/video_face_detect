#!/bin/bash
TARGET_DIR='/opt/video_face_detect'
echo "## Video Face Detection"
echo "# Author: John Mark Causing - Oct 6, 2022"
echo "# Starting setup..."
echo "#"
echo "# Credentials setup:"
# Slack API token
read -p "Enter Slack API Token: " slack_token
# Gmail App email and passwd
read -p "Enter Gmail email address:  " gmail_email
read -p "Enter Gmail APP password:  " gmail_passwd
echo "#"
echo "# Folder known faces setup"
read -p "What is the Google Drive folder of the known faces images?  " gdrive_known_faces_folder
read -p "Enter the Google drive folder (Make sure this is set to PUBLIC access. Example: https://drive.google.com/drive/u/0/folders/14aEtI9n-88ynKPiOvdn5IBAv-knN_DMQ : " gdrive_folder



# Steps to setup video_face_detect.py in  Orange Pi One Armbian 5.15.63-sunxi
# Update repo and upgrade packages
echo "## Apt update and upgrade..."
echo "#"
sudo apt-get update -qq -y && sudo apt-get upgrade -qq -y

# Increase Swap
echo "## Setting up swap file..."
echo "#"
sudo swapoff -a
#sudo dd if=/dev/zero of=/swapfile bs=4K count=850 # Small swap for testing
sudo dd if=/dev/zero of=/swapfile bs=4K count=704850 
sudo mkswap /swapfile``
sudo swapon /swapfile

echo "## Installing required packages.."
echo "#"
# Install required packages
sudo apt-get install -qq -y build-essential cmake gfortran git wget curl graphicsmagick libgraphicsmagick1-dev libavcodec-dev libavformat-dev libboost-all-dev libgtk2.0-dev libjpeg-dev liblapack-dev libswscale-dev pkg-config python3-dev python3-numpy python3-pip zip libopenblas-dev
sudo apt-get clean -y

echo "## Downloading video_face_detect repo.."
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

# Replace gmail pass, email, slack token and folder variables..
echo "## Setting up Gmail,Slack credentials and folders.."
echo "#"
sed -i "s/replace_slack_token/$slack_token/g" $TARGET_DIR/orangepi_video_face_scan_alert.py
sed -i "s/replace_gmail_pass/$gmail_passwd/g" $TARGET_DIR/orangepi_video_face_scan_alert.py
sed -i "s/replace_gmail_email/$gmail_email/g" $TARGET_DIR/orangepi_video_face_scan_alert.py
sed -i "s/known_faces_images/$gdrive_known_faces_folder/g" $TARGET_DIR/orangepi_video_face_scan_alert.py

# Downloading Google drive folder of known faces images..
echo "## Downloading Google drive folder of known faces images.."
echo "#"
gdown --folder $gdrive_folder -O $TARGET_DIR/$gdrive_known_faces_folder

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
RestartSec=20
[Install]
WantedBy=multi-user.target
EOF
    # restart daemon, enable and start service
    echo "Reloading daemon and enabling service"
    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME//'.service'/} # remove the extension
    sudo systemctl start ${SERVICE_NAME//'.service'/}
    echo "Service Started"
fi

exit 0



pip install gdown
https://drive.google.com/drive/u/0/folders/14aEtI9n-88ynKPiOvdn5IBAv-knN_DMQ