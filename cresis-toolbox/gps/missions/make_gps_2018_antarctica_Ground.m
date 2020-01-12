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
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

% gps_source_to_use = 'arena';
% gps_source_to_use = 'arena_cpu_time';
gps_source_to_use = 'trimble_cpu_time';

if strcmpi(gps_source_to_use,'arena')
  %% ARENA
  
  %   year = 2018; month = 10; day = 12;
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  %   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %   file_type{file_idx} = 'arena';
  %   params{file_idx} = struct('year',2018,'time_reference','utc');
  %   gps_source{file_idx} = 'arena-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  %   sync_file_type{file_idx} = 'arena';
  %   sync_params{file_idx} = struct('time_reference','utc');
  
  %   year = 2018; month = 10; day = 14;
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  %   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %   file_type{file_idx} = 'arena';
  %   params{file_idx} = struct('year',2018,'time_reference','utc');
  %   gps_source{file_idx} = 'arena-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  %   sync_file_type{file_idx} = 'arena';
  %   sync_params{file_idx} = struct('time_reference','utc');
  
  year = 2018; month = 10; day = 15;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',2018,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
elseif strcmpi(gps_source_to_use,'arena_cpu_time')
  correction = make_gps_2018_antarctica_Ground_cpu_time(in_base_path);
    
%   year = 2018; month = 12; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('UA_%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
%   sync_file_type{file_idx} = 'arena_cpu_time';
%   sync_params{file_idx} = struct('time_reference','utc', ...
%     'cpu_time_fn',fullfile(in_base_path,sprintf('cpu_time_%04d%02d%02d.csv',year,month,day)));
    
  year = 2018; month = 12; day = 19;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'UA_LOG',sprintf('UA_%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
  sync_file_type{file_idx} = 'arena_cpu_time';
  sync_params{file_idx} = struct('time_reference','utc', ...
    'cpu_time_correction',correction);

elseif strcmpi(gps_source_to_use,'trimble_cpu_time')
  correction = make_gps_2018_antarctica_Ground_cpu_time(in_base_path);

  year = 2018; month = 12; day = 19;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'GNSS_SM111'),'','','iceradar_SM111_areaABC.pos');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps','headerlines',17,'format_str','%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f');
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','f1','f2','f3','f4','f5','f6','f7','f8','f9','f10'};
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'brice-final20190404';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
  sync_file_type{file_idx} = 'arena_cpu_time';
  sync_params{file_idx} = struct('time_reference','utc', ...
    'cpu_time_correction',correction);
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
make_gps;

for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn,'gps_source');
  if regexpi(gps.gps_source,'arena')
    % Extrapolation is necessary because GPS data starts after/stops before
    % the beginning/end of the radar data.
    warning('Extrapolating arena GPS data: %s', out_fn);
    gps = load(out_fn);
    
    if length(gps.lat) >= 2
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
  
  if regexpi(out_fn,'201810XX')
    % Fake GPS for testing
    warning('Faking GPS data: %s', out_fn);
    gps = load(out_fn);
    
    velocity = 4;
    gps.lat = -75.5 - (gps.gps_time-gps.gps_time(1))*velocity/111111;
    gps.lon(:) = -106.75;
    gps.elev(:) = 500;
    gps.heading(:) = -pi;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
  
end
