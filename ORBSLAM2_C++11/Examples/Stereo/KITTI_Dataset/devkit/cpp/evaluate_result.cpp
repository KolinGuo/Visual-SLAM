#include <iostream>
#include <stdio.h>
#include <math.h>
#include <vector>
#include <limits>
#include <limits.h>
#include <libgen.h>

#include "matrix.h"

using namespace std;
string script_dir;

// static parameter
// float lengths[] = {5,10,50,100,150,200,250,300,350,400};
float lengths[] = {100,200,300,400,500,600,700,800};
int32_t num_lengths = 8;

struct errors {
  int32_t first_frame;
  float   r_err;
  float   t_err;
  float   len;
  float   speed;
  errors (int32_t first_frame,float r_err,float t_err,float len,float speed) :
    first_frame(first_frame),r_err(r_err),t_err(t_err),len(len),speed(speed) {}
};

vector<Matrix> loadPoses(const string &file_name) {
  vector<Matrix> poses;
  FILE *fp = fopen(file_name.c_str(),"r");
  if (!fp)
    return poses;
  while (!feof(fp)) {
    Matrix P = Matrix::eye(4);
    if (fscanf(fp, "%lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf",
                   &P.val[0][0], &P.val[0][1], &P.val[0][2], &P.val[0][3],
                   &P.val[1][0], &P.val[1][1], &P.val[1][2], &P.val[1][3],
                   &P.val[2][0], &P.val[2][1], &P.val[2][2], &P.val[2][3] )==12) {
      poses.push_back(P);
    }
  }
  fclose(fp);
  return poses;
}

vector<float> trajectoryDistances (const vector<Matrix> &poses) {
  vector<float> dist;
  dist.push_back(0);
  for (int32_t i=1; i<poses.size(); i++) {
    Matrix P1 = poses[i-1];
    Matrix P2 = poses[i];
    float dx = P1.val[0][3]-P2.val[0][3];
    float dy = P1.val[1][3]-P2.val[1][3];
    float dz = P1.val[2][3]-P2.val[2][3];
    dist.push_back(dist[i-1]+sqrt(dx*dx+dy*dy+dz*dz));
  }
  return dist;
}

int32_t lastFrameFromSegmentLength(const vector<float> &dist,const int32_t &first_frame,const float &len) {
  for (int32_t i=first_frame; i<dist.size(); i++)
    if (dist[i]>dist[first_frame]+len)
      return i;
  return -1;
}

inline float rotationError(const Matrix &pose_error) {
  float a = pose_error.val[0][0];
  float b = pose_error.val[1][1];
  float c = pose_error.val[2][2];
  float d = 0.5*(a+b+c-1.0);
  return acos(max(min(d,1.0f),-1.0f));
}

inline float translationError(const Matrix &pose_error) {
  float dx = pose_error.val[0][3];
  float dy = pose_error.val[1][3];
  float dz = pose_error.val[2][3];
  return sqrt(dx*dx+dy*dy+dz*dz);
}

vector<errors> calcSequenceErrors (const vector<Matrix> &poses_gt,const vector<Matrix> &poses_result) {

  // error vector
  vector<errors> err;

  // parameters
  int32_t step_size = 10; // every second
  
  // pre-compute distances (from ground truth as reference)
  vector<float> dist = trajectoryDistances(poses_gt);
 
  // for all start positions do
  for (int32_t first_frame=0; first_frame<poses_gt.size(); first_frame+=step_size) {
  
    // for all segment lengths do
    for (int32_t i=0; i<num_lengths; i++) {
    
      // current length
      float len = lengths[i];
      
      // compute last frame
      int32_t last_frame = lastFrameFromSegmentLength(dist,first_frame,len);
      
      // continue, if sequence not long enough
      if (last_frame==-1)
        continue;

      // compute rotational and translational errors
      Matrix pose_delta_gt     = Matrix::inv(poses_gt[first_frame])*poses_gt[last_frame];
      Matrix pose_delta_result = Matrix::inv(poses_result[first_frame])*poses_result[last_frame];
      Matrix pose_error        = Matrix::inv(pose_delta_result)*pose_delta_gt;
      float r_err = rotationError(pose_error);
      float t_err = translationError(pose_error);
      
      // compute speed
      float num_frames = (float)(last_frame-first_frame+1);
      float speed = len/(0.1*num_frames);
      
      // write to file
      err.push_back(errors(first_frame,r_err/len,t_err/len,len,speed));
    }
  }

  // return error vector
  return err;
}

