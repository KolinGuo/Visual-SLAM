set term postscript eps enhanced color
set output "04_rl.eps"
set size ratio 0.5
set yrange [0:*]
set xlabel "Path Length [m]"
set ylabel "Rotation Error [deg/100m]"
plot "04_rl.txt" using 1:($2*57.3*100) title 'Rotation Error' lc rgb "#0000FF" pt 4 w linespoints
