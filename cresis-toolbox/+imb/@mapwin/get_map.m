function get_map(obj,hObj,event)
% get_map(obj,hObj,event)
%
% This is the callback function which is called when the preference
% window "OK" button is pressed and the prefwin "StateChange" event occurs.

%% Determine map source
if strcmp('google_map', obj.map_pref.settings.map_name)
  obj.map.source = 1;
  obj.map.scale = 1;
elseif strcmp('blank_map', obj.map_pref.settings.map_name)
  % blank map selected
  obj.map.source = 2;
  obj.map.scale = 1e3;
else
  % OPS map selected
  obj.map.source = 0;
  obj.map.scale = 1e3;
end
obj.map.proj = imb.get_proj_info(obj.map_pref.settings.map_zone);

%% Determine flight line source
if strcmp('OPS',obj.map_pref.settings.flightlines(1:3))
  % OPS flight line source
  obj.map.fline_source = 0;
else
  % Season layer data source
  obj.map.fline_source = 1;
end

%% Check which settings have changed
if ~strcmpi(obj.cur_map_pref_settings.system, obj.map_pref.settings.system)
  system_changed = true;
else
  system_changed = false;
end

seasons_changed = false;
if length(obj.cur_map_pref_settings.seasons) ~= length(obj.map_pref.settings.seasons)
  seasons_changed = true;
else
  for idx = 1:length(obj.cur_map_pref_settings.seasons)
    if ~any(strcmp(obj.cur_map_pref_settings.seasons{idx},obj.map_pref.settings.seasons))
      seasons_changed = true;
    end
  end
end

if ~strcmpi(obj.cur_map_pref_settings.map_name,obj.map_pref.settings.map_name)
  map_name_changed = true;
else
  map_name_changed = false;
end

if ~strcmpi(obj.cur_map_pref_settings.flightlines,obj.map_pref.settings.flightlines)
  flightlines_changed = true;
else
  flightlines_changed = false;
end

if ~strcmpi(obj.cur_map_pref_settings.map_zone,obj.map_pref.settings.map_zone)
  map_zone_changed = true;
else
  map_zone_changed = false;
end

if ~system_changed && ~seasons_changed && ~map_name_changed && ~map_zone_changed && ~flightlines_changed
  % get_map at most only needs to update echogram sources, layers, layer
  % source, and/or layerdata source
  obj.cur_map_pref_settings.sources = obj.map_pref.settings.sources;
  obj.cur_map_pref_settings.layers = obj.map_pref.settings.layers;
  obj.cur_map_pref_settings.layer_source = obj.map_pref.settings.layer_source;
  obj.cur_map_pref_settings.layer_data_source = obj.map_pref.settings.layer_data_source;
  figure(obj.h_fig);
  obj.save_default_params();
  return;
end

%% Copy current preference window settings over
obj.cur_map_pref_settings = obj.map_pref.settings;

%% Update map selection (also called at startup)
% =================================================================
flightlines = obj.cur_map_pref_settings.flightlines;
map_name = obj.cur_map_pref_settings.map_name;
map_zone = obj.cur_map_pref_settings.map_zone;
fprintf('Loading and plotting map %s:%s (%s)\n', map_zone, map_name, datestr(now,'HH:MM:SS'));