void saveSequenceErrors (const vector<errors> &err, const string &file_name) {

  // open file  
  FILE *fp;
  fp = fopen(file_name.c_str(),"w");
 
  // write to file
  for (vector<errors>::const_iterator it=err.begin(); it!=err.end(); it++)
    fprintf(fp,"%d %f %f %f %f\n",it->first_frame,it->r_err,it->t_err,it->len,it->speed);
  
  // close file
  fclose(fp);
}

void savePathPlot (const vector<Matrix> &poses_gt,const vector<Matrix> &poses_result,const string &file_name) {

  // parameters
  int32_t step_size = 3;

  // open file  
  FILE *fp = fopen(file_name.c_str(),"w");
 
  // save x/z coordinates of all frames to file
  for (int32_t i=0; i<poses_gt.size(); i+=step_size)
    fprintf(fp,"%f %f %f %f\n",poses_gt[i].val[0][3],poses_gt[i].val[2][3],
                               poses_result[i].val[0][3],poses_result[i].val[2][3]);
  
  // close file
  fclose(fp);
}

vector<int32_t> computeRoi (const vector<Matrix> &poses_gt,const vector<Matrix> &poses_result) {
  
  float x_min = numeric_limits<int32_t>::max();
  float x_max = numeric_limits<int32_t>::min();
  float z_min = numeric_limits<int32_t>::max();
  float z_max = numeric_limits<int32_t>::min();
  
  for (vector<Matrix>::const_iterator it=poses_gt.begin(); it!=poses_gt.end(); it++) {
    float x = it->val[0][3];
    float z = it->val[2][3];
    if (x<x_min) x_min = x; if (x>x_max) x_max = x;
    if (z<z_min) z_min = z; if (z>z_max) z_max = z;
  }
  
  for (vector<Matrix>::const_iterator it=poses_result.begin(); it!=poses_result.end(); it++) {
    float x = it->val[0][3];
    float z = it->val[2][3];
    if (x<x_min) x_min = x; if (x>x_max) x_max = x;
    if (z<z_min) z_min = z; if (z>z_max) z_max = z;
  }
  
  float dx = 1.1*(x_max-x_min);
  float dz = 1.1*(z_max-z_min);
  float mx = 0.5*(x_max+x_min);
  float mz = 0.5*(z_max+z_min);
  float r  = 0.5*max(dx,dz);
  
  vector<int32_t> roi;
  roi.push_back((int32_t)(mx-r));
  roi.push_back((int32_t)(mx+r));
  roi.push_back((int32_t)(mz-r));
  roi.push_back((int32_t)(mz+r));
  return roi;
}

void plotPathPlot (const string &dir,const vector<int32_t> &roi,const int32_t &idx) {

  // gnuplot file name
  char command[1024];
  char file_name[256];
  sprintf(file_name,"%02d.gp",idx);
  string full_name = dir + "/" + file_name;
  
  // create png + eps
  for (int32_t i=0; i<2; i++) {

    // open file  
    FILE *fp = fopen(full_name.c_str(),"w");

    // save gnuplot instructions
    if (i==0) {
      fprintf(fp,"set term png size 900,900\n");
      fprintf(fp,"set output \"%02d.png\"\n",idx);
    } else {
      fprintf(fp,"set term postscript eps enhanced color\n");
      fprintf(fp,"set output \"%02d.eps\"\n",idx);
    }

    fprintf(fp,"set size ratio -1\n");
    fprintf(fp,"set xrange [%d:%d]\n",roi[0],roi[1]);
    fprintf(fp,"set yrange [%d:%d]\n",roi[2],roi[3]);
    fprintf(fp,"set xlabel \"x [m]\"\n");
    fprintf(fp,"set ylabel \"z [m]\"\n");
    fprintf(fp,"plot \"%02d.txt\" using 1:2 lc rgb \"#FF0000\" title 'Ground Truth' w lines,",idx);
    fprintf(fp,"\"%02d.txt\" using 3:4 lc rgb \"#0000FF\" title 'Visual Odometry' w lines,",idx);
    fprintf(fp,"\"< head -1 %02d.txt\" using 1:2 lc rgb \"#000000\" pt 4 ps 1 lw 2 title 'Sequence Start' w points\n",idx);
    
    // close file
    fclose(fp);
    
    // run gnuplot => create png + eps
    sprintf(command,"cd \"%s\"; gnuplot \"%s\"",dir.c_str(),file_name);
    system(command);
  }
  
  // create pdf and crop
  sprintf(command,"cd \"%s\"; ps2pdf %02d.eps %02d_large.pdf",dir.c_str(),idx,idx);
    system(command);
  sprintf(command,"cd \"%s\"; pdfcrop %02d_large.pdf %02d.pdf",dir.c_str(),idx,idx);
  system(command);
  sprintf(command,"cd \"%s\"; rm %02d_large.pdf",dir.c_str(),idx);
  system(command);
}

