% script run_all_create_season_layerdata_files
% run_all_create_season_layerdata_files
%
% Creates a season layer file containing the lat, lon. The imb.picker loads
% this file when plotting flightlines without OPS. Loading all the
% individual CSARP_layerData files would be slow so this helps speed up the
% loading.
%
% Output filenames are of the form:
% .../csarp_support/layer/layer_SYSTEM_SEASONNAME.mat
% For example:
% .../csarp_support/layer/layer_accum_2018_Antarctica_TObas.mat
%
% Output file:
% These variables are all 1 by Nx vectors of the same length, segments are
% terminated with NaN:
%   bottom: ice bottom two way travel time in seconds
%   elev: elevation in meters
%   frm_id: full frame ID 2019020401123
%   lat: latitude in degrees
%   lon: longitude in degrees
%   surf: ice surface two way travel time in seconds
%   quality: integer enumeration of bottom quality, 1=good, 2=moderate,
%     3=poor or derived from another source
%  frm_info: structure containing frame information
%    .frm_id: Nfrm element vector of frame IDs
%    .start_gps_time: Nfrm element vector of start GPS times for each frame
%    .stop_gps_time: Nfrm element vector of stop GPS times for each frame
%   
% Author: John Paden, Rohan Choudhari
%
% See also: imb.run_all_create_season_layerdata_files.m,
% imb.create_season_layerdata_files.m

%% User Settings
% =========================================================================

% Select seasons in run_all:
run_all;

%% User Settings: Select layers
% First layer is the "surface"
% Second layer is the "bottom"
if 1
  layer_params = struct('name','surface');
  layer_params.source = 'layerdata';
  % layer_params.layerdata_source = 'CSARP_post/layerData';
  layer_params.existence_check = true;
  layer_params(2).name = 'bottom';
  layer_params(2).source = 'layerdata';
  % layer_params(2).layerdata_source = 'CSARP_post/layerData';
  layer_params(2).existence_check = false;
else
  % HACK!!!
  keyboard
  layer_params = struct('name','surface');
  layer_params.source = 'layerdata';
  layer_params(1).layerdata_source = 'layerData_koenig';
  layer_params(2).existence_check = true;
  layer_params(1).fix_broken_layerdata = true; % Found some bad files
  layer_params(2).name = 'bottom';
  layer_params(2).source = 'layerdata';
  layer_params(2).layerdata_source = 'layerData_koenig';
  layer_params(2).existence_check = false;
  layer_params(2).fix_broken_layerdata = true; % Found some bad files
  for lay_idx=2:30
    layer_params(lay_idx+1).name = sprintf('Koenig_%d',lay_idx);
    layer_params(lay_idx+1).source = 'layerdata';
    layer_params(lay_idx+1).layerdata_source = 'layerData_koenig';
    layer_params(lay_idx+1).existence_check = false;
    layer_params(lay_idx+1).fix_broken_layerdata = true; % Found some bad files
  end
end

param_override = [];
param_override.create_season_layerdata_files.layer_params = layer_params;

%% Automated Section
% =========================================================================
% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Loop to process each season
for param_idx = 1:length(param_fns)
  
  % Initialize variables to be extracted from layers
  lat = [];
  lon = [];
  frm_id = [];
  surf = [];
  bottom = [];
  elev = [];
  quality = [];
  frm_info = [];
  frm_info.frm_id = [];
  frm_info.start_gps_time = [];
  frm_info.stop_gps_time = [];
  
  % Read in parameter spreadsheet
  param_fn = ct_filename_param(param_fns{param_idx});
  fprintf('Reading %s\n', param_fn);
  params = read_param_xls(param_fn,'');
  
  if isempty(params)
    continue;
  end
  
  % Run all segments (except "do not process")
  if 1
    params = ct_set_params(params,'cmd.generic',1);
    params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
  else
    % HACK!!!
    keyboard
    params = ct_set_params(params,'cmd.generic',0);
    params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
  end
  
  %% Load each segment
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      fprintf('%s\tdo not process\n', param.day_seg);
      continue;
    end
    
    tmp = [];
    try
      param.cmd.frms = [];
      [tmp.lat,tmp.lon,tmp.frm_id,tmp.elev,tmp.surf,tmp.bottom,tmp.quality,tmp.frm_info,gps_source] = imb.create_season_layerdata_files(param,param_override);
    catch ME
      fprintf('%s\terror!!!\t%s\n', param.day_seg, ME.getReport);
      continue;
    end
    
    % Concatenate data
    fprintf('%s\tloaded\t%d\t%d\n', param.day_seg, length(tmp.lat), sum(~isnan(tmp.bottom)));
    lat = [lat tmp.lat NaN];
    lon = [lon tmp.lon NaN];
    % Store full frame ID number 20190204_01_003 --> 2019020401003
    frm_id = [frm_id tmp.frm_id NaN];
    elev = [elev tmp.elev NaN];
    surf = [surf tmp.surf NaN];
    bottom = [bottom tmp.bottom NaN];
    quality = [quality tmp.quality NaN];

    % Store frame GPS time boundaries
    frm_info.frm_id = [frm_info.frm_id tmp.frm_info.frm_id];
    frm_info.start_gps_time = [frm_info.start_gps_time tmp.frm_info.start_gps_time];
    frm_info.stop_gps_time = [frm_info.stop_gps_time tmp.frm_info.stop_gps_time];
  end
  
  if isempty(lat)
    %% No data error
    error('There is no data available and so no season layer file can be saved.');
    
  else
    %% Save output for this season
    out_fn_dir = ct_filename_support(param,'layer','');
    out_fn_name = sprintf('layer_%s_%s_%s.mat', param.post.ops.location, ct_output_dir(param.radar_name), param.season_name);
    out_fn = fullfile(out_fn_dir,out_fn_name);
    fprintf('  Saving %s\n\n', out_fn);
    if ~exist(out_fn_dir,'dir')
      mkdir(out_fn_dir);
    end
    file_type = 'layer_season';
    file_version = '1';
    param = struct('day_seg',param.day_seg,'radar_name',param.radar_name, ...
      'season_name',param.season_name,'sw_version',param.sw_version);
    ct_save(out_fn,'bottom','elev','file_type','file_version','frm_id','frm_info','gps_source','lat','lon','param','quality','surf');
  end
end