if obj.map.source == 0 || obj.map.fline_source == 0
  opsCmd;
  
  if obj.map.fline_source == 0
    %% Create season and group ID strings for OPS flightline requests
    
    % 1. create seasons viewparam
    if ~isempty(obj.cur_map_pref_settings.seasons)
      season_names = obj.cur_map_pref_settings.seasons;
      
      % convert season_names to a string for concatenation
      for sidx = 1:size(season_names,2)
        if sidx < size(season_names,2) && size(season_names,2) ~= 1
          season_names{sidx}=['''' season_names{sidx} '''%5C,'];
        else
          season_names{sidx}=['''' season_names{sidx} ''''];
        end
      end
      season_names = cell2mat(season_names);
      obj.ops.seasons_as_string = season_names;
      obj.ops.seasons_modrequest = strcat('season_name:',season_names,';');
    else
      obj.ops.seasons_modrequest = '';
      obj.ops.seasons_as_string = '';
    end
    
    % 2. create season_group_ids viewparam
    if ~isempty(obj.map_pref.ops.profile)
      eval(sprintf('season_group_ids = obj.map_pref.ops.profile.%s_season_group_ids'';',obj.cur_map_pref_settings.system))
      
      if isempty(season_group_ids)
        season_group_ids = {'1'};
      end
      
      % convert season_group_ids to a string for concatenation
      for sidx = 1:size(season_group_ids,2)
        if sidx < size(season_group_ids,2) && size(season_group_ids,2) ~= 1
          season_group_ids{sidx}=['' int2str(season_group_ids{sidx}) '%5C,'];
        else
          season_group_ids{sidx}=['' int2str(season_group_ids{sidx}) ''];
        end
      end
      season_group_ids = cell2mat(season_group_ids);
      obj.ops.season_group_ids_as_string = season_group_ids;
      obj.ops.season_group_ids_modrequest = strcat('season_group_ids:',season_group_ids);
      
    else
      obj.ops.season_group_ids_modrequest = '';
      obj.ops.season_group_ids_as_string = '1';
    end
  end
  
end

if obj.map.source == 0
  %% Setup OPS map and flightlines for OPS maps
  
  % Update axes labels
  xlabel(obj.map_panel.h_axes,'X (km)');
  ylabel(obj.map_panel.h_axes,'Y (km)');
  
  % Rename to layer for readability
  layer = obj.map_pref.ops.wms_capabilities.Layer;
  
  % Setup OPS map
  wms_map_layer = layer.refine(map_name,'matchType','exact');
  
  % Setup OPS flightlines if enabled
  wms_flightline_layer = [];
  if obj.map.fline_source == 0
    % Setup OPS flightlines
    if strcmpi(flightlines,'OPS Flightlines') && ~isempty(layer.refine('line_paths'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_line_paths',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Quality Flightlines') && ~isempty(layer.refine('data_quality'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_quality',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Coverage Flightlines') && ~isempty(layer.refine('data_coverage'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_coverage',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Crossover Errors') && ~isempty(layer.refine('crossover_errors'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_crossover_errors',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Bed Elevation') && ~isempty(layer.refine('data_elevation'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_elevation',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    end
    
    % Get request
    obj.ops.request = WMSMapRequest([wms_flightline_layer wms_map_layer]);
  else
    obj.ops.request = WMSMapRequest(wms_map_layer);
  end
  
  % Set projection code and default map bounds
  if strcmp(map_zone,'arctic')
    obj.ops.request.CoordRefSysCode = 'EPSG:3413';
    obj.map.xaxis_default = [-1500000 1500000]/1e3;
    obj.map.yaxis_default = [-4000000 0]/1e3;
  else
    obj.ops.request.CoordRefSysCode = 'EPSG:3031';
    obj.map.xaxis_default = [-3400000 3400000]/1e3;
    obj.map.yaxis_default = [-3400000 3400000]/1e3;
  end
  
elseif obj.map.source == 1
  %% Get Map: Google
  
  % Setup the Google map
  if isempty(obj.google.map)
    obj.google.map = google_map();
  end
  
  % Update axes labels
  xlabel(obj.map_panel.h_axes,'Lon (deg)');
  ylabel(obj.map_panel.h_axes,'Lat (approx. deg)');
  
  wms_flightline_layer = [];
  if obj.map.fline_source == 0
    % Rename to layer for readability
    layer = obj.map_pref.ops.wms_capabilities.Layer;
    % Setup OPS flightlines
    if strcmpi(flightlines,'OPS Flightlines') && ~isempty(layer.refine('line_paths'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_line_google',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Quality Flightlines') && ~isempty(layer.refine('data_quality'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_quality_google',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Coverage Flightlines') && ~isempty(layer.refine('data_coverage'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_coverage_google',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Crossover Errors') && ~isempty(layer.refine('crossover_errors'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_crossover_errors_google',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Bed Elevation') && ~isempty(layer.refine('data_elevation'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_elevation_google',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    end
    
    % Get request
    obj.ops.request = WMSMapRequest(wms_flightline_layer);
    % Set projection code
  else
    obj.ops.request = [];
  end
  
  obj.ops.request.CoordRefSysCode = 'EPSG:3857';
  % Set default map bounds
  if strcmp(map_zone,'arctic')
    obj.map.xaxis_default = [-1500000 1500000]/1e3;
    obj.map.yaxis_default = [-4000000 0]/1e3;
  else
    obj.map.xaxis_default = [-3400000 3400000]/1e3;
    obj.map.yaxis_default = [-3400000 3400000]/1e3;
  end
  if strcmp(map_zone,'arctic')
    [obj.map.xaxis_default(1),obj.map.xaxis_default(2),obj.map.yaxis_default(1),obj.map.yaxis_default(2)] ...
      = google_map.greenland();
  else
    [obj.map.xaxis_default(1),obj.map.xaxis_default(2),obj.map.yaxis_default(1),obj.map.yaxis_default(2)] ...
      = google_map.antarctica();
  end
  obj.map.yaxis_default = sort(256-obj.map.yaxis_default);
  
elseif obj.map.source == 2
  %% Setup blank map and flightlines for OPS maps
  
  % Update axes labels
  xlabel(obj.map_panel.h_axes,'X (km)');
  ylabel(obj.map_panel.h_axes,'Y (km)');
  
  % Setup OPS flightlines if enabled
  wms_flightline_layer = [];
  if obj.map.fline_source == 0
    % Rename to layer for readability
    layer = obj.map_pref.ops.wms_capabilities.Layer;
    % Setup OPS flightlines
    if strcmpi(flightlines,'OPS Flightlines') && ~isempty(layer.refine('line_paths'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_line_paths',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Quality Flightlines') && ~isempty(layer.refine('data_quality'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_quality',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Coverage Flightlines') && ~isempty(layer.refine('data_coverage'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_coverage',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Crossover Errors') && ~isempty(layer.refine('crossover_errors'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_crossover_errors',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    elseif strcmpi(flightlines,'OPS Bed Elevation') && ~isempty(layer.refine('data_elevation'))
      wms_flightline_layer = layer.refine(sprintf('%s_%s_data_elevation',map_zone,obj.cur_map_pref_settings.system),'MatchType','exact');
    end
    
    % Get request
    obj.ops.request = WMSMapRequest(wms_flightline_layer);
  else
    obj.ops.request = [];
  end
  
  % Set projection code and default map bounds
  if strcmp(map_zone,'arctic')
    obj.ops.request.CoordRefSysCode = 'EPSG:3413';
    obj.map.xaxis_default = [-1500000 1500000]/1e3;
    obj.map.yaxis_default = [-4000000 0]/1e3;
  else
    obj.ops.request.CoordRefSysCode = 'EPSG:3031';
    obj.map.xaxis_default = [-3400000 3400000]/1e3;
    obj.map.yaxis_default = [-3400000 3400000]/1e3;
  end
end

if obj.map.fline_source == 1
  
  %% Plot flightlines
  obj.layerdata.x = [];
  obj.layerdata.y = [];
  obj.layerdata.frm_id = [];
  obj.layerdata.season_idx = [];
  obj.layerdata.frm_info = struct('frm_id',{},'start_gps_time',{},'stop_gps_time',{});
  
  % Looping through the seasons
  layer_fn_dir = ct_filename_support(struct('radar_name','rds'),'layer','');
  for season_idx = 1:length(obj.cur_map_pref_settings.seasons)
    %Loading the season layerdata files
    layer_fn_name = sprintf('layer_%s_%s.mat', obj.cur_map_pref_settings.map_zone, obj.cur_map_pref_settings.seasons{season_idx});
    layer_fn = fullfile(layer_fn_dir,layer_fn_name);
    S = load(layer_fn);
    if obj.map.source == 1
      [x,y] = google_map.latlon_to_world(S.lat, S.lon); y = 256-y;
    else
      [x,y] = projfwd(obj.map.proj, S.lat, S.lon);
    end
    x = x/obj.map.scale; y = y/obj.map.scale;
    obj.layerdata.x = [obj.layerdata.x x];
    obj.layerdata.y = [obj.layerdata.y y];
    obj.layerdata.frm_id = [obj.layerdata.frm_id S.frm_id];
    obj.layerdata.season_idx = [obj.layerdata.season_idx season_idx*ones(size(x))];
    obj.layerdata.frm_info(season_idx) = S.frm_info;
    
    % Plot flight lines
    set(obj.map_panel.h_flightline,'XData',obj.layerdata.x,'YData',obj.layerdata.y);
  end
  
else
  set(obj.map_panel.h_flightline,'XData',NaN,'YData',NaN);
end

% Turn map axes on if this is the first time a map is being loaded
set(obj.map_panel.h_axes,'Visible', 'on');
set(obj.map_panel.h_image,'Visible', 'on');

% Set map bounds to default if this is the first time a map is being loaded
% or if the projection changed
if isempty(obj.map.xaxis) || ~strcmpi(obj.ops.request.CoordRefSysCode,obj.map.CoordRefSysCode)
  obj.map.xaxis = obj.map.xaxis_default;
  obj.map.yaxis = obj.map.yaxis_default;
  obj.map.CoordRefSysCode = obj.ops.request.CoordRefSysCode;
end

obj.query_redraw_map(obj.map.xaxis(1),obj.map.xaxis(end),obj.map.yaxis(1),obj.map.yaxis(end));

% Reset selection
obj.map.sel.frm_str = ''; % Current frame name
obj.map.sel.seg_id = []; % Current segment ID (Database ID for OPS layer source, index into obj.cur_map_pref_settings.seasons for layerdata source)
obj.map.sel.season_name = ''; % Current season name
obj.map.sel.radar_name = ''; % Current radar name
% Update current frame selection map plot
set(obj.map_panel.h_cur_sel,{'XData','YData'},{[],[]});
% Change map title to the currently selected frame
set(obj.top_panel.flightLabel,'String',obj.map.sel.frm_str);

% Redraw table to ensure everything is the right size
table_draw(obj.table);

figure(obj.h_fig);

obj.save_default_params();

fprintf('  Done (%s)\n', datestr(now));