void saveErrorPlots(const vector<errors> &seq_err,const string &plot_error_dir,const char* prefix) {

  // file names
  char file_name_tl[1024]; sprintf(file_name_tl,"%s/%s_tl.txt",plot_error_dir.c_str(),prefix);
  char file_name_rl[1024]; sprintf(file_name_rl,"%s/%s_rl.txt",plot_error_dir.c_str(),prefix);
  char file_name_ts[1024]; sprintf(file_name_ts,"%s/%s_ts.txt",plot_error_dir.c_str(),prefix);
  char file_name_rs[1024]; sprintf(file_name_rs,"%s/%s_rs.txt",plot_error_dir.c_str(),prefix);

  // open files
  FILE *fp_tl = fopen(file_name_tl,"w");
  FILE *fp_rl = fopen(file_name_rl,"w");
  FILE *fp_ts = fopen(file_name_ts,"w");
  FILE *fp_rs = fopen(file_name_rs,"w");
 
  // for each segment length do
  for (int32_t i=0; i<num_lengths; i++) {

    float t_err = 0;
    float r_err = 0;
    float num   = 0;

    // for all errors do
    for (vector<errors>::const_iterator it=seq_err.begin(); it!=seq_err.end(); it++) {
      if (fabs(it->len-lengths[i])<1.0) {
        t_err += it->t_err;
        r_err += it->r_err;
        num++;
      }
    }
    
    // we require at least 3 values
    if (num>2.5) {
      fprintf(fp_tl,"%f %f\n",lengths[i],t_err/num);
      fprintf(fp_rl,"%f %f\n",lengths[i],r_err/num);
    }
  }
  
  // for each driving speed do (in m/s)
  for (float speed=2; speed<25; speed+=2) {

    float t_err = 0;
    float r_err = 0;
    float num   = 0;

    // for all errors do
    for (vector<errors>::const_iterator it=seq_err.begin(); it!=seq_err.end(); it++) {
      if (fabs(it->speed-speed)<2.0) {
        t_err += it->t_err;
        r_err += it->r_err;
        num++;
      }
    }
    
    // we require at least 3 values
    if (num>2.5) {
      fprintf(fp_ts,"%f %f\n",speed,t_err/num);
      fprintf(fp_rs,"%f %f\n",speed,r_err/num);
    }
  }
  
  // close files
  fclose(fp_tl);
  fclose(fp_rl);
  fclose(fp_ts);
  fclose(fp_rs);
}

