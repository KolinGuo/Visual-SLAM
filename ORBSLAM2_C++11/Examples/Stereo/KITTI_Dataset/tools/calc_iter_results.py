import os
import sys
import numpy as np
import matplotlib.pyplot as plt

def file_len(filePath):
    with open(filePath, 'r') as f:
        for i, l in enumerate(f):
            pass
    return i + 1

# Input: argv[1] = path to benchmark iteration results folder
def main():
    totTransError = []
    totRotError   = []
    totMedianTime = []
    totMeanTime   = []

    iterNum = len(os.listdir(sys.argv[1])) - 1
    totStatsFile = open(sys.argv[1]+'/'+"stats.txt", 'w')
    totTimesFile = open(sys.argv[1]+'/'+"times.txt", 'w')
    # Write headers
    totStatsFile.write('\t\t\t\t\t\t\tAverage Relative Error\n')
    totStatsFile.write('\t\t\t\tt_rel (%)\t\t\t\t\t\t\tr_rel (deg/100m)\n')
    totStatsFile.write('Seq #\tmean\t\tlow\t\thigh\t\tstd\t\tmean\t\tlow\t\thigh\t\tstd\n')
    totTimesFile.write('\t\t\t\t\t\t\tTracking Time\n')
    totTimesFile.write('\t\t\t\tmedian\t\t\t\t\t\t\t\tmean\n')
    totTimesFile.write('Seq #\tmedian\t\tlow\t\thigh\t\tstd\t\tmean\t\tlow\t\thigh\t\tstd\n')

    seqNum = file_len(sys.argv[1]+'/'+os.listdir(sys.argv[1])[0]+'/'+"stats.txt") - 4
    seqCount = 0
    seqLabels = []
    while (seqCount < seqNum):
        # Initialize
        transError = np.empty(0, dtype = np.float64)
        rotError   = np.empty(0, dtype = np.float64)
        medianTime = np.empty(0, dtype = np.float64)
        meanTime   = np.empty(0, dtype = np.float64)

        # Go through all iterations
        seqNumWrite = 0
        for iterDir in os.listdir(sys.argv[1]):
            if (iterDir == "stats.txt" or iterDir == "times.txt" or iterDir == "plots"):
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
                            seqLabels.append(line.split()[0])
                        medianTime = np.append(medianTime, np.array(line.split()[1], dtype = np.float64))
                        meanTime   = np.append(meanTime, np.array(line.split()[2], dtype   = np.float64))
            seqNumWrite = 1

        # Calculate and append to totStatsFile/totTimesFile
        totStatsFile.write('\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n' 
                % ( np.mean(transError) , np.amin(transError) , np.amax(transError) , np.std(transError) ,
                    np.mean(rotError)   , np.amin(rotError)   , np.amax(rotError)   , np.std(rotError)    ))
        totTimesFile.write('\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\n' 
                % ( np.median(medianTime) , np.amin(medianTime) , np.amax(medianTime) , np.std(medianTime) ,
                    np.mean(meanTime)     , np.amin(meanTime)   , np.amax(meanTime)   , np.std(meanTime)    ))

        # Save to total result
        totTransError.append(transError)
        totRotError.append(rotError)
        totMedianTime.append(medianTime)
        totMeanTime.append(meanTime)

        seqCount+=1

    totStatsFile.write('-' * 129 + '\n')
    totStatsFile.write('avg\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n' 
            % ( np.mean(totTransError) , np.amin(totTransError) , np.amax(totTransError) , np.std(totTransError) ,
                np.mean(totRotError)   , np.amin(totRotError)   , np.amax(totRotError)   , np.std(totRotError)    ))
    totTimesFile.write('-' * 129 + '\n')
    totTimesFile.write('avg\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\t%.7f\n' 
            % ( np.median(totMedianTime) , np.amin(totMedianTime) , np.amax(totMedianTime) , np.std(totMedianTime) ,
                np.mean(totMeanTime)     , np.amin(totMeanTime)   , np.amax(totMeanTime)   , np.std(totMeanTime)    ))

    totStatsFile.close()
    totTimesFile.close()
    print('Successfully calculated results from %d iterations of %d sequences' % (iterNum, seqCount))

    plotSavePath = sys.argv[1]+'/plots/'

    fig1, ax1 = plt.subplots()
    ax1.set_title('Translation Error of 11 Sequences')
    boxplot1 = ax1.boxplot(totTransError, labels=seqLabels, 
            showmeans=True, meanprops=dict(marker='^', markerfacecolor='g', linestyle='None'))
    boxplot1['means'][0].set_label('Means')
    boxplot1['medians'][0].set_label('Medians')
    ax1.legend()
    plt.xlabel("KITTI Sequence Number")
    plt.ylabel("Average Relative Translation Error [%]")
    plt.grid(axis='y', alpha=0.4, color='k', linestyle='--')
    plt.savefig(plotSavePath+'trans_error.png', dpi=1200)

    fig2, ax2 = plt.subplots()
    ax2.set_title('Rotation Error of 11 Sequences')
    boxplot2 = ax2.boxplot(totRotError, labels=seqLabels, 
            showmeans=True, meanprops=dict(marker='^', markerfacecolor='g', linestyle='None'))
    boxplot2['means'][0].set_label('Means')
    boxplot2['medians'][0].set_label('Medians')
    ax2.legend()
    plt.xlabel("KITTI Sequence Number")
    plt.ylabel("Average Relative Rotation Error [deg/100m]")
    plt.grid(axis='y', alpha=0.4, color='k', linestyle='--')
    plt.savefig(plotSavePath+'rot_error.png', dpi=1200)

    fig3, ax3 = plt.subplots()
    ax3.set_title('Median Tracking Time of 11 Sequences')
    boxplot3 = ax3.boxplot(totMedianTime, labels=seqLabels, 
            showmeans=True, meanprops=dict(marker='^', markerfacecolor='g', linestyle='None'))
    boxplot3['means'][0].set_label('Means')
    boxplot3['medians'][0].set_label('Medians')
    ax3.legend()
    plt.xlabel("KITTI Sequence Number")
    plt.ylabel("Median Tracking Time [s]")
    plt.grid(axis='y', alpha=0.4, color='k', linestyle='--')
    plt.savefig(plotSavePath+'median_track_time.png', dpi=1200)

    fig4, ax4 = plt.subplots()
    ax4.set_title('Mean Tracking Time of 11 Sequences')
    boxplot4 = ax4.boxplot(totMeanTime, labels=seqLabels, 
            showmeans=True, meanprops=dict(marker='^', markerfacecolor='g', linestyle='None'))
    boxplot4['means'][0].set_label('Means')
    boxplot4['medians'][0].set_label('Medians')
    ax4.legend()
    plt.xlabel("KITTI Sequence Number")
    plt.ylabel("Mean Tracking Time [s]")
    plt.grid(axis='y', alpha=0.4, color='k', linestyle='--')
    plt.savefig(plotSavePath+'mean_track_time.png', dpi=1200)

    print('Successfully generated plots from iteration results')

if __name__ == "__main__":
    main()
