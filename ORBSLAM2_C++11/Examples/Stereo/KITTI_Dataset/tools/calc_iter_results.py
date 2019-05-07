import os
import sys
import numpy as np

def file_len(filePath):
    with open(filePath, 'r') as f:
        for i, l in enumerate(f):
            pass
    return i + 1

# Input: argv[1] = path to benchmark iteration results folder
def main():
    totTransError = np.empty(0, dtype = np.float64)
    totRotError   = np.empty(0, dtype = np.float64)
    totMedianTime = np.empty(0, dtype = np.float64)
    totMeanTime   = np.empty(0, dtype = np.float64)

    iterNum = len(os.listdir(sys.argv[1]))
    totStatsFile = open(sys.argv[1]+'/'+"stats.txt", 'w')
    totTimesFile = open(sys.argv[1]+'/'+"times.txt", 'w')
    # Write headers
    totStatsFile.write('\t\t\t\t\t\t\tAverage Relative Error\n')
    totStatsFile.write('\t\t\t\tt_rel (%)\t\t\t\t\t\t\tr_rel (deg/100m)\n')
    totStatsFile.write('Seq #\tmean\t\tlow\t\thigh\t\tstd\t\tmean\t\tlow\t\thigh\t\tstd\n')
    totTimesFile.write('\t\t\t\t\t\t\tTracking Time\n')
    totTimesFile.write('\t\t\t\tmedian\t\t\t\t\t\t\t\tmean\n')
    totTimesFile.write('Seq #\tmean\t\tlow\t\thigh\t\tstd\t\tmean\t\tlow\t\thigh\t\tstd\n')

    seqNum = file_len(sys.argv[1]+'/'+os.listdir(sys.argv[1])[0]+'/'+"stats.txt") - 4
    seqCount = 0
    while (seqCount < seqNum):
        # Initialize
        transError = np.empty(0, dtype = np.float64)
        rotError   = np.empty(0, dtype = np.float64)
        medianTime = np.empty(0, dtype = np.float64)
        meanTime   = np.empty(0, dtype = np.float64)

        # Go through all iterations
        seqNumWrite = 0
        for iterDir in os.listdir(sys.argv[1]):
            if (iterDir == "stats.txt" or iterDir == "times.txt"):
                continue
            statsFilePath = sys.argv[1]+'/'+iterDir+'/'+"stats.txt"
            timesFilePath = sys.argv[1]+'/'+iterDir+'/'+"times.txt"

            with open(statsFilePath, 'r') as statsFile:
                for i, line in enumerate(statsFile):
                    if (i == 2+seqCount):
                        if (seqNumWrite == 0):
                            totStatsFile.write(line.split()[0])
                        transError = np.append(transError, np.array(line.split()[1], dtype = np.float64))
                        rotError   = np.append(rotError, np.array(line.split()[2], dtype   = np.float64))

            with open(timesFilePath, 'r') as timesFile:
                for i, line in enumerate(timesFile):
                    if (i == 2+seqCount):
                        if (seqNumWrite == 0):
                            totTimesFile.write(line.split()[0])
                        medianTime = np.append(medianTime, np.array(line.split()[1], dtype = np.float64))
                        meanTime   = np.append(meanTime, np.array(line.split()[2], dtype   = np.float64))
            seqNumWrite = 1

        # Calculate and append to totStatsFile/totTimesFile
        totStatsFile.write('\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n' 
                % ( np.mean(transError) , np.amin(transError) , np.amax(transError) , np.std(transError) ,
                    np.mean(rotError)   , np.amin(rotError)   , np.amax(rotError)   , np.std(rotError)    ))
        totTimesFile.write('\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\n' 
                % ( np.mean(medianTime) , np.amin(medianTime) , np.amax(medianTime) , np.std(medianTime) ,
                    np.mean(meanTime)   , np.amin(meanTime)   , np.amax(meanTime)   , np.std(meanTime)    ))

        # Save to total result
        totTransError = np.append(totTransError, transError)
        totRotError   = np.append(totRotError, rotError)
        totMedianTime = np.append(totMedianTime, medianTime)
        totMeanTime   = np.append(totMeanTime, meanTime)

        seqCount+=1

    totStatsFile.write('-' * 129 + '\n')
    totStatsFile.write('avg\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n' 
            % ( np.mean(totTransError) , np.amin(totTransError) , np.amax(totTransError) , np.std(totTransError) ,
                np.mean(totRotError)   , np.amin(totRotError)   , np.amax(totRotError)   , np.std(totRotError)    ))
    totTimesFile.write('-' * 129 + '\n')
    totTimesFile.write('avg\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\n' 
            % ( np.mean(totMedianTime) , np.amin(totMedianTime) , np.amax(totMedianTime) , np.std(totMedianTime) ,
                np.mean(totMeanTime)   , np.amin(totMeanTime)   , np.amax(totMeanTime)   , np.std(totMeanTime)    ))

    totStatsFile.close()
    totTimesFile.close()
    print('Successfully calculated results from %d iterations of %d sequences' % (iterNum, seqCount))

if __name__ == "__main__":
    main()