void plotErrorPlots (const string &dir,const char* prefix) {

  char command[1024];

  // for all four error plots do
  for (int32_t i=0; i<6; i++) {
 
    // create suffix
    char suffix[16];
    switch (i) {
      case 0: sprintf(suffix,"tl"); break;
      case 1: sprintf(suffix,"rl"); break;
      case 2: sprintf(suffix,"trl"); break;
      case 3: sprintf(suffix,"ts"); break;
      case 4: sprintf(suffix,"rs"); break;
      case 5: sprintf(suffix,"trs"); break;
    }
       
    // gnuplot file name
    char file_name[1024]; char full_name[1024];
    sprintf(file_name,"%s_%s.gp",prefix,suffix);
    sprintf(full_name,"%s/%s",dir.c_str(),file_name);
    
    // create png + eps
    for (int32_t j=0; j<2; j++) {

      // open file  
      FILE *fp = fopen(full_name,"w");

      // save gnuplot instructions
      if (j==0) {
        fprintf(fp,"set term png size 500,250 font \"Helvetica\" 11\n");
        fprintf(fp,"set output \"%s_%s.png\"\n",prefix,suffix);
      } else {
        fprintf(fp,"set term postscript eps enhanced color\n");
        fprintf(fp,"set output \"%s_%s.eps\"\n",prefix,suffix);
      }
      
      // start plot at 0
      fprintf(fp,"set size ratio 0.5\n");
      fprintf(fp,"set yrange [0:*]\n");

      // x label
      if (i<=2) fprintf(fp,"set xlabel \"Path Length [m]\"\n");
      else      fprintf(fp,"set xlabel \"Speed [km/h]\"\n");
      
      // y label
      if (i==0 || i==3) 
        fprintf(fp,"set ylabel \"Translation Error [%%]\"\n");
      else if (i==1 || i==4)
        fprintf(fp,"set ylabel \"Rotation Error [deg/100m]\"\n");
      else
        fprintf(fp,"set ylabel \"Translation Error [%%]\\nRotation Error [deg/100m]\"\n");
      
      // plot error curve
      switch (i) {
        case 0: 
          fprintf(fp,"plot \"%s_%s.txt\" using ",prefix,suffix);
          fprintf(fp,"1:($2*100) title 'Translation Error'"); 
          fprintf(fp," lc rgb \"#0000FF\" pt 4 w linespoints\n");
          break;
        case 1: 
          fprintf(fp,"plot \"%s_%s.txt\" using ",prefix,suffix);
          fprintf(fp,"1:($2*57.3*100) title 'Rotation Error'"); 
          fprintf(fp," lc rgb \"#0000FF\" pt 4 w linespoints\n");
          break;
        case 2: 
          fprintf(fp,"plot \"%s_tl.txt\" using ",prefix);
          fprintf(fp,"1:($2*100) title 'Translation Error'"); 
          fprintf(fp," lc rgb \"#FF0000\" pt 4 w linespoints,");
          fprintf(fp,"\"%s_rl.txt\" using ",prefix);
          fprintf(fp,"1:($2*57.3*100) title 'Rotation Error'"); 
          fprintf(fp," lc rgb \"#0000FF\" pt 4 w linespoints\n");
          break;
        case 3: 
          fprintf(fp,"plot \"%s_%s.txt\" using ",prefix,suffix);
          fprintf(fp,"($1*3.6):($2*100) title 'Translation Error'"); 
          fprintf(fp," lc rgb \"#0000FF\" pt 4 w linespoints\n");
          break;
        case 4: 
          fprintf(fp,"plot \"%s_%s.txt\" using ",prefix,suffix);
          fprintf(fp,"($1*3.6):($2*57.3*100) title 'Rotation Error'"); 
          fprintf(fp," lc rgb \"#0000FF\" pt 4 w linespoints\n");
          break;
        case 5:
          fprintf(fp,"plot \"%s_ts.txt\" using ",prefix);
          fprintf(fp,"($1*3.6):($2*100) title 'Translation Error'"); 
          fprintf(fp," lc rgb \"#FF0000\" pt 4 w linespoints,");
          fprintf(fp,"\"%s_rs.txt\" using ",prefix);
          fprintf(fp,"($1*3.6):($2*57.3*100) title 'Rotation Error'"); 
          fprintf(fp," lc rgb \"#0000FF\" pt 4 w linespoints\n");
          break;
      }
      
      // close file
      fclose(fp);
      
      // run gnuplot => create png + eps
      sprintf(command,"cd \"%s\"; gnuplot \"%s\"",dir.c_str(),file_name);
      system(command);
    }
    
    // create pdf and crop
    sprintf(command,"cd \"%s\"; ps2pdf %s_%s.eps %s_%s_large.pdf",dir.c_str(),prefix,suffix,prefix,suffix);
    system(command);
    sprintf(command,"cd \"%s\"; pdfcrop %s_%s_large.pdf %s_%s.pdf",dir.c_str(),prefix,suffix,prefix,suffix);
    system(command);
    sprintf(command,"cd \"%s\"; rm %s_%s_large.pdf",dir.c_str(),prefix,suffix);
    system(command);
  }
}

