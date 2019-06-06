import cv2
import numpy as np
import sys
import os

def calibrate_camera():
    if (3 != len(sys.argv)):
        print("Usage: ./capture_checkerboard <yaml_file> <path/to/images> \n")
        sys.exit(1)

    save_path = "../images/drawn_corners"
    if (not os.path.exists(save_path)):
        os.makedirs(save_path)
    f = open(sys.argv[1], 'w+')
    f.close()

    nx = 9
    ny = 6
    
    obj_points = []
    img_points = []
    objp = np.zeros((nx*ny, 3), np.float32)
    objp[:,:2] = np.mgrid[0:nx,0:ny].T.reshape(-1,2)

    for img_path in os.listdir(sys.argv[2]):
        img = cv2.imread(sys.argv[2] + img_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        ret, corners = cv2.findChessboardCorners(img, (nx,ny), None)

        if (ret == True):
            img_points.append(corners)
            obj_points.append(objp)

            img = cv2.drawChessboardCorners(img, (nx,ny), corners, ret)
            img_corner_name = img_path.split('.')[0] + ".png"
            cv2.imwrite(os.path.join(save_path, img_corner_name), img)

    ret, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(obj_points, img_points, gray.shape[::-1],None,None)

    fs = cv2.FileStorage(sys.argv[1], cv2.FILE_STORAGE_WRITE)
    fs.write("distortion coefficients", dist)
    fs.write("camera matrix", mtx)
    fs.release()

if __name__ == '__main__':
    calibrate_camera()
