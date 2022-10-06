FROM balenalib/armv7hf-ubuntu:bionic-build

MAINTAINER Masahiro Hiramori <mhg00g13@gmail.com>

ARG DEBIAN_FRONTEND="noninteractive"
ARG REPO_URL=https://github.com/skvark/opencv-python
ARG BRANCH=master

ENV LANG "C.UTF-8"
ENV LC_ALL "C.UTF-8"
ENV HOME /root
ENV PATH "/root/.pyenv/shims:/root/.pyenv/bin:$PATH"
ENV PYENV_ROOT $HOME/.pyenv
ENV PYTHON_VERSION 3.9.5
ENV ENABLE_CONTRIB 1

#Enforces cross-compilation through Qemu
RUN [ "cross-build-start" ]

RUN install_packages \
    sudo \
    build-essential \
    ca-certificates \
    cmake \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install pyenv
RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT \
    && echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc

# Install Python through pyenv
RUN env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION \
    && pip3 install -U pip

# Get source code
WORKDIR /code
RUN git clone --single-branch --branch ${BRANCH} --recursive ${REPO_URL}

# Build OpenCV
WORKDIR /code/opencv-python
RUN pip wheel .

RUN [ "cross-build-end" ]



# # This is a sample Dockerfile you can modify to deploy your own app based on face_recognition
# # docker build -t jmcausing1/vfd .
# #docker image push jmcausing1/vfd
# #docker run -ti --entrypoint=/bin/bash -v /dev/video0:/dev/video0 313fd63b1c86
# # opencv-python install https://pythops.com/post/compile-deeplearning-libraries-for-jetson-nano

# FROM arm32v7/ubuntu

# RUN apt-get -y update
# RUN apt-get install -y software-properties-common

# RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'

# RUN apt-get -y update

# # RUN apt-get install -y --fix-missing \
# #     build-essential \
# #     cmake \
# #     gfortran \
# #     git \
# #     wget \
# #     curl \
# #     graphicsmagick \
# #     libgraphicsmagick1-dev \
# #     libatlas-base-dev \
# #     libavcodec-dev \
# #     libavformat-dev \
# #     libgtk2.0-dev \
# #     libjpeg-dev \
# #     liblapack-dev \
# #     libswscale-dev \
# #     pkg-config \
# #     python3-dev \
# #     python3-numpy \
# #     software-properties-common \
# #     zip \
# #     libssl-dev \
# #    && apt-get clean && rm -rf /tmp/* /var/tmp/*

# # https://blog.piwheels.org/new-opencv-builds/
# RUN apt-get install -y \
#     libatlas3-base \
#     libwebp6 \
#     libtiff5 \
#     libjasper1 \
#     libilmbase12 \
#     libopenexr22 \
#     libilmbase12 \
#     libgstreamer1.0-0 \
#     libavcodec57 \
#     libavformat57 \
#     libavutil55 \
#     libswscale4 \
#     libgtk-3-0 \
#     libpangocairo-1.0-0 \
#     libpango-1.0-0 \
#     libatk1.0-0 \
#     libcairo-gobject2 \
#     libcairo2 \
#     libgdk-pixbuf2.0-0 

# # RUN pip3 install opencv-python==3.4.2.16

# # RUN pip3 install dlib -v

# # RUN pip3 install face_recognition -vv 

# # RUN pip3 install cmake -vv 

# # # RUN pip3 install opencv-python-headless -vv

# # RUN cd ~ && \
# #     mkdir -p vfd && \
# #     git clone https://github.com/jmcausing/video_face_detect vfd/ && \
# #     cd  vfd/

# CMD tail -f /dev/null