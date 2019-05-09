#!/bin/bash
# Make sure you have gnuplot installed
gnuplot --version
if [ $? -ne 0 ] ; then
  echo -e "\ngnuplot not found. Please install it via apt install first\n"
  exit 1
fi
# Make sure you have ghostscript (ps2pdf) installed
ghostscript --version
if [ $? -ne 0 ] ; then
  echo -e "\nghostscript not found. Please install it via apt install first\n"
  exit 1
fi
# Make sure you have pdfcrop installed
pdfcrop --version
if [ $? -ne 0 ] ; then
  echo -e "\npdfcrop not found. Please install it via apt install first\n"
  exit 1
fi

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
USAGE="Usage: ./benchmark_kitti.sh [c++=[0,1]] [py=[0,1]] [iter=[num]] [KITTI Dataset Sequence Numbers]\n"
USAGE+="\tc++=[0,1]  : 0 to not benchmark C++11 implementation\n"
USAGE+="\t             and 1 otherwise\n"
USAGE+="\t             default is 0\n"
USAGE+="\tpy=[0,1]   : 0 to not benchmark python implementation\n"
USAGE+="\t             and 1 otherwise\n"
USAGE+="\t             default is 1\n"
USAGE+="\titer=[num] : number of benchmark iteration\n"
USAGE+="\t             default is 1\n"
USAGE+="\texample    : ./benchmark_kitti.sh 00 05 10\n"
USAGE+="\t             only benchmark 00, 05 and 10 sequence\n"
USAGE+="\t             default is all 11 data sequences 00-10\n"

BMCPLUSPLUS=false
BMPYTHON=true
SEQUENCELIST=$(seq -w 00 10)
SEQUENCELISTFULL=true
declare -i iter
iter=1
RESULTCPLUSPLUSDIR=$(realpath "$SCRIPTPATH/resultC++")
RESULTPYTHONDIR=$(realpath "$SCRIPTPATH/resultPy")

