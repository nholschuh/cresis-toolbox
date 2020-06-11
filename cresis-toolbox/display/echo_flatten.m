function [mdata] = echo_flatten(mdata,layer_params)
% [mdata] = echo_flatten(mdata,layer_params)
%
% Shifts columns up/down in echogram in order to flatten one or more 1D
% layers in the data. Defaults to flattening the surface stored in
% CSARP_layer if no layer_params given. If a single layer is given, all
% bins are shifted up and down the same amount. If more than one layer is
% given, then bins are adjusted according to a piecewise linear polynomial
% between each of the layers and nearest neighbor for extrapolating above
% and below the top and bottom layers respectively. If a slope field is
% given, then the bin shifts are made from left to right. Interpolation is
% used for the shifts, so oversampling (e.g. 2x) in the fast-time domain is
% recommended for best results when the shifts are non-integer. To
% compensate for elevation, just pass in a custom layer_params similar to
% opsCopyLayers and set the twtt = elev*c/2.
%
% INPUTS:
%
% mdata: echogram structure from an echogram file (e.g. returned from
% echo_load)
%
% layer_params: struct array controlling how the flattening is done if a
% character, then assumes it is a slope field file path (ct_filename_out
% will be used to determine filepath)
%
% interp_method: string containing 'linear' or 'interpft' (default is
% 'linear'). interpft is not recommended unless the data are Nyquist
% sampled (usually this means 2x interpolation in the fast-time before
% power detection occurs).
%
% OUTPUTS:
%
% mdata: echogram structure (t0 and dt fields added)
%
% Examples:
%
% param = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'),'20200107_01');
% mdata = echo_load(param,'standard',1);
%
% Author: John Paden, Reece Mathews
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

physical_constants;

if isstruct(mdata)
  data = mdata.Data;
  
  % TODO[reece]: Elevation should be passed in as layer_param
else
  data = mdata;
end

Nx = size(data, 2);

if ~exist('layer_params','var') || isempty(layer_params)
    % TODO[reece]: Default to surface
elseif isa(layer_params, 'double')
    slope = layer_params;
else
    % TODO[reece]: When single layer given, shift bins to flatten layer
    % TODO[reece]: When multiple layers are given, shift bins to flatten
    %              all layers (nearest neighbor above and below top and
    %              bottom)
    % TODO[reece]: Slope field shifts bins left to right?
end

% TODO[reece]: Convert elevation to bins

slope_range = slope - min(slope);

mdata = nan(size(data, 1) + floor(max(slope_range)), Nx);

for c = 1:Nx
  mdata(:, c) = interp1(1:size(data, 1), data(:, c), (1:size(data, 1) + max(slope_range)) - slope_range(c));
end

% TODO[reece]: Why does the nearest neighbor seem to sometimes come from
%              the other end of the previous column?
% TODO[reece]: Allow user to choose to interp finite or pass a default
%              value
mdata = interp_finite(mdata, nan, 'nearest');
