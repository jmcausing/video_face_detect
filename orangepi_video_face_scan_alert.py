import face_recognition
import cv2
import numpy as np
from datetime import datetime
import os, logging, sys
import atexit
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import platform
import socket   
import smtplib
import mimetypes
from email.message import EmailMessage
import math

class Video_face_scan:
    """
    Video Face detection that alerts if it detects an unknown face/intruder 
    """

    def __init__(self):
        # Setup default variables
        self.py_script_path = os.path.dirname(os.path.realpath(__file__))
        # Get IP and hostname
        self.hostname=socket.gethostname()   
        self.IPAddr=socket.gethostbyname(self.hostname)   
        # Slack
        self.slack_channel = '#video_face_detect'
        self.slack_token = 'replace_slack_token'
        # Gmail Setup
        self.sender = "replace_gmail_email"
        self.recipient = "replace_gmail_email"        
        self.mail_server_user = 'replace_gmail_email'
        self.mail_server_pass = 'replace_gmail_pass' # Google App Password for Gmail only - https://support.google.com/accounts/answer/185833?visit_id=637989785843231280-2031701535&p=InvalidSecondFactor&rd=1
        self.email_subject = 'Intruder alert! Detected unknown face!'
        # Face recognition tolerance and accuracy values
        self.tolerance_compare = 0.5
        self.tolerance_accuracy = 0.5


    def setup(self):
        print('# Setting up variables and other requirements..')
        # Image folder and files location for known friendly faces.
        self.target_file = []
        self.target_file_dir = f'{self.py_script_path}/known_faces_images' # or specific path '/mnt/c/Users/JMC/python/face/images'  
        # Folder of unknown/intruder face so we can store images there.
        self.unknown_faces_dir = 'unknown_faces'    
        # Check and create if self..unknown_faces_dir does not exist
        if not os.path.isdir(self.unknown_faces_dir):
            try:
                os.mkdir(self.unknown_faces_dir)
            except OSError as e:
                logging.error(f"Couldn't create log folder: {e!r}\nShutting down.")
                return f'{e!r}'
        # Check and create if self.target_file_dir does not exist
        if not os.path.isdir(self.target_file_dir):
            try:
                os.mkdir(self.target_file_dir)
            except OSError as e:
                logging.error(f"Couldn't create log folder: {e!r}\nShutting down.")
                return f'{e!r}'
        # Check if folder self.target_file_dir is empty
        py_script_path = os.path.dirname(os.path.realpath(__file__))
        if len(os.listdir(self.target_file_dir)) == 0:
            self.alert_and_shutdown(exitCode=1, msg=f'Shutting down! setup() - {self.target_file_dir} folder (elf.target_file_dir) is empty!')
        # If it reeached here, then self.target_file_dir is not empty and we'll appending files.
        # Append image files from self.target_file_dir self.target_file
        for file in os.listdir(self.target_file_dir):
            self.target_file.append(file)
        print(f'# These are the files of our known/friendly faces: {self.target_file}')
        # We use this to process every other frame of video to save time
        self.process_this_frame = True
        ## Log settings
        self.log_path = f'{self.py_script_path}/logs/vfs.log'
        self.log_level = logging.INFO  ## possible values: DEBUG, INFO, WARNING, ERROR, CRITICAL
        self.log_format = '%(asctime)s - [%(levelname)s]: %(message)s'
        self.log_date_format = '%Y-%m-%d %H:%M:%S'

        ## Set up logging
        ls = self.logSetup(self.log_path, self.log_level, self.log_format, self.log_date_format)
        if ls != True:
            self.alert_and_shutdown(exitCode=1, msg='Setup() - Error setting up logs')
        print('# Setup finished!')
        print('#')

        # Checking if webcam exist..
        print('# Searching for camera..')
        for cam in range(-2,10):
            try:
                # For debug
                # print(f'# Trying camera {cam}..')
                video_capture = cv2.VideoCapture(cam)
                frame_test = video_capture.read()
                if 'True' in str(frame_test):
                    print(f'# Found camera index: {cam}')
                    self.camera = cam
                    video_capture.release()
                    break
            except Exception as e:
                    print(e)
        if 'False' in str(frame_test):
            # print('# Webcam not found!')   
            self.alert_and_shutdown(exitCode=1, msg='Setup() - Camera not found! Shutting down!')
        # Setup known face encoding
        print('# Start encoding known faces..')
        self.known_face_encodings = []         
        self.encode_known_faces()


    def encode_known_faces(self):
        # Load and encode all images from the list self.target_file (The known faces)
        for image in self.target_file:
            logging.info(f"# encode_known_faces() - Encoding image {image}")
            print(f"# Encoding image {image}")
            load_image = face_recognition.load_image_file(f"{self.target_file_dir}/{image}")
            self.known_face_encodings.append(face_recognition.face_encodings(load_image))      

    # Shutdown exit function
    def alert_and_shutdown(self, msg=None, exitCode=0):
        # This helps for shutting down the process and alerting if needed.
        if msg is None:
            sys.exit(exitCode)
        else:
            # Send slack!!!
            print(f'# Shutting down! Error: {msg}')
            logging.info(f'alert_and_shutdown() - {msg}')
            self.send_slack(msg)
            sys.exit(exitCode)

    # Gmail send function
    def send_gmail(self,file,msg_subject,msg_body):
        # Make sure to enable Google Password App for gmail
        # https://support.google.com/accounts/answer/185833?visit_id=637989785843231280-2031701535&p=InvalidSecondFactor&rd=1
        message = EmailMessage()
        message['From'] = self.sender
        message['To'] = self.recipient
        message['Subject'] = msg_subject
        full_path_attachment = f'{self.unknown_faces_dir}/{file}'
        body = msg_body
        message.set_content(body)
        mime_type, _ = mimetypes.guess_type(full_path_attachment)
        mime_type, mime_subtype = mime_type.split('/')
        with open(full_path_attachment, 'rb') as file:
            message.add_attachment(file.read(),
            maintype=mime_type,
            subtype=mime_subtype)
            #filename='09-17-2022--11-00-44-AM.png')
        mail_server = smtplib.SMTP_SSL('smtp.gmail.com')
        mail_server.set_debuglevel(0)
        mail_server.login(f"{self.mail_server_user}", f'{self.mail_server_pass}')
        mail_server.send_message(message)
        mail_server.quit()

    # Slack send function
    def send_slack(self,message,attachment=None):
        client = client = WebClient(token=self.slack_token)
        # Send slack with attachment like intruder/unknown face alert
        if attachment:
            # Upload image to JMC slack channel '#video_face_detect'
            image = client.files_upload(
                channel = self.slack_channel,
                initial_comment = "This is my image",
                file = f"{self.unknown_faces_dir}/{attachment}"
            )
            # Compose slack message with file url
            file_url = image["file"]["permalink"]
            text = f"{message} {file_url}"
            # Try to send message with image
            try:
                result = client.chat_postMessage(
                    channel = self.slack_channel,
                    text = text
                )
            except SlackApiError as e:
                print(f"Error: {e}")  
        # If no attachment like slack alert logging
        else:
            vm_hostname = platform.node()
            vm_os = platform.system()
            message = f"VM:{vm_hostname} - Hostname:{vm_os} - IP: {self.IPAddr}\n{message}"
            try:
                response = client.chat_postMessage(channel=self.slack_channel, text=message)
                return True
            except SlackApiError as e:
                # You will get a SlackApiError if "ok" is False
                assert e.response["ok"] is False
                assert e.response["error"]  # str like 'invalid_auth', 'channel_not_found'
                logging.warning(f"Got an error when trying to send Slack message: {e.response['error']}")
                return False

    # Setup logging
    def logSetup(self, log_path, log_level, log_format, log_date_format):
        # Setting up log facility
        target_dir = f'{self.py_script_path}/logs'
        if not os.path.isdir(target_dir):
            try:
                os.mkdir(target_dir)
            except OSError as e:
                logging.error(f"Couldn't create log folder: {e!r}\nShutting down.")
                return f'{e!r}'
        try:
            logging.basicConfig(filename=log_path, level=log_level, format=log_format, datefmt=log_date_format)
        except Exception as e:
            return f'{e!r}'
        else:
            logging.info('Logging setup complete')
            return True

    # Calculate accuracy from facedistance results (face distance of target face and other faces)
    def face_distance_to_conf(self,face_distance,face_match_threshold):
        if face_distance > face_match_threshold:
            range = (1.0 - face_match_threshold)
            linear_val = (1.0 - face_distance) / (range * 2.0)
            return linear_val
        else:
            range = face_match_threshold
            linear_val = 1.0 - (face_distance / (range * 2.0))
            return linear_val + ((1.0 - linear_val) * math.pow((linear_val - 0.5) * 2, 0.2))

    # Compare unknown face to known faces
    def compare_face(self,face_encodings):
        accuracy_percentage = ''
        match = []
        # Loop each known faces encoding (the encoding per known faces image file)    
        for index,known_face_encoding in enumerate(self.known_face_encodings):
            # For debug
            # print(f"## Checking known face encoding of: {self.target_file[index]} ")
            #Start comparing faces
            for face_encoding in face_encodings:
                # See if the face is a match for the known face(s)
                is_match = face_recognition.compare_faces(known_face_encoding, face_encoding, self.tolerance_compare)[0]
                if is_match:
                    print(f"# Current face matched from the known face: {self.target_file[index]}")
                    # Check accuracy for the face matched. No need to get accuracy for non-matched face
                    face_distance = face_recognition.face_distance(known_face_encoding,face_encoding)
                    accuracy = self.face_distance_to_conf(face_distance, 0.5)
                    accuracy_percentage = "{:.0%}".format(float(accuracy)) # Convert to percentage
                    # print(f'Accuracy: {accuracy_percentage}') # For debug
                    # Append match value (True)
                    match.append(is_match)
                else:
                    # Check accuracy for the face matched.
                    match.append(is_match)
        # Append accuracy value
        match.append(accuracy_percentage)
        # This returns True or False in a list. If you have two target file and it doesn't match, it returns: [False, False]
        # If it matches one of the target file (from known faces), then it returns: [False, True] or [True, False]
        return match

    # Function to start detecting faces
    def video_detect_start(self):
        # Get time and date
        now = datetime.now()        
        logging.info('video_detect_start() - Start')
        # Start video capture from webcam
        video_capture = cv2.VideoCapture(self.camera)
        # Infinite loop video frame capture starts here
        while True:
            # Grab a single frame of video
            ret, frame = video_capture.read()
            # Only process every other frame of video to save time
            if self.process_this_frame:
                # Resize frame of video to 1/4 size for faster face recognition processing
                small_frame = cv2.resize(frame, (0, 0), fx=0.25, fy=0.25)
                # Convert the image from BGR color (which OpenCV uses) to RGB color (which face_recognition uses)
                # This doesn't work for Orange Pi so we use `small_frame` in face_encodings() instead
                rgb_small_frame = small_frame[:, :, ::-1]
                # Get face location from current video frame
                face_locations = face_recognition.face_locations(small_frame)
                # If face found from current video frame, encode it!          
                if bool(face_locations):
                    # Get time and date so we can log it!
                    now = datetime.now()
                    current_time = now.strftime("%m-%d-%Y--%I-%M-%S-%p")
                    print(f"# Face detected at {current_time}")
                    # This is currently working for orange pigit
                    face_encodings = face_recognition.face_encodings(rgb_small_frame, face_locations)
                    # Not working for orange pi
                    # face_encodings = face_recognition.face_encodings(rgb_small_frame, face_locations)
                    # Run function compare_face() to compare faces from known faces (the list of image files)
                    match = self.compare_face(face_encodings)
                    # For debug
                    # print(match) # match[-1] is the percentag accuracy
                    # Intruder unknown face alert starts here
                    #
                    if True in match:
                        logging.info(f'video_detect_start() - FRIENDLY! A face was found but it\'s one of the known friendly face.  Accuracy is : {match[-1]}')
                        print(f'# FRIENDLY! A face was found but it\'s one of the known friendly face. Log it {current_time}')
                        print('#')
                    else:
                        logging.info(f'video_detect_start() - INTRUDER ALERT! An unknown face was detected. Please check the logs and unknown_faces folder.')
                        print(f'# Intruder alert! Log it and save the image - Log time: {current_time}')
                        #
                        # From here you can:
                        # - Save the current frame image
                        # - Email and TXT the house owner
                        # - Maybe a device that sounds an alarm
                        try:
                            # Log intruder
                            logging.info(f'video_detect_start() - Saving intruder/unknown face as image in {self.unknown_faces_dir} folder with slack and gmail alerts.')
                            print(f'# Saving intruder face as image in {self.unknown_faces_dir} folder..')
                            # Save intruder's face in self.unknown_faces_dir
                            intruder_file_name = f'{current_time}.png'
                            cv2.imwrite(os.path.join(self.unknown_faces_dir, '%s') % intruder_file_name, frame)
                            # Send slack alert with intruder's image
                            print(f'# Sending to slack!')
                            msg = f'Intruder alert! Unknown face image file name `{intruder_file_name}` is saved in `{self.unknown_faces_dir}` folder! - Time and date: `{current_time}`'
                            self.send_slack(message=":no_entry:"+msg,attachment=intruder_file_name)
                            # Send it to gmail
                            print('# Sending to gmail...')
                            email_subject = f'{self.email_subject} - {current_time}'
                            email_body = msg
                            self.send_gmail(file=intruder_file_name,msg_subject=email_subject,msg_body=email_body)
                            print('# Done with this current loop frame. Checking next frame..')
                            print('#')
                        except Exception as e:
                            print(e)      
                # For debug
                # else: 
                #    print(f'# No face found!! face_location: {face_locations}')
            self.process_this_frame = not self.process_this_frame
        # Release handle to the webcam
        video_capture.release()

    def run(self):
        print("# Starting video face detection...")
        # Setup our environment
        self.setup()
        # Run the main function video_detect_start()    
        start = self.video_detect_start()    
        return start
        
def detect_exit():
    logging.info(f'detect_exit() - Script was shutdown/interrupted')

def main(request): # 
    # Detect and log if the script was shutdown/exit
    atexit.register(detect_exit)
    check = Video_face_scan()
    return check.run()

if __name__ == "__main__": 
    try:
        main(None)
    except Exception as e:
        print(e)
