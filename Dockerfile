# This is a sample Dockerfile you can modify to deploy your own app based on face_recognition
# docker build -t jmcausing1/vfd .
#docker image push jmcausing1/vfd
#docker run -ti --entrypoint=/bin/bash -v /dev/video0:/dev/video0 313fd63b1c86
# opencv-python install https://pythops.com/post/compile-deeplearning-libraries-for-jetson-nano

FROM arm32v7/python:3.7-slim-buster

RUN apt-get -y update

RUN apt-get install -y --fix-missing \
    build-essential \
    cmake \
    gfortran \
    git \
    wget \
    curl \
    graphicsmagick \
    libgraphicsmagick1-dev \
    libatlas-base-dev \
    libavcodec-dev \
    libavformat-dev \
    libgtk2.0-dev \
    libjpeg-dev \
    liblapack-dev \
    libswscale-dev \
    pkg-config \
    python3-dev \
    python3-numpy \
    software-properties-common \
    zip \
    libssl-dev \
    && apt-get clean && rm -rf /tmp/* /var/tmp/*

# RUN pip3 install cmake -vv

RUN pip3 install dlib -vv

RUN pip3 install face_recognition -vv 

RUN pip3 install cmake -vv 

RUN pip3 install opencv-python-headless -vv

RUN cd ~ && \
    mkdir -p vfd && \
    git clone https://github.com/jmcausing/video_face_detect vfd/ && \
    cd  vfd/

CMD tail -f /dev/null