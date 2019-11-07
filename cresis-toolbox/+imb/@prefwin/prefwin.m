classdef (HandleCompatible = true) prefwin < handle
% Map Window for imb.picker
  
  properties
    % GUI variables
    h_fig
    h_gui

    % default_params = Default parameters loaded from default parameters file
    %   These parameters are updated every time Ok button is pushed and
    %   will be written back to the default parameters file on exit by mapwin.
    default_params
    
    unique_systems % Cell array of unique systems
    systems % Cell array of systems
    seasons % Cell array of seasons
    locations % Cell array of locations
    flightlines % Cell array of flightlines
    
    ops % OPS information
    % ops.profile % Cell array of profiles
    % ops.layers % Cell array of layers
    % ops.wms; % WMS capabilities from OPS, read in during create_ui
    % ops.wms_capabilities; % WMS capabilities from OPS, read in during create_ui
    
    % Selections during most recent call to okPB_callback (these fields
    % are set during the call to okPB_callback). These represent the active
    % settings mapwin is using.
    settings

  end
  
  properties (SetAccess = private, GetAccess = private)
  end
  
  events
    StateChange
  end
  
  methods
    function obj = prefwin(h_fig,default_params)
      %%% Pre Initialization %%%
      % Any code not using output argument (obj)
      if nargin == 0 || isempty(h_fig)
        h_fig = figure;
      else
        figure(h_fig);
      end
      
      %%% Post Initialization %%%
      % Any code, including access to object
      fprintf('Creating preference window (%s)\n', datestr(now,'HH:MM:SS'));
      obj.h_fig = h_fig;
      obj.default_params = default_params;
      obj.settings.flightlines = 'Regular Flightlines';
      obj.settings.map_name = [];
      obj.settings.map_zone = [];
      obj.settings.sources = {};
      obj.settings.system = [];
      obj.settings.seasons = {};
      obj.settings.layers = {};
    
      try
        create_ui(obj);
      catch ME
        delete(obj);
        rethrow(ME);
      end
      fprintf('  Done (%s)\n', datestr(now,'HH:MM:SS'));
    end
    
    function delete(obj)
      % Delete the preference window
      try
        delete(obj.h_fig);
      end
      % Delete the GUI subclasses
      try
        delete(obj.h_gui.h_layers);
      end
      try
        delete(obj.h_gui.h_seasons);
      end
    end
    
    close_win(obj,varargin);
    create_ui(obj,param);
    addPB_callback(obj,hObj,event);
    seasonLB_callback(obj,hObj,event);
    selectedLB_callback(obj,hObj,event);
    removePB_callback(obj,status,event);
    okPB_callback(obj,status,event);
    systemsLB_callback(obj,status,event);
    season_update(obj);
    sourceLB_callback(obj,status,event);
    layerSourcePM_callback(obj,status,event);
    mapsPM_callback(obj,status,event);
    flightlinesPM_callback(obj,status,event);
    layers_callback(obj,status,event);
    layers_callback_new(obj,status,event);
    layers_callback_refresh(obj,status,event);
    
%     addlistener(event_obj,'StateChange',@myCallback)
    
  end
  
end


