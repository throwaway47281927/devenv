docker run \
    --device /dev/nvidia0:/dev/nvidia0 \
    --device /dev/nvidiactl:/dev/nvidiactl \
    --device /dev/nvidia-uvm:/dev/nvidia-uvm \
    -it \
    -p 5901:5901 \
    -p 2222:22 \
    --privileged \
    devenv
