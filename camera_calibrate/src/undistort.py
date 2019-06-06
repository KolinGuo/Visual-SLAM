import cv2
import sys
import os

def undistort():
    if (3 != len(sys.argv)):
        print("Usage: ./undistort <yaml_file> <path/to/images> \n")
        sys.exit(1)
    
    save_path = "../images/undistorted_images"
    if (not os.path.exists(save_path)):
        os.makedirs(save_path)

    fs = cv2.FileStorage(sys.argv[1], cv2.FILE_STORAGE_READ)
    dist = fs.getNode("distortion coefficients").mat()
    mtx = fs.getNode("camera matrix").mat()
    fs.release()

    count = 0
    for img_path in os.listdir(sys.argv[2]):
        #print("Processing " + img_path)
        img = cv2.imread(sys.argv[2] + img_path)
        img_dist = cv2.undistort(img, mtx, dist)
        img_dist_name = img_path.split('.')[0] + ".png"
        cv2.imwrite(os.path.join(save_path, img_dist_name), img_dist)
        count += 1

    print("Finish processing %d images" % count)

if __name__ == '__main__':
    undistort()

