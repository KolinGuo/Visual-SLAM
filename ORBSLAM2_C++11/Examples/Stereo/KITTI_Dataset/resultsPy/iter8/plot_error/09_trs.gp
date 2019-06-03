set term postscript eps enhanced color
set output "09_trs.eps"
set size ratio 0.5
set yrange [0:*]
set xlabel "Speed [km/h]"
set ylabel "Translation Error [%]\nRotation Error [deg/100m]"
plot "09_ts.txt" using ($1*3.6):($2*100) title 'Translation Error' lc rgb "#FF0000" pt 4 w linespoints,"09_rs.txt" using ($1*3.6):($2*57.3*100) title 'Rotation Error' lc rgb "#0000FF" pt 4 w linespoints
