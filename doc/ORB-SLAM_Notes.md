# Notes on ORB-SLAM Paper
## System Overview
1. Feature Choice  
* **Same features** used by the mapping and tracking are used for 
place recognition to perform frame-rate relocalization and loop 
detection. 
* ORB: *oriented multi-scale FAST corners with a 256 bits descriptor
 associated*. Extremely fast to compute and match, while having 
**good invariance to viewpoint**.  
* To obtain general place recognition capabilities, we require 
rotation invariance, which excludes BRIEF and LDB. 
2. Three Threads: Tracking, Local Mapping and Loop Closing
## Map Initialization

## Tracking

## Local Mapping

## Loop Closing

