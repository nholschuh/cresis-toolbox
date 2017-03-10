% script make_gps_2017_greenland_P3
%
% Makes the GPS files for 2017 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2017_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2017_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
% gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'NMEA')
  
    year = 2017; month = 3; day = 9;
    file_idx = file_idx + 1;
    in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'NMEA';
    params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
    gps_source{file_idx} = 'nmea-field';
    sync_flag{file_idx} = 0;

  
elseif strcmpi(gps_source_to_use,'ATM-field')
  
  year = 2017; month = 2; day = 26;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'ATM')
  % Just some simple code to automate creation of the code in this section:
  %
  %   ATM_fns = get_filenames(in_base_path,'','','.out');
  %   fn_dates = [];
  %   for idx = 1:length(ATM_fns)
  %     fn = ATM_fns{idx};
  %     [~,fn_name] = fileparts(fn);
  %     if strcmpi(fn_name(1:2),'BD')
  %       fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(9:11), fn_name(7:8), fn_name(12:13)));
  %     elseif strcmpi(fn_name(1:2),'00')
  %       fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(13:15), fn_name(11:12), fn_name(16:17)));
  %     end
  %   end
  %   fn_dates = sort(fn_dates);
  %   for idx = 1:length(fn_dates)
  %     [year,month,day] = datevec(fn_dates(idx));
  %     fprintf('year = %d; month = %d; day = %d;\n', year, month, day);
  %   end
  % !!!   ALL data, including test flights, from Oct 7th to OCT29th are in
  % GPS time. From Nov2nd to Nov 22nd the data is in UTC time.
  
  year = 2017; month = 2; day = 26;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_X';
  sync_flag{file_idx} = 0;
  
end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
make_gps;