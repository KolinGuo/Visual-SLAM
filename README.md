# Visual-SLAM
EEC 193AB Independent Senior Design Project 2018-2019 @ UC-Davis

## Group Members 
  * Kolin Guo
  * Jeff Lai
  * Wenda Xu
  
## Teaching Assistants
  * Teja Aluru
  * Adam Jones
  * Minh Truong
  
## Instructions on Setting up This Repository
### Prerequisites
The list of prerequisites for building and running this repository is described below. 
* GNU/Linux x86_64 with kernel version > 3.10
* Docker >= 1.12
* NVIDIA GPU with Architecture > Fermi (2.1)
* NVIDIA drivers >= 418.39  
(Required for CUDA 10.1.105, can change Dockerfile base image to downgrade CUDA version if NVIDIA driver doesn't satisfy. Driver version required for different CUDA versions can be found in [Table 1](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html). Other base images can be found [here](https://hub.docker.com/r/nvidia/cudagl))
* [nvidia-docker2](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0))

### Setup Instructions
The setup process is separated into two shell scripts: `setup.sh` and `build.sh`. Both have some command-line arguments that you can specify to config them. See the printed out usage for details.   
`setup.sh` might take *more than an hour* to finish depending on your CPU power and network environment. Please be patient and **wait until it finishes completely**. 
1. Setup Docker Environment.  
`./setup.sh`  
If you need `sudo` permission to run `nvidia-docker`, run `sudo -i` before running *setup.sh*.  
You should be greeted by the Docker container **orbslam2py** when this script finishes. The working directory is */root* and the repo is mounted at */root/Visual-SLAM*.  

2. Build the C++11 and Python ORBSLAM2 Implementation.  
`cd /root/Visual-SLAM && ./build.sh`  
This script should be running in a Docker container to gain access to dependencies.  
Instructions on how to run C++11 and Python implementation will be printed when this script finishes. 


## Notes
  * The testing/benchmarking environment of the original ORB_SLAM2 C++ implementation is the **Benchmark** branch. We avoid benchmarking in the **master** branch to keep it tidy. All benchmark results will be summarized and uploaded to **master** branch. 
