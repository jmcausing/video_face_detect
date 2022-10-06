# Python script that detects unknown face and send alerts
You can install this on a small/mini device like Orange Pi or Raspberry pi and put it to your front door or gate.


# Setup:
For windows, download and install `cmake` first https://cmake.org/download/

# Orange Pi instructions:
wget https://raw.githubusercontent.com/jmcausing/video_face_detect/main/setup.sh

/bin/bash /setup.sh



## Create virtual env
python3 -m venv `your_venv_folder`
cd your_venv_folder
# Active venv
.\Scripts\Activate.ps1 
# Install required libraries from requirements.txt
pip3 install -r requirements.txt

Add images:
Just add your known face image files in `known_faces_images` folder and enter the image file names from the variable `self.target_file`
self.target_file = ['elisa.png','elon.jpg','roselle.png']

# To run: 
python .\video_face_scan_alert.py

# Example screenshots:
![image](https://user-images.githubusercontent.com/10601417/192078778-3de45591-6623-40be-8da0-09893618cd4f.png)
![image](https://user-images.githubusercontent.com/10601417/193448954-c2fe8753-6803-4b58-878b-f22ffb013d49.png)
![image](https://user-images.githubusercontent.com/10601417/193448932-5165ce96-7f1f-4566-926a-1bfbaf9a616b.png)
