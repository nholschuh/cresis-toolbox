// viterbi.cpp
//
// Layer-tracking program based on the Viterbi algorithm
//  for MUSIC-processed 2D and 3D data
//
// Authors: Victor Berger and John Paden
//           Center for Remote Sensing of Ice Sheets
//           2017-2018
//          Adapted from original code by Mingze Xu and David Crandall
//
// Changes to cost function (shifted exponential decay): Victor Berger and John Paden 2018
// Changes to cost function (geostatistical analysis): Victor Berger and John Paden 2019
//
// See also: viterbi.h
//
// mex -v -largeArrayDims viterbi.cpp

#include "viterbi.h"

//  Used to define unary cost of target at position x, y
double viterbi::unary_cost(int x, int y) { 
    
    // Merge layers when no ice exists
    if (f_mask[x] == 0 && y != f_sgt[x]) {
        return LARGE;
    }

    // Set cost to large if bottom is above surface
    if (y + 1 < f_sgt[x]) {
        return LARGE;
    }

    // Set cost to large if far from center ground truth (if present)
    // TODO[reece]: Distance is hardcoded here when comparing to ground truth
    // TODO[reece]: What is center ground truth? Apparently gt that is present in the center column of an echogram?
    if ((f_bgt != -1) && (x == f_mid) && (y < f_bgt - 20 || y > f_bgt + 20)) {
        return LARGE;
    }

    double cost = 0;

    // TODO[reece]: Compare binary costs with unary costs/multiple bin costs. Adjust accordingly. Perhaps use constants for easy nudging.
    // TODO[reece]: Weight such that manual points can be over-written by better points on occasion
    // Increase cost if far from extra ground truth
    for (int f = 0; f < (f_num_extra_tr / 2); ++f) {
        if (f_egt_x[f] == x) {
            cost += f_gt_weights[x] * 10 * sqr(((int)f_egt_y[f] - (int)y) * f_egt_weight);
            break;
        }
    }

    // TODO[reece]: Remove t and mu
    // Increase cost if near surface or surface multiple bin
    const int travel_time = f_sgt[x] - f_plane_bin;  // Between multiples
    int multiple_bin = (y - f_sgt[x]) / travel_time;
    int dist_to_bin = abs((y - f_sgt[x]) % travel_time);
    // If closer to next multiple, use that distance instead
    if (dist_to_bin > travel_time/2 && multiple_bin >= 0) {
      dist_to_bin = travel_time - dist_to_bin;
      multiple_bin++;
    }
    multiple_bin = multiple_bin < 0 ? 0 : multiple_bin;
    // Exponential formula. cost = 0 where dist_to_bin or multiple_bin == max. cost = MULTIPLE_BIN_WEIGHT when both are 0.
    // Here is an explanation of the formula: https://www.geogebra.org/3d/zy3f6mde
    // TODO[reece]: Make multiple_bin more influential than dist_to_bin
    double multiple_cost = (MULTIPLE_BIN_WEIGHT + multiple_cost_base)*pow(multiple_cost_base, (-dist_to_bin/(MULTIPLE_MAX_DIST+1)-multiple_bin/(MULTIPLE_MAX_NUM+1))) - multiple_cost_base;
    multiple_cost = multiple_cost < 0 ? 0 : multiple_cost;
    cost += multiple_cost;

    // Distance from nearest ice-mask
    // Probabilistic measurement
    // TODO[reece]: Account for size of cost matrix -- don't allow out of bounds
    //              Use min of dim - 1, y + ...
    int DIM = (std::isinf(f_mask_dist[x]) || f_mask_dist[x] >=  f_costmatrix_Y) ? f_costmatrix_Y - 1 : f_mask_dist[x];
    cost += f_costmatrix[f_costmatrix_X * DIM + y + 1 - f_sgt[x]];

    // Image magnitude
    cost -= f_image[encode(x, y)] * f_img_mag_weight;
    
    return cost;
}

