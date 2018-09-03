% script make_gps_2018_antarctica_Ground
%
% Makes the GPS files for 2018 Antarctica Ground field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2018_Antarctica_Ground');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

% ======================================================================
% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2018_Antarctica_Ground');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'arena';

if strcmpi(gps_source_to_use,'arena')
%% ARENA

%   year = 2018; month = 8; day = 31;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 0;

  year = 2018; month = 9; day = 1;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 0;

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
make_gps;

for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'arena')
    
    warning('Extrapolating GPS data: %s', out_fn);
    
    new_gps_time = [gps.gps_time(1)-10, gps.gps_time,gps.gps_time(end)+10];
    gps.lat = interp1(gps.gps_time,gps.lat,new_gps_time,'linear','extrap');
    gps.lon = interp1(gps.gps_time,gps.lon,new_gps_time,'linear','extrap');
    gps.elev = interp1(gps.gps_time,gps.elev,new_gps_time,'linear','extrap');
    gps.roll = interp1(gps.gps_time,gps.roll,new_gps_time,'linear','extrap');
    gps.pitch = interp1(gps.gps_time,gps.pitch,new_gps_time,'linear','extrap');
    gps.heading = interp1(gps.gps_time,gps.heading,new_gps_time,'linear','extrap');
    gps.gps_time = new_gps_time;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
end