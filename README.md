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
  
## Instructions on Setting up This Repository for Nvidia Jetson TX2
### Prerequisites
The list of prerequisites for building and running this repository is described below. 
* Ubuntu ARMv8 >= 16.04
* Docker >= 1.12
* CUDA Driver > 9.0
* [Tegra-Docker (tx2-docker)](https://github.com/Technica-Corporation/Tegra-Docker)

### Setup Instructions
The setup process is separated into two shell scripts: `setup.sh` and `build.sh`. Both have some command-line arguments that you can specify to config them. See the printed out usage for details.   
`setup.sh` might take *more than an hour* to finish depending on your CPU power and network environment. Please be patient and **wait until it finishes completely**. 
1. Setup Docker Environment.  
`bash ./setup.sh`  
If you need `sudo` permission to run `nvidia-docker`, run `sudo -s` before running *setup.sh*.  
You should be greeted by the Docker container **orbslam2py** when this script finishes. The working directory is */root* and the repo is mounted at */root/Visual-SLAM*.  

2. Build the C++11 and Python ORBSLAM2 Implementation.  
`cd /root/Visual-SLAM && bash -i ./build.sh && source ~/.bashrc`  
This script should be running in a Docker container to gain access to dependencies. It needs to be run interactively with `-i` option so that it can do `source ~/.bashrc`.  
Instructions on how to run C++11 and Python implementation will be printed when this script finishes.  
If failed to open X display, run `xhost +` on local computer. 


## Notes
  * The testing/benchmarking environment of the original ORB_SLAM2 C++ implementation is the **Benchmark** branch. We avoid benchmarking in the **master** branch to keep it tidy. All benchmark results will be summarized and uploaded to **master** branch. 
