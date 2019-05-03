#!/bin/bash 
# Ensure that you have installed nvidia-docker and the latest nvidia graphics driver on host!

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
USAGE="Usage: ./setup.sh [rm=[0,1]]\n"
USAGE+="\trm=[0,1] : 0 to remove intermediate Docker images after a successul build and 1 otherwise\n"
USAGE+="\t           default is 0\n"

# Parsing argument
if [] ; then

fi




# Print usage
echo -e "\n$USAGE"
echo -e ".......... Set up will start in 5 seconds .........."
sleep 5




# Build and run the image
echo "Building image..."
sudo nvidia-docker build --rm=true -t orbslam2py .

echo "Removing older container..."
if [ 1 -eq $(sudo docker container ls -a | grep "orbslam2py$" | wc -l) ] ; then
	sudo nvidia-docker rm -f orbslam2py
fi

echo "Building a container from the image..."

sudo nvidia-docker create -it --name=orbslam2py \
	-v "$SCRIPTPATH":/root/Visual-SLAM \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=$DISPLAY \
	orbslam2py /bin/bash

sudo nvidia-docker start -ai orbslam2py