// Returns Viterbi solution of optimal path
double* viterbi::find_path(void) { 
    start_col   = f_bounds[0];
    end_col     = f_bounds[1];
    num_col_vis = end_col - start_col;

    // Used in multiple cost calculation: Ensures correct range for outputs
    multiple_cost_base = sqrt(MULTIPLE_BIN_WEIGHT + .25) + .5;

    int *path = new int[f_row * num_col_vis];
    double path_prob[f_row], path_prob_next[f_row], index[f_row];
    
    for (int k = 0; k < f_col; ++k)
        f_result[k] = 0;

    for (int k = 0; k < f_row * num_col_vis; ++k) {
        path[k] = 0;
    }
    
    for (int k = 0; k < f_row; ++k) {
        path_prob[k] = 0;
        path_prob_next[k] = 0;
        index[k] = 0;
    }

    viterbi_right(path, path_prob, path_prob_next, index); 

    int encode;
    int viterbi_index     = calculate_best(path_prob);
    int idx               = end_col;
    f_result[end_col - 1] = (f_mask[end_col - 1] == 1 || std::isinf(f_mask[end_col - 1])) ? viterbi_index : f_sgt[end_col - 1];

    // Set result vector
    for (int k = start_col + 1; k <= end_col; ++k) {
        encode = vic_encode(viterbi_index, num_col_vis + start_col - k);
        viterbi_index = path[encode];
        f_result[idx - 2] = viterbi_index; 
        --idx;
        if (encode < 0 || idx < 2) {
            break;
        }
    }
    
    delete[] path; 
    return f_result;
}

// Select path with lowest overall cost
int viterbi::calculate_best(double *path_prob) {
    double min = LARGE;
    int viterbi_index = 0;
    for (int k = 0; k < f_row; ++k) {
        if (path_prob[k] < min) {
            min = path_prob[k];
            viterbi_index = k;
        }
    }
    return viterbi_index;
}

// Perform viterbi to the right
void viterbi::viterbi_right(int *path, double *path_prob, double *path_prob_next, double *index) {
    int idx = 0;
    bool next = 0;
    
    for (int col = start_col; col < end_col; ++col) {   
        if (idx >= f_row * num_col_vis || col >= f_col || col < 0) {
            continue;
        }
        // Have to add unary cost to first column before calculating best prev index for next column
        for (int row = 0; row < f_row; ++row) {
            if (col > start_col) {
                path[idx] = index[row];
            }
            if(next) {
                path_prob_next[row] += unary_cost(col, row);
            }
            else {
                path_prob[row] += unary_cost(col, row);
            }
            ++idx;
        }
        if (col >= end_col - 1) {
          // Allow addition of unary cost to final column but do not 
          // add binary cost for next column since there are no more columns
          continue;
        }
        
        if (!next) {
            dt_1d(path_prob, f_scale, path_prob_next, index, 0, f_row, f_smooth_slope[col-1]);
        }
        else {
            dt_1d(path_prob_next, f_scale, path_prob, index, 0, f_row, f_smooth_slope[col-1]);
        }
        next = !next;
    }
}