# Parsing argument
if [ $# -ne 0 ] ; then
  while [ ! -z $1 ] ; do
    echo -e "Argument $1"
    if [[ "$1" =~ ^(0[0-9]|10)$ ]] ; then
      if [ "$SEQUENCELISTFULL" = true ] ; then
        SEQUENCELIST="$1"
        SEQUENCELISTFULL=false
      else
        SEQUENCELIST+="\n$1"
      fi
    elif [ "$1" = "c++=1" ] ; then
      BMCPLUSPLUS=true
    elif [ "$1" = "py=0" ] ; then
      BMPYTHON=false
    elif [[ "$1" =~ ^iter=[0-9]+$ ]] ; then
      iter=$(echo -ne "$1" | egrep -o "[0-9]+$")
    elif [[ "$1" != "c++=0" && "$1" != "py=1" ]] ; then
      echo -e "Unknown argument: " $1
      echo -e "$USAGE"
      exit 1
    fi
    shift
  done
fi

# Rebuild evaluate_result.cpp
EVALSCRIPTPATH="$SCRIPTPATH/devkit/cpp"
echo -e "Rebuilding evaluate_result..."
cd "$EVALSCRIPTPATH"
make clean
make
if [ $? -ne 0 ] ; then
  echo -e "\nFailed to make evaluate_result... Exiting...\n"
  exit 1
fi
cd "$SCRIPTPATH"

BMMULTITER=false
# If multiple iteration
if [ $iter -gt 1 ] ; then
  BMMULTITER=true
  RESULTCPLUSPLUSDIR=$(realpath "$SCRIPTPATH/resultsC++")
  RESULTPYTHONDIR=$(realpath "$SCRIPTPATH/resultsPy")
  if [ "$BMCPLUSPLUS" = true ] ; then
    if [ -d "$RESULTCPLUSPLUSDIR" ] ; then
      echo -ne "\nAll contents in\n\t$RESULTCPLUSPLUSDIR\n"
      echo -e "will be deleted."
      echo -e "Press 'y' to continue, and 'q' to quit and save them somewhere else"
      read option
      if [ "$option" = y ] ; then
        rm -rf "$RESULTCPLUSPLUSDIR"
      elif [ "$option" = q ] ; then
        exit 0
      else
        echo -e "\nUnknown command... Exiting...\n"
        exit 1
      fi
    fi
    mkdir -p "$RESULTCPLUSPLUSDIR"
  fi
  if [ "$BMPYTHON" = true ] ; then
    if [ -d "$RESULTPYTHONDIR" ] ; then
      echo -ne "\nAll contents in\n\t$RESULTPYTHONDIR\n"
      echo -e "will be deleted."
      echo -e "Press 'y' to continue, and 'q' to quit and save them somewhere else"
      read option
      if [ "$option" = y ] ; then
        rm -rf "$RESULTPYTHONDIR"
      elif [ "$option" = q ] ; then
        exit 0
      else
        echo -e "\nUnknown command... Exiting...\n"
        exit 1
      fi
    fi
    mkdir -p "$RESULTPYTHONDIR"
  fi
fi

# Create new sequence lists for c++ and python
SEQUENCELISTCPLUSPLUS=""
SEQUENCELISTPYTHON=""

declare -i loopcount
loopcount=0
while [ $loopcount -lt $iter ] ; do
if [ "$BMMULTITER" = true ] ; then
  SEQUENCELISTCPLUSPLUS=$SEQUENCELIST
  SEQUENCELISTPYTHON=$SEQUENCELIST
  if [ $iter -gt 10 ] ; then
    printfcmd="%02d"
  elif [ $iter -gt 100 ] ; then
    printfcmd="%03d"
  else    # Assume no iteration larger than 999
    printfcmd="%01d"
  fi
  dirseqname=$(printf $printfcmd $loopcount)
  RESULTCPLUSPLUSDIR=$(realpath "$SCRIPTPATH/resultsC++/iter$dirseqname")
  RESULTPYTHONDIR=$(realpath "$SCRIPTPATH/resultsPy/iter$dirseqname")
fi

# Check if any benchmark result already exists
if [[ "$BMMULTITER" = false && "$BMCPLUSPLUS" = true ]] ; then
  for seq in $(echo -e $SEQUENCELIST) ; do
    if [[ -d "$RESULTCPLUSPLUSDIR/data" && -f "$RESULTCPLUSPLUSDIR/data/$seq.txt" ]] ; then
      echo -e "\nFile \"$RESULTCPLUSPLUSDIR/data/$seq.txt\" exists"
      echo -e "Press 'y' to overwrite it, 'n' to skip benchmark it and 'q' to quit"
      read option
      if [ "$option" = y ] ; then
        rm -rfv "$RESULTCPLUSPLUSDIR/data/$seq.txt"
        SEQUENCELISTCPLUSPLUS+="$seq\n"
      elif [ "$option" = q ] ; then
        exit 0
      elif [ "$option" != n ] ; then
        echo -e "\nUnknown command... Exiting...\n"
        exit 1
      fi
    else
      SEQUENCELISTCPLUSPLUS+="$seq\n"
    fi
  done
fi

if [[ "$BMMULTITER" = false && "$BMPYTHON" = true ]] ; then
  for seq in $(echo -e $SEQUENCELIST) ; do
    if [[ -d "$RESULTPYTHONDIR/data" && -f "$RESULTPYTHONDIR/data/$seq.txt" ]] ; then
      echo -e "\nFile \"$RESULTPYTHONDIR/data/$seq.txt\" exists"
      echo -e "Press 'y' to overwrite it, 'n' to skip benchmark it and 'q' to quit"
      read option
      if [ "$option" = y ] ; then
        rm -rfv "$RESULTPYTHONDIR/data/$seq.txt"
        SEQUENCELISTPYTHON+="$seq\n"
      elif [ "$option" = q ] ; then
        exit 0
      elif [ "$option" != n ] ; then
        echo -e "\nUnknown command... Exiting...\n"
        exit 1
      fi
    else
      SEQUENCELISTPYTHON+="$seq\n"
    fi
  done
fi

# Echo the benchmark information
echo -e "\n"
echo -e "################################################################################\n"
echo -e "\tKITTI Benchmark Information\n"
if [ "$BMMULTITER" = true ] ; then
  echo -e "\t\tCautious: this benchmark will run $iter iterations"
  echo -e "\t\t\tThis is iteration #$(($loopcount+1))\n"
fi
if [ "$BMCPLUSPLUS" = true ] ; then
  echo -ne "\t\tC++11 Benchmark sequences:\n\t\t\t"
  for seq in $(echo -e $SEQUENCELISTCPLUSPLUS) ; do
    echo -n "$seq "
  done
  echo -e "\n"
else
  echo -e "\t\tDon't benchmark C++11 implementation\n"
fi
if [ "$BMPYTHON" = true ] ; then
  echo -ne "\t\tPython Benchmark sequences:\n\t\t\t"
  for seq in $(echo -e $SEQUENCELISTPYTHON) ; do
    echo -n "$seq "
  done
  echo -e "\n"
else
  echo -e "\t\tDon't benchmark Python implementation\n"
fi
echo -e "################################################################################\n"

# Print usage
echo -e "\n$USAGE\n"

echo -e ".......... Benchmark will start in 5 seconds .........."
sleep 5

BMCPLUSPLUSLOC=$(realpath "$SCRIPTPATH/../")
BMCPLUSPLUSCMD00_02="./stereo_kitti ../../Vocabulary/ORBvoc.txt ./KITTI00-02.yaml ./KITTI_Dataset/dataset/sequences/"
BMCPLUSPLUSCMD03="./stereo_kitti ../../Vocabulary/ORBvoc.txt ./KITTI03.yaml ./KITTI_Dataset/dataset/sequences/"
BMCPLUSPLUSCMD04_12="./stereo_kitti ../../Vocabulary/ORBvoc.txt ./KITTI04-12.yaml ./KITTI_Dataset/dataset/sequences/"
if [ "$BMCPLUSPLUS" = true ] ; then
  # Make directory for C++11 benchmark results
  echo -e "\nMaking new directory to hold C++11 benchmark results..."
  mkdir -p "$RESULTCPLUSPLUSDIR/data"
  mkdir -p "$RESULTCPLUSPLUSDIR/logs"
  mkdir -p "$RESULTCPLUSPLUSDIR/errors"
  mkdir -p "$RESULTCPLUSPLUSDIR/plot_path"
  mkdir -p "$RESULTCPLUSPLUSDIR/plot_error"

  # Call C++11 implementation
  echo -e "\nCalling C++11 implementation..."
  cd "$BMCPLUSPLUSLOC"
  for seq in $(echo -e $SEQUENCELISTCPLUSPLUS) ; do
    # Run implementation
    echo -e "\nBenchmarking sequence $seq..."
    if [[ "$seq" =~ ^0[0-2]$ ]] ; then
      date > "$RESULTCPLUSPLUSDIR/logs/$seq.log"  # Add timestamp
      $BMCPLUSPLUSCMD00_02$seq >> "$RESULTCPLUSPLUSDIR/logs/$seq.log"
    elif [[ "$seq" =~ ^03$ ]] ; then
      date > "$RESULTCPLUSPLUSDIR/logs/$seq.log"  # Add timestamp
      $BMCPLUSPLUSCMD03$seq >> "$RESULTCPLUSPLUSDIR/logs/$seq.log"
    elif [[ "$seq" =~ ^(0[4-9]|10)$ ]] ; then
      date > "$RESULTCPLUSPLUSDIR/logs/$seq.log"  # Add timestamp
      $BMCPLUSPLUSCMD04_12$seq >> "$RESULTCPLUSPLUSDIR/logs/$seq.log"
    else
      echo -e "\nWrong sequence number $seq\n"
      exit 1
    fi
    # Check return status
    if [ $? -ne 0 ] ; then
      echo -e "\nFailed to benchmark C++11 implementation... Exiting...\n"
      exit 1
    else
      echo -e "Success! Output is logged at $RESULTCPLUSPLUSDIR/logs/$seq.log"
    fi
    # Move result
    if [ -f "CameraTrajectory.txt" ] ; then
      mv -f "CameraTrajectory.txt" "$RESULTCPLUSPLUSDIR/data/$seq.txt"
    else
      echo -e "\nNo CameraTrajectory.txt found... Exiting...\n"
      exit 1
    fi
  done
  cd "$SCRIPTPATH"

  # Extract tracking time from log
  echo -e "\nExtracting tracking times from logs..."
  if [ -f "$RESULTCPLUSPLUSDIR/times.txt" ] ; then
    rm -f "$RESULTCPLUSPLUSDIR/times.txt"
  fi
  echo -ne " \t\tTracking Time\nSeq #\tmedian\t\tmean\n" \
    > "$RESULTCPLUSPLUSDIR/times.txt"
  for seqlog in $(ls -al "$RESULTCPLUSPLUSDIR/logs" | egrep -oh "(0[0-9]|10).log$") ; do
    echo -ne "$seqlog" | egrep -oh "^(0[0-9]|10)" | tr -d '\n'\
      >> "$RESULTCPLUSPLUSDIR/times.txt"

    echo -ne "\t" \
      >> "$RESULTCPLUSPLUSDIR/times.txt"

    egrep -h "^median tracking time" "$RESULTCPLUSPLUSDIR/logs/$seqlog" | \
      egrep -oh "[0-9].[0-9]+$" | tr -d '\n' \
      >> "$RESULTCPLUSPLUSDIR/times.txt"

    echo -ne "\t" \
      >> "$RESULTCPLUSPLUSDIR/times.txt"

    egrep -h "^mean tracking time" "$RESULTCPLUSPLUSDIR/logs/$seqlog" | \
      egrep -oh "[0-9].[0-9]+$" | tr -d '\n' \
      >> "$RESULTCPLUSPLUSDIR/times.txt"

    echo -ne "\n" \
      >> "$RESULTCPLUSPLUSDIR/times.txt"
  done

  # Calculate average tracking time
  python3 "$SCRIPTPATH/tools/calc_avg_track_time.py" "$RESULTCPLUSPLUSDIR/times.txt"
  if [ $? -ne 0 ] ; then
    echo -e "\nFailed to calculate average tracking time..."
  fi

  # Evaluate Results
  echo -e "\nEvaluating C++11 results..."
  cd "$EVALSCRIPTPATH"
  ./evaluate_result "$RESULTCPLUSPLUSDIR"
  if [ $? -ne 0 ] ; then
    echo -e "\nFailed to evaluate C++11 results... Exiting...\n"
    exit 1
  fi
  cd "$SCRIPTPATH"
fi

BMPYTHONLOC=$(realpath "$SCRIPTPATH/../../../../examples/")
BMPYTHONVOCLOC=$(realpath "$SCRIPTPATH/../../../Vocabulary/ORBvoc.txt")
BMPYTHONDATALOC=$(realpath "$SCRIPTPATH/../")
BMPYTHONCMD00_02="orbslam_stereo_kitti.py $BMPYTHONVOCLOC $BMPYTHONDATALOC/KITTI00-02.yaml $BMPYTHONDATALOC/KITTI_Dataset/dataset/sequences/"
BMPYTHONCMD03="orbslam_stereo_kitti.py $BMPYTHONVOCLOC $BMPYTHONDATALOC/KITTI03.yaml $BMPYTHONDATALOC/KITTI_Dataset/dataset/sequences/"
BMPYTHONCMD04_12="orbslam_stereo_kitti.py $BMPYTHONVOCLOC $BMPYTHONDATALOC/KITTI04-12.yaml $BMPYTHONDATALOC/KITTI_Dataset/dataset/sequences/"
if [ "$BMPYTHON" = true ] ; then
  # Make directory for python benchmark results
  echo -e "\nMaking new directory to hold python benchmark results..."
  mkdir -p "$RESULTPYTHONDIR/data"
  mkdir -p "$RESULTPYTHONDIR/logs"
  mkdir -p "$RESULTPYTHONDIR/errors"
  mkdir -p "$RESULTPYTHONDIR/plot_path"
  mkdir -p "$RESULTPYTHONDIR/plot_error"

  # Call Python implementation
  echo -e "\nCalling Python implementation..."
  cd "$BMPYTHONLOC"
  for seq in $(echo -e $SEQUENCELISTPYTHON) ; do
    # Run implementation
    echo -e "\nBenchmarking sequence $seq..."
    if [[ "$seq" =~ ^0[0-2]$ ]] ; then
      date > "$RESULTPYTHONDIR/logs/$seq.log"  # Add timestamp
      python3 $BMPYTHONCMD00_02$seq >> "$RESULTPYTHONDIR/logs/$seq.log"
    elif [[ "$seq" =~ ^03$ ]] ; then
      date > "$RESULTPYTHONDIR/logs/$seq.log"  # Add timestamp
      python3 $BMPYTHONCMD03$seq >> "$RESULTPYTHONDIR/logs/$seq.log"
    elif [[ "$seq" =~ ^(0[4-9]|10)$ ]] ; then
      date > "$RESULTPYTHONDIR/logs/$seq.log"  # Add timestamp
      python3 $BMPYTHONCMD04_12$seq >> "$RESULTPYTHONDIR/logs/$seq.log"
    else
      echo -e "\nWrong sequence number $seq\n"
      exit 1
    fi
    # Check return status
    if [ $? -ne 0 ] ; then
      echo -e "\nFailed to benchmark Python implementation... Exiting...\n"
      exit 1
    else
      echo -e "Success! Output is logged at $RESULTPYTHONDIR/logs/$seq.log"
    fi
    # Move result
    if [ -f "trajectory.txt" ] ; then
      mv -f "trajectory.txt" "$RESULTPYTHONDIR/data/$seq.txt"
    else
      echo -e "\nNo trajectory.txt found... Exiting...\n"
      exit 1
    fi
  done
  cd "$SCRIPTPATH"

  # Extract tracking time from log
  echo -e "\nExtracting tracking times from logs..."
  if [ -f "$RESULTPYTHONDIR/times.txt" ] ; then
    rm -f "$RESULTPYTHONDIR/times.txt"
  fi
  echo -ne " \t\tTracking Time\nSeq #\tmedian\t\tmean\n" \
    > "$RESULTPYTHONDIR/times.txt"
  for seqlog in $(ls -al "$RESULTPYTHONDIR/logs" | egrep -oh "(0[0-9]|10).log$") ; do
    echo -ne "$seqlog" | egrep -oh "^(0[0-9]|10)" | tr -d '\n'\
      >> "$RESULTPYTHONDIR/times.txt"

    echo -ne "\t" \
      >> "$RESULTPYTHONDIR/times.txt"

    tmpnum=$(egrep -h "^median tracking time" "$RESULTPYTHONDIR/logs/$seqlog" | \
      egrep -oh "[0-9].[0-9]+$" | tr -d '\n')
    python3 -c "print('%.7f' % $tmpnum)" | tr -d '\n' \
      >> "$RESULTPYTHONDIR/times.txt"

    echo -ne "\t" \
      >> "$RESULTPYTHONDIR/times.txt"

    tmpnum=$(egrep -h "^mean tracking time" "$RESULTPYTHONDIR/logs/$seqlog" | \
      egrep -oh "[0-9].[0-9]+$" | tr -d '\n')
    python3 -c "print('%.7f' % $tmpnum)" | tr -d '\n' \
      >> "$RESULTPYTHONDIR/times.txt"

    echo -ne "\n" \
      >> "$RESULTPYTHONDIR/times.txt"
  done

  # Calculate average tracking time
  python3 "$SCRIPTPATH/tools/calc_avg_track_time.py" "$RESULTPYTHONDIR/times.txt"
  if [ $? -ne 0 ] ; then
    echo -e "\nFailed to calculate average tracking time..."
  fi

  # Evaluate Results
  echo -e "\nEvaluating Python results..."
  cd "$EVALSCRIPTPATH"
  ./evaluate_result "$RESULTPYTHONDIR"
  if [ $? -ne 0 ] ; then
    echo -e "\nFailed to evaluate Python results... Exiting...\n"
    exit 1
  fi
  cd "$SCRIPTPATH"
fi
loopcount+=1  # Finish this iteration
done

# Calculate iteration results
if [ "$BMMULTITER" = true ] ; then
  if [ "$BMCPLUSPLUS" = true ] ; then
    echo -e "\nCalculating C++11 iteration results..."
    RESULTCPLUSPLUSDIR=$(realpath "$RESULTCPLUSPLUSDIR/../")
    mkdir -p "$RESULTCPLUSPLUSDIR/plots"
    python3 "$SCRIPTPATH/tools/calc_iter_results.py" "$RESULTCPLUSPLUSDIR"
    if [ $? -ne 0 ] ; then
      echo -e "\nFailed to calculate C++11 iteration results..."
    fi
  fi
  if [ "$BMPYTHON" = true ] ; then
    echo -e "\nCalculating Python iteration results..."
    RESULTPYTHONDIR=$(realpath "$RESULTPYTHONDIR/../")
    mkdir -p "$RESULTPYTHONDIR/plots"
    python3 "$SCRIPTPATH/tools/calc_iter_results.py" "$RESULTPYTHONDIR"
    if [ $? -ne 0 ] ; then
      echo -e "\nFailed to calculate Python iteration results..."
    fi
  fi
fi

# Print benchmark result
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tKITTI Benchmark Result\n"
if [ "$BMCPLUSPLUS" = true ] ; then
  echo -ne "\t\tC++11 Benchmark Result:\n\n"
  cat "$RESULTCPLUSPLUSDIR/times.txt"
  echo ""
  cat "$RESULTCPLUSPLUSDIR/stats.txt"
  echo -e "\n"
fi
if [ "$BMPYTHON" = true ] ; then
  echo -ne "\t\tPython Benchmark Result:\n\n"
  cat "$RESULTPYTHONDIR/times.txt"
  echo ""
  cat "$RESULTPYTHONDIR/stats.txt"
  echo -e "\n"
fi
echo -e "################################################################################\n"
