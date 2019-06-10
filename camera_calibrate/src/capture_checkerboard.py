import cv2
import matplotlib.pyplot as plt
import numpy as np
import sys
import os
import time

def capture_checkerboard():
    if (3 != len(sys.argv)):
        print("Usage: ./capture_checkerboard sensor_id <save/path> \n")
        sys.exit(1)

    sensor_id = int(sys.argv[1])
    save_path = sys.argv[2]
    print("Save checkerboard images to " + save_path)
    if (not os.path.exists(save_path)):
        os.makedirs(save_path)

    numPics = 20
    delaySec = 5
    width = 1920
    height = 1080
    cap = cv2.VideoCapture("nvcamerasrc sensor-id=%d ! video/x-raw(memory:NVMM), width=(int)%d, height=(int)%d, format=(string)I420, framerate=(fraction)30/1 ! nvvidconv flip-method=0 ! video/x-raw, format=(string)BGRx ! videoconvert ! video/x-raw, format=(string)BGR ! appsink" % (sensor_id, width, height), cv2.CAP_GSTREAMER)
    #cap = cv2.VideoCapture("nvcamerasrc sensor-id=%d ! video/x-raw(memory:NVMM), width=(int)%d, height=(int)%d, format=(string)I420, framerate=(fraction)30/1 ! nvvidconv flip-method=0 ! videoconvert ! appsink" % (sensor_id, width, height), cv2.CAP_GSTREAMER)
    #cap = cv2.VideoCapture("v4l2src device=/dev/video{} ! video/x-raw, width=(int){}, height=(int){} ! videoconvert ! appsink".format(sensor_id, width, height), cv2.CAP_GSTREAMER)
    #cap = cv2.VideoCapture(0, cv2.CAP_GSTREAMER)
    #cap = cv2.VideoCapture("nvcamerasrc sensor-id=%d ! video/x-raw, format=(string)I420, width=(int)%d, height=(int)%d, pixel-aspect-ratio=(fraction)1/1, interlace-mode=(string)progressive, framerate=(fraction)30/1! nvvidconv flip-method=0 ! video/x-raw, format=(string)BGRx ! videoconvert ! video/x-raw, format=(string)BGR ! appsink" % (sensor_id, width, height), cv2.CAP_GSTREAMER)

    if cap.isOpened():
        print("Camera %d open succeeded" % sensor_id)
        for i in range(numPics):
            print("Capturing #$d image in %d seconds" % (i, delaySec))
            time.sleep(delaySec)

            retval, frame = cap.read()
            if (retval == False):
                print("Failed at #%d image" % i)
                sys.exit(2)

            plt.imshow(frame)
            plt.show()
            cv2.waitKey(0)
            img_name = "frame%d.png" % (i)
            cv2.imwrite(os.path.join(save_path, img_name), frame)

        print("Successfully capture %d images at %s" % (numPics, save_path))
    else:
        print("Camera %d open failed" % sensor_id)

if __name__ == '__main__':
    capture_checkerboard()
