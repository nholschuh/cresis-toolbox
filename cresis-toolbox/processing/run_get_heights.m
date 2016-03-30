% script run_get_heights
%
% Script for running get_heights (usually just used for debugging).
%
% Authors: John Paden
%
% See also: run_master.m, master.m, run_get_heights.m, get_heights.m,
%   get_heights_task.m

dbstop if error


% =====================================================================
% Debug Setup
% =====================================================================
param = read_param_xls(ct_filename_param('snow_param_2010_Antarctica_DC8.xls'),'20101113_07');

clear('param_override');
param_override.sched.type = 'no scheduler';
param_override.sched.rerun_only = true;

% Input checking
if ~exist('param','var')
  error('A struct array of parameters must be passed in\n');
end
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

get_heights(param,param_override);

return;