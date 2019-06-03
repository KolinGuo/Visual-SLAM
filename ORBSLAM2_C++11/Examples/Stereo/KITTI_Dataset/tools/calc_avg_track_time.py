import sys
import numpy as np

def main():
    median = np.empty(0, dtype=np.float64)
    mean = np.empty(0, dtype=np.float64)
    with open(sys.argv[1], 'r') as file:
        for i, line in enumerate(file):
            if (i >= 2):
                median = np.append(median, np.array(line.split()[1], dtype=np.float64))
                mean = np.append(mean, np.array(line.split()[2], dtype=np.float64))

    file = open(sys.argv[1], 'a')
    file.write('----------------------------------------\n')
    file.write('avg\t%.7f\t%.7f\n' % (np.median(median), np.mean(mean)))
    file.close()
    print('Successfully calculated average tracking time')

if __name__ == "__main__":
    main()