void saveStats (const vector<errors> &err,const string &dir,const char* prefix) {

  double t_err = 0;
  double r_err = 0;

  // for all errors do => compute sum of t_err, r_err
  for (vector<errors>::const_iterator it=err.begin(); it!=err.end(); it++) {
    t_err += it->t_err;
    r_err += it->r_err;
  }

  // open file  
  FILE *fp = fopen((dir + "/stats.txt").c_str(), "a");

  // print a line divider if average
  if (strcmp(prefix, "avg") == 0)
    fprintf(fp,"----------------------------------------\n");
 
  // save errors
  double num = err.size();
  double avg_t_err = t_err/num*100;
  double avg_r_err = r_err/num*57.3*100;
  fprintf(fp,"%s\t%.6f\t%.6f\n",prefix,avg_t_err,avg_r_err);
  
  // close file
  fclose(fp);
}

bool eval (const string &result_dir) {

  // ground truth and result directories
  char buf[PATH_MAX + 1];
  char* res = realpath((script_dir +"/../../dataset/poses").c_str(), buf);
  if (res == NULL) {
    perror("realpath ground truth");
    return false;
  }
  string gt_dir         = buf;
  string error_dir      = result_dir + "/errors";
  string plot_path_dir  = result_dir + "/plot_path";
  string plot_error_dir = result_dir + "/plot_error";

  // total errors
  vector<errors> total_err;

  // for all sequences do
  for (int32_t i=0; i<=10; i++) {
   
    // file name
    char file_name[256];
    sprintf(file_name,"%02d.txt",i);
    
    // read ground truth and result poses
    vector<Matrix> poses_gt     = loadPoses(gt_dir + "/" + file_name);
    vector<Matrix> poses_result = loadPoses(result_dir + "/data/" + file_name);
   
    // print status
    cout << "Processing: " << file_name << ", poses: " 
      << poses_result.size() << "/" << poses_gt.size() << endl;
    
    // check for errors
    if (poses_gt.size()==0 || poses_result.size()!=poses_gt.size()) {
      cout << "ERROR: Couldn't read (all) poses of: " << file_name << endl;
      continue;
    }

    // compute sequence errors    
    vector<errors> seq_err = calcSequenceErrors(poses_gt,poses_result);
    saveSequenceErrors(seq_err,error_dir + "/" + file_name);
    
    // add to total errors
    total_err.insert(total_err.end(),seq_err.begin(),seq_err.end());
    
    // plot trajectory and compute individual stats
    // save + plot bird's eye view trajectories
    savePathPlot(poses_gt,poses_result,plot_path_dir + "/" + file_name);
    vector<int32_t> roi = computeRoi(poses_gt,poses_result);
    plotPathPlot(plot_path_dir,roi,i);

    // save + plot individual errors
    char prefix[16];
    sprintf(prefix,"%02d",i);
    saveErrorPlots(seq_err,plot_error_dir,prefix);
    plotErrorPlots(plot_error_dir,prefix);

    // save individual average stats
    saveStats(seq_err,result_dir,prefix);
  }
  
  // save + plot total errors + summary statistics
  if (total_err.size()>0) {
    char prefix[16];
    sprintf(prefix,"avg");
    saveErrorPlots(total_err,plot_error_dir,prefix);
    plotErrorPlots(plot_error_dir,prefix);
    saveStats(total_err,result_dir,prefix);
  }

  // success
  return true;
}

int32_t main (int32_t argc,char *argv[]) 
{
  // we need 2 or 4 arguments!
  if (argc != 2) {
    cout << "Usage: ./eval_odometry result_dir" << endl;
    return 1;
  }
  
  // get current directory path
  char* cmd = strdup(argv[0]);
  script_dir = dirname(cmd);
  char buf[PATH_MAX + 1];
  char* res = realpath(script_dir.c_str(), buf);
  if (res == NULL) {
    perror("realpath script_dir");
    return 1;
  }
  script_dir = buf;

  // read arguments
  string result_dir = argv[1];
  res = realpath(result_dir.c_str(), buf);
  if (res == NULL) {
    perror("realpath result");
    return 1;
  }
  result_dir = buf;

  // create stats output file
  FILE *fp = fopen((result_dir + "/stats.txt").c_str(), "w");
  fprintf(fp, "Seq #\tt_rel (%)\tr_rel (deg/100m)\n");
  fclose(fp);
  
  // run evaluation
  bool success = eval(result_dir);
  
  if (success)
    cout << "Succeed in running evaluation" << endl;
  else {
  	cout << "Failed to run evaluation" << endl;
  	return 1;
  }

  return 0;
}
