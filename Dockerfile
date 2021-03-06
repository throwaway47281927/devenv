FROM ubuntu:16.04

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
    apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
    echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list

ENV CUDA_VERSION 8.0.61

ENV CUDA_PKG_VERSION 8-0=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-nvrtc-$CUDA_PKG_VERSION \
        cuda-nvgraph-$CUDA_PKG_VERSION \
        cuda-cusolver-$CUDA_PKG_VERSION \
        cuda-cublas-8-0=8.0.61.2-1 \
        cuda-cufft-$CUDA_PKG_VERSION \
        cuda-curand-$CUDA_PKG_VERSION \
        cuda-cusparse-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-8.0 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=8.0"

# ---- 16.04:8:devel
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-core-$CUDA_PKG_VERSION \
        cuda-misc-headers-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        cuda-nvrtc-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-nvgraph-dev-$CUDA_PKG_VERSION \
        cuda-cusolver-dev-$CUDA_PKG_VERSION \
        cuda-cublas-dev-8-0=8.0.61.2-1 \
        cuda-cufft-dev-$CUDA_PKG_VERSION \
        cuda-curand-dev-$CUDA_PKG_VERSION \
        cuda-cusparse-dev-$CUDA_PKG_VERSION \
        cuda-npp-dev-$CUDA_PKG_VERSION \
        cuda-cudart-dev-$CUDA_PKG_VERSION \
        cuda-driver-dev-$CUDA_PKG_VERSION && \
    rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs:${LIBRARY_PATH}

# --------- 16.04:8:devel:cudnn5

RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDNN_VERSION 5.1.10
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn5=$CUDNN_VERSION-1+cuda8.0 \
            libcudnn5-dev=$CUDNN_VERSION-1+cuda8.0 && \
    rm -rf /var/lib/apt/lists/*

RUN echo "keyboard-configuration	keyboard-configuration/unsupported_config_layout	boolean	true" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/unsupported_config_layout	boolean	true" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/xkb-keymap	select	" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/unsupported_config_options	boolean	true" | debconf-set-selections && \
    echo "keyboard-configuration	console-setup/detected	note	" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/unsupported_options	boolean	true" | debconf-set-selections && \
    echo "keyboard-configuration	console-setup/ask_detect	boolean	false" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/optionscode	string	" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/variant	select	English (US)" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/switch	select	No temporary switch" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/ctrl_alt_bksp	boolean	false" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/toggle	select	No toggling" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/altgr	select	The default for the keyboard layout" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/model	select	Generic 105-key (Intl) PC" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/layout	select	English (US)" | debconf-set-selections && \
    echo "keyboard-configuration	console-setup/detect	detect-keyboard	" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/compose	select	No compose key" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/modelcode	string	pc105" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/variantcode	string	" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/layoutcode	string	us" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/store_defaults_in_debconf_db	boolean	true" | debconf-set-selections && \
    echo "keyboard-configuration	keyboard-configuration/unsupported_layout	boolean	true" | debconf-set-selections

ENV DEBIAN_FRONTEND="noninteractive dpkg-reconfigure keyboard-configuration"

## create non-root user
RUN apt-get update && apt-get upgrade -y && apt-get install -y sudo
RUN useradd -ms /bin/bash ubuntu && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu
USER ubuntu
WORKDIR /home/ubuntu

# tor
RUN sudo apt-get install -y apt-transport-https && \
    echo "deb https://deb.torproject.org/torproject.org xenial main" | sudo tee --append /etc/apt/sources.list && \
    echo "deb-src https://deb.torproject.org/torproject.org xenial main" | sudo tee --append /etc/apt/sources.list && \
    sudo gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 && \
    sudo gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add - && \
    sudo apt-get update && \
    sudo apt-get install -y tor deb.torproject.org-keyring

RUN sudo service tor start && \
    sudo apt-get install -y curl git && \
    curl -s --socks5-hostname localhost:9050 https://check.torproject.org/api/ip && \
    git config --global http.proxy 'socks5://127.0.0.1:9050' && \
    git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name" && \
    git clone https://github.com/throwaway47281927/clothed2nude.git && \
    git clone https://github.com/throwaway47281927/devenv.git && \
    git clone https://github.com/throwaway47281927/Mask_RCNN.git

# ----- open pose
RUN sudo apt-get install -y wget unzip lsof apt-utils lsb-core git libatlas-base-dev libopencv-dev python-opencv python-pip   

RUN sudo service tor start && \
    git clone --recursive https://github.com/throwaway47281927/openpose.git

RUN cd openpose && \
    sed -i 's/\<sudo chmod +x $1\>//g' ubuntu/install_caffe_and_openpose_if_cuda8.sh; \
    sed -i 's/\<sudo chmod +x $1\>//g' ubuntu/install_openpose_if_cuda8.sh; \
    sed -i 's/\<sudo -H\>//g' 3rdparty/caffe/install_caffe_if_cuda8.sh; \
    sed -i 's/\<sudo\>//g' 3rdparty/caffe/install_caffe_if_cuda8.sh; \
    sync; sleep 1; sudo ./ubuntu/install_caffe_and_openpose_if_cuda8.sh

RUN sudo apt-get install -y vim wget net-tools locales bzip2 python-numpy
RUN sudo locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install xvnc-server
RUN wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C . && \
    sudo cp -R usr/ /

### Install xfce UI
RUN sudo apt-get install -y supervisor xfce4 xfce4-terminal && \
    sudo apt-get purge -y pm-utils xscreensaver* && \
    sudo apt-get clean -y

### configure startup
RUN sudo apt-get install -y libnss-wrapper gettext software-properties-common python-software-properties

RUN wget https://www.torproject.org/dist/torbrowser/7.5.3/tor-browser-linux64-7.5.3_en-US.tar.xz
RUN ls -l && \
    tar -xvJf tor-browser-linux64-7.5.3_en-US.tar.xz
RUN sudo apt-get install -y iptables
RUN mkdir -p ~/.local/share/applications/ && \
    printf "[Desktop Entry]\nName=Tor Browser\nExec=/home/ubuntu/tor-browser_en-US/Browser/start-tor-browser\nIcon=tigervnc\nTerminal=false\nType=Application\nCategories=Network;RemoteAccess;\n" > ~/.local/share/applications/tor.desktop

RUN sudo apt-get install -y curl iptables dnsutils

RUN wget https://download.jetbrains.com/cpp/CLion-2018.1.2.tar.gz
RUN wget https://download.jetbrains.com/python/pycharm-professional-2018.1.2.tar.gz
RUN tar -xvf CLion-2018.1.2.tar.gz && \
    tar -xvf pycharm-professional-2018.1.2.tar.gz
RUN printf "[Desktop Entry]\nName=CLion\nExec=/home/ubuntu/clion-2018.1.2/bin/clion.sh\nIcon=tigervnc\nTerminal=false\nType=Application\nCategories=Network;RemoteAccess;\n" > ~/.local/share/applications/clion.desktop && \
    printf "[Desktop Entry]\nName=PyCharm\nExec=/home/ubuntu/pycharm-2018.1.2/bin/pycharm.sh\nIcon=tigervnc\nTerminal=false\nType=Application\nCategories=Network;RemoteAccess;\n" > ~/.local/share/applications/pycharm.desktop

ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false
EXPOSE $VNC_PORT

RUN sudo apt-get install -y cmake && \
    sudo chown -R ubuntu:root ~/openpose && \
    cd openpose/build && \
    cmake .. && \
    make -j`nproc`

RUN sudo apt-get install -y openssh-server && \
    sudo sh -c 'echo "ubuntu:vncpassword" | chpasswd'
EXPOSE 22

RUN sudo apt-get install -y imagemagick python3 python3-pip python3-dev nano
RUN pip3 install tensorflow-gpu numpy scipy pillow

# CUDA 9
ENV CUDA_VERSION 9.0.176
ENV CUDA_PKG_VERSION 9-0=$CUDA_VERSION-1

RUN sudo apt-get install -y ca-certificates apt-transport-https gnupg-curl

RUN sudo apt-get install -y cuda-cudart-$CUDA_PKG_VERSION

#RUN sudo ln -s cuda-9.0 /usr/local/cuda

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" | sudo tee --append /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" | sudo tee --append /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.0"

ENV CUDNN_VERSION 7.1.2.21
ENV NCCL_VERSION 2.1.15

RUN sudo apt-get install -y cuda-libraries-$CUDA_PKG_VERSION \
        libnccl2=$NCCL_VERSION-1+cuda9.0

RUN sudo apt-get install -y cuda-libraries-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-minimal-build-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        libnccl-dev=$NCCL_VERSION-1+cuda9.0

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs:${LIBRARY_PATH}

RUN sudo apt-get install -y libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
    libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 

# clone
RUN pip3 install PySocks
RUN pip install PySocks beautifulsoup4

RUN sudo add-apt-repository ppa:graphics-drivers/ppa && \
    sudo apt-get update && \
    sudo apt-get install -y jq nvidia-390

RUN sudo apt-get install -y exif

RUN sudo service tor start && \
    cd clothed2nude && \
    git pull && \
    python download.py && \
    tar -xvf dataset.tar.gz && \
    mkdir -p datasets && \
    mv blended/ datasets/ && \
    python download_original.py && \
    tar -xvf original.tar.gz

RUN sudo service tor start && \
    sudo chown -R root:ubuntu /usr/local/ && \
    sudo chmod -R ug+rw /usr/local && \
    pip install Cython && \
    git clone https://github.com/waleedka/coco && \
    cd ~/coco && \
    echo "installing coco" && \
    cd ~/coco/PythonAPI && \
    make && \
    echo "setup coco" && \
    python setup.py build_ext install

RUN sudo service tor start && \
    mv ~/clothed2nude/raw ~/Mask_RCNN/dataset && \
    mkdir -p ~/Mask_RCNN/out && \
    cd ~/Mask_RCNN && \
    sudo apt-get install -y python3-tk && \
    sudo chown -R root:ubuntu /home/ubuntu/.cache/ && \
    sudo chmod -R ug+rw /home/ubuntu/.cache/ && \
    pip install --upgrade pip==9.0.1 && \
    pip3 install --upgrade pip==9.0.1 && \
    pip install setuptools --upgrade && \
    pip3 install setuptools --upgrade && \
    sudo pip3 install -r requirements.txt && \
    sudo python3 setup.py install

RUN sudo pip install scikit-image tensorflow tensorflow-gpu && \
    sudo pip3 install pycocotools && \
    sudo apt-get install -y python-tk

RUN sudo service tor start && \
    cd ~/Mask_RCNN && \
    git pull && \
    python3 download.py

# Run
ENTRYPOINT sudo service tor start && \
    sudo service ssh start && \
    echo 1 | sudo tee --append /proc/sys/net/ipv4/ip_forward && \
    sudo iptables -F OUTPUT && \
    sudo iptables -A INPUT -i eth0 -s 192.168.0.0/16 -j ACCEPT && \
    sudo iptables -A INPUT -p tcp --dport 5901 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT && \
    sudo iptables -A OUTPUT -p tcp --sport 5901 -m conntrack --ctstate ESTABLISHED -j ACCEPT && \
    sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT && \
    sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT && \
    sudo iptables -A INPUT -p udp --source-port 53 -j ACCEPT && \
    sudo iptables -A OUTPUT -p udp --destination-port 53 -j ACCEPT && \
    sudo iptables -P FORWARD ACCEPT && \
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE && \
    sudo iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 9050 && \
    sudo iptables -t nat -A PREROUTING -p tcp --destination-port 443 -j REDIRECT --to-port 9050 && \
    sudo iptables -A OUTPUT -j ACCEPT -m owner --uid-owner debian-tor && \
    sudo iptables -A OUTPUT -j ACCEPT -o lo && \
    sudo iptables -P OUTPUT DROP && \
    sudo iptables -L -v && \
    VNC_IP=$(hostname -i) && \
    mkdir -p "/home/ubuntu/.vnc" && \
    PASSWD_PATH="/home/ubuntu/.vnc/passwd" && \
    echo "$VNC_PW" | vncpasswd -f >> $PASSWD_PATH && \
    chmod 600 $PASSWD_PATH && \
    vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION && \
    xset -dpms && \
    xset s noblank && \
    xset s off && \
    xset s off && \
    /usr/bin/startxfce4