// MATLAB FUNCTION START
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {    
    if (nrhs < 13 || nrhs > 14 ||  nlhs != 1) {
        mexErrMsgTxt("Usage: [labels] = viterbi(input_img, surface_gt, bottom_gt, extra_gt, ice_mask, mean, var, egt_weight, smooth_weight, smooth_var, smooth_slope, bounds, viterbi_weight, repulsion, ice_bin_thr, mask_dist, costmatrix, scale, [plane_bin])\n"); 
    }

    // TODO[reece]: Organize inputs, fix counting, update usage ^
    
    // Input checking
    // input image ========================================================
    if (!mxIsDouble(prhs[0])) {
        mexErrMsgTxt("usage: image must be type double");
    }
    if (mxGetNumberOfDimensions(prhs[0]) != 2) {
        mexErrMsgTxt("usage: image must be a 2D matrix");
    }
    const int _row = mxGetM(prhs[0]);
    const int _col = mxGetN(prhs[0]);
    const double *_image = mxGetPr(prhs[0]);
    
    // surface ground truth ===============================================
    if (!mxIsDouble(prhs[1])) {
        mexErrMsgTxt("usage: sgt must be type double");
    }
    if (mxGetNumberOfElements(prhs[1]) != _col) {
        mexErrMsgTxt("usage: sgt must have numel(sgt)=size(image,2)");
    }
    const double *_surf_tr = mxGetPr(prhs[1]);
    
    // bottom ground truth ================================================
    if (!mxIsDouble(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1) {
        mexErrMsgTxt("usage: bgt must be a scalar of type double");
    }
    const double *t_bott_tr = mxGetPr(prhs[2]);
    
    // extra ground truth =================================================
    if (!mxIsDouble(prhs[3])) {
        mexErrMsgTxt("usage: egt must be type double");
    }
    const int _num_extra_tr = mxGetNumberOfElements(prhs[3]);
    if (_num_extra_tr % 2 != 0) {
        mexErrMsgTxt("usage: egt size must be a multiple of 2");
    }
    if (mxGetNumberOfElements(prhs[3]) > 0) {
        if (mxGetNumberOfDimensions(prhs[3]) != 2) {
            mexErrMsgTxt("usage: egt must be a 2xN array");
        }
    }
    const double *t_egt = mxGetPr(prhs[3]);
    
    // mask ===============================================================
    if (!mxIsDouble(prhs[4])) {
        mexErrMsgTxt("usage: mask must be type double");
    }
    if (mxGetNumberOfElements(prhs[4]) != _col) {
        mexErrMsgTxt("usage: mask must have numel(mask)=size(image,2)");
    }
    const double *_mask = mxGetPr(prhs[4]);
    
    // img_mag_weight ==========================================================
    if (!mxIsDouble(prhs[5]) || mxGetNumberOfElements(prhs[5]) != 1) {
        mexErrMsgTxt("usage: img_mag_weight must be scalar double");
    }
    const double _img_mag_weight = *(double *)mxGetPr(prhs[5]); 
    
    // extra ground truth weight ==========================================
    if (!mxIsDouble(prhs[6])) {
        mexErrMsgTxt("usage: extra gt weight must be type double");
    }
    if (mxGetNumberOfElements(prhs[6]) != 1) {
        mexErrMsgTxt("usage: extra gt weight must be a scalar");  
    }    
    const double *t_egt_weight    = mxGetPr(prhs[6]);
    const double _egt_weight = !t_egt_weight || t_egt_weight[0] < 0 ? EGT_WEIGHT : t_egt_weight[0];
    
    // smooth_slope =======================================================
    if (!mxIsDouble(prhs[7])) {
        mexErrMsgTxt("usage: smooth_slope must be type double");
    }
    if (_col-1 != mxGetNumberOfElements(prhs[7])) {
        mexErrMsgTxt("usage: smooth_slope must have numel(smooth_slope)=size(image,2)-1");
    }
    const double *_smooth_slope = mxGetPr(prhs[7]);
    
    // bounds =============================================================
    ptrdiff_t _bounds[2];
    if (mxGetNumberOfElements(prhs[8]) != 0) {
        if (!mxIsInt64(prhs[8])) {
            mexErrMsgTxt("Usage: bounds must be type int64");
        }
        if (mxGetNumberOfElements(prhs[8]) != 2) {
            mexErrMsgTxt("Usage: bounds must be a 2 element vector");
        }
        ptrdiff_t *tmp = (ptrdiff_t*)mxGetPr(prhs[8]);
        _bounds[0] = tmp[0];
        _bounds[1] = tmp[1];
        if (_bounds[0] < 0) {
            _bounds[0] = 0;
        }
        if (_bounds[1] < 0) {
            _bounds[1] = _col;
        }
        if (_bounds[0] > _col) {
            mexErrMsgTxt("Usage: bounds[0] <= size(input,2)");
        }
        if(_bounds[1] > _col) {
            mexErrMsgTxt("Usage: bounds[1] <= size(input,2)");
        }
        if(_bounds[1] < _bounds[0]) {
            mexErrMsgTxt("Usage: bounds[1] must be greater than bounds[0]");
        }
    }
    else {
        // Default setting is to process all columns
        _bounds[0] = 0;
        _bounds[1] = _col;
    }
    
    // gt_weight ======================================================
    if (!mxIsDouble(prhs[9])) {
        mexErrMsgTxt("usage: gt_weight must be type double");
    }
    if (mxGetNumberOfElements(prhs[9]) != _col) {
        mexErrMsgTxt("usage: gt_weight must have numel(gt_weight)=size(image,2)");
    }   
    const double *_gt_weights  = mxGetPr(prhs[9]);
    
    // mask_dist ==========================================================
    if (!mxIsDouble(prhs[10])) {
        mexErrMsgTxt("usage: mask_dist must be type double");
    }
    if (mxGetNumberOfElements(prhs[10]) != _col) {
        mexErrMsgTxt("usage: mask_dist must have numel(mask_dist)=size(image,2)");
    }   
    const double *_mask_dist = mxGetPr(prhs[10]);
    
    // costmatrix =========================================================
    if (!mxIsDouble(prhs[11])) {
        mexErrMsgTxt("usage: costmatrix must be type double");
    } 
    const double *_costmatrix = mxGetPr(prhs[11]);
    const int _costmatrix_X = mxGetM(prhs[11]);
    const int _costmatrix_Y = mxGetN(prhs[11]);
    
    // scale ===================================================
    if (!mxIsDouble(prhs[12])) {
        mexErrMsgTxt("usage: scale must be type double");
    }
    if (mxGetNumberOfElements(prhs[12]) != 1) {
        mexErrMsgTxt("usage: scale must be scalar");
    }   
    const double _scale = *(double *)mxGetPr(prhs[12]);
    
    // plane bin ===================================================
    int _plane_bin = 0;
    if (nrhs >= 14) {
      if (!mxIsInt64(prhs[13])) {
          mexErrMsgTxt("usage: plane bin must be type int64");
      }
      _plane_bin = *(int *)mxGetPr(prhs[13]);
    }
    
    // ====================================================================
    
    // Initialize surface layer array
    int _sgt[_col];
    for (int k = 0; k < _col; ++k) {
        _sgt[k] = (int)_surf_tr[k];
    }
    
    // Initialize variables to default values if temporary values not set
    const int _mid = floor(_col / 2);
    const int _bgt = ((t_bott_tr) ? (t_bott_tr[0] > 0 ? round(t_bott_tr[0]) : -1) : -1);
    
    double _egt_x[(_num_extra_tr / 2)], _egt_y[(_num_extra_tr / 2)];
    for (int p = 0; p < (_num_extra_tr / 2); ++p) {
        _egt_x[p] = round(t_egt[(p * 2)]);
        _egt_y[p] = round(t_egt[(p * 2) + 1]);
    }
    
    // Allocate output    
    plhs[0] = mxCreateDoubleMatrix(1, _col, mxREAL);
    double *_result = mxGetPr(plhs[0]); 
    viterbi obj(_row, _col, _image, _sgt, _bgt, _mask, _img_mag_weight, _mid, 
        _egt_weight, _smooth_slope, _bounds, _num_extra_tr, _egt_x, _egt_y, _gt_weights,
        _mask_dist, _costmatrix, _costmatrix_X, _costmatrix_Y,
        _scale, _plane_bin, _result); 
}
