function layerCM_callback(obj,source,event)
% layerCM_callback(obj,source,event)

% Ensure focus stays on figure to prevent hotkeys registering with this
% uicontrol.
% uicontrol(obj.right_panel.status_panel.statusText);

if source == obj.left_panel.layerCM_visible || source == obj.left_panel.layerCM_hide
  val = get(obj.left_panel.layerLB,'Value');
  
  obj.eg.layers.visible_layers(val) = source == obj.left_panel.layerCM_visible;
  
  obj.layerLB_str();
  
  % Update plot based on selection
  obj.set_visibility();
elseif source == obj.left_panel.layerCM_new || source == obj.left_panel.layerCM_copy || source == obj.left_panel.layerCM_insert
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers. The new layer will be inserted
    % before the first of the currently selected layers or at the bottom
    % of the listbox.
    val = get(obj.left_panel.layerLB,'Value');
    val = val(val>2);
    % Ensure that there is at least one layer selected if copying
    if source == obj.left_panel.layerCM_new || ~isempty(val)
      if isempty(val)
        val = length(obj.eg.layers.lyr_id)+1;
      else
        val = val(1);
      end
      prompt = {'Layer Age:','Layer Age Source (cell array of strings):','Layer Age Source Age (double vector):','Layer Age Source Type (cell array of strings: unknown,annual,event,core,ref):','Description:','Layer Group Name:','Layer Name:'};
      old_base_name = ''; % Not used except for obj.left_panel.layerCM_insert
      if source == obj.left_panel.layerCM_new
        def = {'', '{}', '[]', '{}', '', '', ''};
        dlg_title = 'New Layer';
      else
        def = {sprintf('%g',obj.eg.layers.lyr_age(val)),'{}','[]','{}',obj.eg.layers.lyr_desc{val},char(obj.eg.layers.lyr_group_name{val}),obj.eg.layers.lyr_name{val}};
        if source == obj.left_panel.layerCM_copy
          val = val+1;
          dlg_title = 'Copy Layer';
        else % source == obj.left_panel.layerCM_insert
          old_base_name = obj.eg.layers.lyr_name{val};
          last_underscore = find(old_base_name=='_',1,'last');
          if ~isempty(last_underscore) && all(isstrprop(old_base_name(last_underscore+1:end),'digit'))
            zero_pad_len = length(old_base_name) - last_underscore;
            try
              count = str2double(old_base_name(last_underscore+1:end));
            catch
              fprintf('Selected layer name does not have a properly formated sequence layer name (BASENAME_###).\n');
              return;
            end
            old_base_name = old_base_name(1:last_underscore-1);
          else
            fprintf('Selected layer name does not have a properly formated sequence layer name (BASENAME_###).\n');
            return;
          end
          def{7} = obj.eg.layers.lyr_name{val};
          dlg_title = 'Insert Layer In Sequence';
        end
      end
      num_lines = 1;
      if source == obj.left_panel.layerCM_insert
        answer = def;
      else
        answer = inputdlg(prompt,dlg_title,num_lines,def);
      end
      
      if length(answer) == 7 && ~isempty(answer{7})
        try
          age = eval(answer{1});
        catch
          age = NaN;
        end
        if isempty(age)
          age = NaN;
        end
        try
          age_source_age = double(eval(answer{3}));
          if ~isfinite(age_source_age)
            error('');
          end
        catch
          fprintf('Invalid Layer Age Source Age.\n');
          return;
        end
        age_source_age = age_source_age(:).';
        try
          age_source_source = eval(answer{2});
          if ~iscell(age_source_source)
            error('Must be a cell array');
          end
          if ~all(cellfun(@ischar,age_source_source))
            error('Each cell must be a string');
          end
          % Ensure row cell vector
          age_source_source = age_source_source(:).';
          for idx=1:length(age_source_source)
            % Ensure each cell is a row vector
            age_source_source{idx} = age_source_source{idx}(:).';
          end
        catch
          fprintf('Invalid Layer Age Source.\n');
          return;
        end
        try
          age_source_type_input = eval(answer{4});
          if ~iscell(age_source_type_input)
            error('Must be a cell array');
          end
          if ~all(cellfun(@ischar,age_source_type_input))
            error('Each cell must be a string');
          end
          age_source_type = zeros(size(age_source_type_input));
          for idx=1:length(age_source_type_input)
            switch (age_source_source{idx})
              case 'unknown'
                age_source_type(idx) = 0;
              case 'annual'
                age_source_type(idx) = 1;
              case 'event'
                age_source_type(idx) = 2;
              case 'core'
                age_source_type(idx) = 3;
              case 'ref'
                age_source_type(idx) = 4;
              otherwise
                error('Unknown type');
            end
          end
        catch
          fprintf('Invalid Layer Age Source Type.\n');
          return;
        end
        desc = answer{5};
        group_name = answer{6};
        name = answer{7};
        
        if any(strcmpi(name,obj.eg.layers.lyr_name)) && source ~= obj.left_panel.layerCM_insert
          fprintf('  Layer %s already exists\n', name);
        else
          
          % Get id for new layer
          new_lyr_id = max(obj.eg.layers.lyr_id) + 1;
          id = new_lyr_id;
          
          fprintf('Add layer %s:%s age %g desc "%s"\n', group_name, name, age, desc);
          if val > length(obj.eg.layers.lyr_id)
            order = obj.eg.layers.lyr_order(end) + 1;
          else
            order = obj.eg.layers.lyr_order(val);
          end
          
          cmds = [];
          cmds(end+1).undo_cmd = 'layer_delete';
          cmds(end).undo_args = {id};
          cmds(end).redo_cmd = 'layer_new';
          cmds(end).redo_args = {id,age,desc,group_name,name,order};
          
          base_name = old_base_name;
          cur_val = val;
          if source == obj.left_panel.layerCM_insert
            start_val = 1;
          else
            start_val = cur_val;
          end
          for val = start_val:length(obj.eg.layers.lyr_id)
            age = obj.eg.layers.lyr_age(val);
            desc = obj.eg.layers.lyr_desc{val};
            group_name = obj.eg.layers.lyr_group_name{val};
            id = obj.eg.layers.lyr_id(val);
            old_name = obj.eg.layers.lyr_name{val};
            order = obj.eg.layers.lyr_order(val);
            if val >= cur_val
              % Only increment order of layers that are at the same or
              % later order as the layer that just got inserted. Layers
              % before this new layer will not have their order changed.
              if val < length(obj.eg.layers.lyr_order)
                new_order = obj.eg.layers.lyr_order(val+1);
              else
                new_order = obj.eg.layers.lyr_order(end) + 1;
              end
            else
              new_order = order;
            end
            
            % Keep the name the same unless inserting a layer into a
            % sequence in which case we need to change the name of all
            % subsequent layers in the sequence. For example, if we insert
            % a layer at "snow_003", then the old "snow_003" needs to
            % become "snow_004" and so on for all counts >= 3. "snow_001"
            % and "snow_002" will remain unchanged.
            if source == obj.left_panel.layerCM_insert
              old_base_name = obj.eg.layers.lyr_name{val};
              last_underscore = find(old_base_name=='_',1,'last');
              old_count = [];
              if ~isempty(last_underscore) && all(isstrprop(old_base_name(last_underscore+1:end),'digit'))
                old_zero_pad_len = length(old_base_name) - last_underscore;
                try
                  old_count = str2double(old_base_name(last_underscore+1:end));
                catch
                  old_count = [];
                end
                old_base_name = old_base_name(1:last_underscore-1);
              end
              if isempty(old_count) || old_count < count || old_zero_pad_len ~= zero_pad_len || ~strcmp(old_base_name,base_name)
                new_name = old_name;
              else
                new_name = sprintf(sprintf('%%s_%%0%dd',zero_pad_len),base_name,old_count+1);
              end
                
            else
              new_name = old_name;
            end
            
            if order ~= new_order || ~strcmp(new_name,old_name)
              cmds(end+1).undo_cmd = 'layer_edit';
              cmds(end).undo_args = {id,age,desc,group_name,old_name,order};
              cmds(end).redo_cmd = 'layer_edit';
              cmds(end).redo_args = {id,age,desc,group_name,new_name,new_order};
            end
          end
          cmds = cmds([2:end 1]);
          
          % Push the new command(s) to the stack
          obj.undo_stack.push(obj.cmds_convert_units(cmds));
        end
      end
    end
  end
  
elseif source == obj.left_panel.layerCM_edit
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers.
    vals = get(obj.left_panel.layerLB,'Value');
    vals = vals(vals>2);
    if length(vals) == 1
      val = vals(1);
      prompt = {'Layer Age:','Layer Age Source:','Layer Age Source Age:','Layer Age Source Type:','Description:','Layer Group Name:','Layer Name:'};
      old_age = obj.eg.layers.lyr_age(val);
      old_age_source_age = '[]';
      old_age_source_source = '{}';
      old_age_source_type = '{}';
      old_desc = obj.eg.layers.lyr_desc{val};
      old_group_name = char(obj.eg.layers.lyr_group_name{val});
      old_id = obj.eg.layers.lyr_id(val);
      old_name = obj.eg.layers.lyr_name{val};
      old_order = obj.eg.layers.lyr_order(val);
      def = {num2str(old_age),old_age_source_source,old_age_source_age,old_age_source_type,old_desc,old_group_name,old_name};
      dlg_title = 'Edit Layer';
      num_lines = 1;
      answer = inputdlg(prompt,dlg_title,num_lines,def);
      
      if length(answer) == 7 && ~isempty(answer{7})
        try
          age = eval(answer{1});
        catch
          age = NaN;
        end
        if isempty(age)
          age = NaN;
        end
        desc = answer{5};
        group_name = answer{6};
        name = answer{7};
        
        if any(strcmpi(name,obj.eg.layers.lyr_name([1:val-1 val+1:end])))
          fprintf('  Layer %s already exists\n', name);
        else
          
          fprintf('Edit layer %s:%s to %s:%s age: %g desc: "%s"\n', old_group_name, old_name, group_name, name, age, desc);
          
          cmds = [];
          cmds(end+1).undo_cmd = 'layer_edit';
          cmds(end).undo_args = {old_id,old_age,old_desc,old_group_name,old_name,old_order};
          cmds(end).redo_cmd = 'layer_edit';
          cmds(end).redo_args = {old_id,age,desc,group_name,name,old_order};
          
          % Push the new command(s) to the stack
          obj.undo_stack.push(obj.cmds_convert_units(cmds));
        end
      end
      
    elseif length(vals) > 1
      
      prompt = {'Description:','Layer Group Name:'};
      old_desc = obj.eg.layers.lyr_desc{vals(1)};
      old_group_name = char(obj.eg.layers.lyr_group_name{vals(1)});
      def = {old_desc,old_group_name};
      dlg_title = 'Edit Selected Layers';
      num_lines = 1;
      answer = inputdlg(prompt,dlg_title,num_lines,def);
      
      if length(answer) == 2
        desc = answer{1};
        group_name = answer{2};

        cmds = [];
        for val = vals
          old_age = obj.eg.layers.lyr_age(val);
          old_age_source_age = '[]';
          old_age_source_source = '{}';
          old_age_source_type = '{}';
          old_id = obj.eg.layers.lyr_id(val);
          old_name = obj.eg.layers.lyr_name{val};
          old_order = obj.eg.layers.lyr_order(val);
          
          fprintf('Edit layer %s:%s to %s:%s age: %g desc: "%s"\n', old_group_name, old_name, group_name, old_name, old_age, desc);
          
          cmds(end+1).undo_cmd = 'layer_edit';
          cmds(end).undo_args = {old_id,old_age,old_desc,old_group_name,old_name,old_order};
          cmds(end).redo_cmd = 'layer_edit';
          cmds(end).redo_args = {old_id,old_age,desc,group_name,old_name,old_order};
        end
        % Push the new command(s) to the stack
        obj.undo_stack.push(obj.cmds_convert_units(cmds));
      end
      
    end
  end
    
elseif source == obj.left_panel.layerCM_sequence
  vals = get(obj.left_panel.layerLB,'Value');
  vals = vals(vals>2);
  
  prompt = {'Basename (BASENAME_001):','Zero padding length ("003" is 3):','Start count at:'};
  old_base_name = obj.eg.layers.lyr_name{vals(1)};
  last_underscore = find(old_base_name=='_',1,'last');
  if ~isempty(last_underscore) && all(isstrprop(old_base_name(last_underscore+1:end),'digit'))
    old_base_name = old_base_name(1:last_underscore-1);
  end
  old_zero_pad_len = '3';
  old_start_count = '1';
  def = {old_base_name,old_zero_pad_len,old_start_count};
  dlg_title = 'Rename selected layers as sequence:';
  num_lines = 1;
  answer = inputdlg(prompt,dlg_title,num_lines,def);
  
  if length(answer) == 3
    base_name = answer{1};
    try
      zero_pad_len = eval(answer{2});
      start_count = eval(answer{3});
    catch ME
      fprintf('Invalid inputs to sequence layer names.\n');
      return;
    end
    
    cmds = [];
    for val = vals
      old_age = obj.eg.layers.lyr_age(val);
      old_age_source_age = '[]';
      old_age_source_source = '{}';
      old_age_source_type = '{}';
      old_id = obj.eg.layers.lyr_id(val);
      old_desc = obj.eg.layers.lyr_desc{val};
      old_group_name = obj.eg.layers.lyr_group_name{val};
      old_name = obj.eg.layers.lyr_name{val};
      old_order = obj.eg.layers.lyr_order(val);
      new_name = sprintf(sprintf('%%s_%%0%dd',zero_pad_len),base_name,start_count);
      
      fprintf('Edit layer %s:%s to %s:%s age: %g desc: "%s"\n', old_group_name, old_name, old_group_name, new_name, old_age, old_desc);
      
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {old_id,old_age,old_desc,old_group_name,old_name,old_order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {old_id,old_age,old_desc,old_group_name,new_name,old_order};

      start_count = start_count + 1;
    end
    % Push the new command(s) to the stack
    obj.undo_stack.push(obj.cmds_convert_units(cmds));
  end
  
elseif source == obj.left_panel.layerCM_order
  vals = get(obj.left_panel.layerLB,'Value');
  vals = vals(vals>2);
  done = false;
  order_unsorted = obj.eg.layers.lyr_order;
  name_unsorted = obj.eg.layers.lyr_name;
  y_unsorted = obj.eg.layers.y;
  iterations = 0;
  % Sort list using simple bubble sort
  while ~done && iterations <= length(vals)
    done = true;
    % Since the comparison operator does not satisify the axiom of a sort
    % operator that a > b and b > c implies a > c, to prevent potential
    % oscillations in layer sorting that may cause this to loop infinitely,
    % we keep track of the number of iterations and stop after the number
    % is equal to length(vals) which is the maximum number of iterations
    % for a bubble sort that does have a proper comparison operator.
    iterations = iterations + 1;
    for val_idx = 2:length(vals)
      prev_val = vals(val_idx-1);
      val = vals(val_idx);
      if 0
        % For debugging
        figure(1000);clf;
        plot(y_unsorted{val});
        hold on; 
        plot(y_unsorted{prev_val});
      end
      % Try to do direct comparison of the twtt
      comparison = y_unsorted{val} - y_unsorted{prev_val};
      if ~all(isnan(comparison))
        % At least one point has valid twtt for both layers so compare
        % these overlapping points
        comparison = nansum(comparison) < 0;
      else
        % No points in the two layers overlap, use the mean twtt to compare
        comparison = nanmean(y_unsorted{val}) - nanmean(y_unsorted{prev_val});
        if ~isnan(comparison)
          comparison = comparison < 0
        else
          % At least one layer is all NaN, so use layer names to sort
          comparison = issorted(name_unsorted([val,prev_val]));
        end
      end
      if comparison
        % Layer is out of order
        order_unsorted([prev_val val]) = order_unsorted([val prev_val]);
        name_unsorted([prev_val val]) = name_unsorted([val prev_val]);
        y_unsorted([prev_val val]) = y_unsorted([val prev_val]);
        done = false;
      end
    end
  end
  cmds = [];
  for val = find(order_unsorted ~= obj.eg.layers.lyr_order)
    old_age = obj.eg.layers.lyr_age(val);
    old_age_source_age = '[]';
    old_age_source_source = '{}';
    old_age_source_type = '{}';
    old_desc = obj.eg.layers.lyr_desc{val};
    old_group_name = char(obj.eg.layers.lyr_group_name{val});
    old_id = obj.eg.layers.lyr_id(val);
    old_name = obj.eg.layers.lyr_name{val};
    old_order = obj.eg.layers.lyr_order(val);
    new_order = find(order_unsorted == old_order);
    cmds(end+1).undo_cmd = 'layer_edit';
    cmds(end).undo_args = {old_id,old_age,old_desc,old_group_name,old_name,old_order};
    cmds(end).redo_cmd = 'layer_edit';
    cmds(end).redo_args = {old_id,old_age,old_desc,old_group_name,old_name,new_order};
  end
  if ~isempty(cmds)
    % Push the new command(s) to the stack
    obj.undo_stack.push(obj.cmds_convert_units(cmds));
  end
  
elseif source == obj.left_panel.layerCM_up
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers.
    val = get(obj.left_panel.layerLB,'Value');
    val = val(val>3);
    if ~isempty(val)
      val = val(1);
      age = obj.eg.layers.lyr_age(val);
      desc = obj.eg.layers.lyr_desc{val};
      group_name = obj.eg.layers.lyr_group_name{val};
      id = obj.eg.layers.lyr_id(val);
      name = obj.eg.layers.lyr_name{val};
      order = obj.eg.layers.lyr_order(val);
      new_order = obj.eg.layers.lyr_order(val-1);
      
      fprintf('Move layer up %s:%s\n', group_name, name);
      
      cmds = [];
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {id,age,desc,group_name,name,order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {id,age,desc,group_name,name,new_order};
      val = val-1;
      age = obj.eg.layers.lyr_age(val);
      desc = obj.eg.layers.lyr_desc{val};
      group_name = obj.eg.layers.lyr_group_name{val};
      id = obj.eg.layers.lyr_id(val);
      name = obj.eg.layers.lyr_name{val};
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {id,age,desc,group_name,name,new_order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {id,age,desc,group_name,name,order};
      cmds = cmds([2:end 1]);
      
      % Push the new command(s) to the stack
      obj.undo_stack.push(obj.cmds_convert_units(cmds));
    end
  end
  
elseif source == obj.left_panel.layerCM_down
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers.
    val = get(obj.left_panel.layerLB,'Value');
    val = val(val>2 & val<length(obj.eg.layers.lyr_name));
    if ~isempty(val)
      val = val(1);
      age = obj.eg.layers.lyr_age(val);
      desc = obj.eg.layers.lyr_desc{val};
      group_name = obj.eg.layers.lyr_group_name{val};
      id = obj.eg.layers.lyr_id(val);
      name = obj.eg.layers.lyr_name{val};
      order = obj.eg.layers.lyr_order(val);
      new_order = obj.eg.layers.lyr_order(val+1);
      
      fprintf('Move layer down %s:%s\n', group_name, name);
      
      cmds = [];
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {id,age,desc,group_name,name,order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {id,age,desc,group_name,name,new_order};
      val = val+1;
      age = obj.eg.layers.lyr_age(val);
      desc = obj.eg.layers.lyr_desc{val};
      id = obj.eg.layers.lyr_id(val);
      group_name = obj.eg.layers.lyr_group_name{val};
      name = obj.eg.layers.lyr_name{val};
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {id,age,desc,group_name,name,new_order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {id,age,desc,group_name,name,order};
      cmds = cmds([2:end 1]);
      
      % Push the new command(s) to the stack
      obj.undo_stack.push(obj.cmds_convert_units(cmds));
    end
  end
  
elseif source == obj.left_panel.layerCM_top
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers.
    val = get(obj.left_panel.layerLB,'Value');
    val = val(val>3);
    if ~isempty(val)
      val = val(1);
      age = obj.eg.layers.lyr_age(val);
      desc = obj.eg.layers.lyr_desc{val};
      group_name = obj.eg.layers.lyr_group_name{val};
      id = obj.eg.layers.lyr_id(val);
      name = obj.eg.layers.lyr_name{val};
      order = obj.eg.layers.lyr_order(val);
      
      new_val = 3;
      new_order = obj.eg.layers.lyr_order(new_val);
      
      fprintf('Move layer top %s:%s\n', group_name, name);
      
      cmds = [];
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {id,age,desc,group_name,name,order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {id,age,desc,group_name,name,new_order};
      for val = new_val:val-1
        age = obj.eg.layers.lyr_age(val);
        desc = obj.eg.layers.lyr_desc{val};
        group_name = obj.eg.layers.lyr_group_name{val};
        id = obj.eg.layers.lyr_id(val);
        name = obj.eg.layers.lyr_name{val};
        order = obj.eg.layers.lyr_order(val);
        new_order = obj.eg.layers.lyr_order(val+1);
        cmds(end+1).undo_cmd = 'layer_edit';
        cmds(end).undo_args = {id,age,desc,group_name,name,order};
        cmds(end).redo_cmd = 'layer_edit';
        cmds(end).redo_args = {id,age,desc,group_name,name,new_order};
      end
      cmds = cmds([2:end 1]);
      
      % Push the new command(s) to the stack
      obj.undo_stack.push(obj.cmds_convert_units(cmds));
    end
  end
  
elseif source == obj.left_panel.layerCM_bottom
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers.
    val = get(obj.left_panel.layerLB,'Value');
    val = val(val>2);
    if ~isempty(val)
      val = val(1);
      age = obj.eg.layers.lyr_age(val);
      desc = obj.eg.layers.lyr_desc{val};
      group_name = obj.eg.layers.lyr_group_name{val};
      id = obj.eg.layers.lyr_id(val);
      name = obj.eg.layers.lyr_name{val};
      order = obj.eg.layers.lyr_order(val);
      
      new_val = length(obj.eg.layers.lyr_name);
      new_order = obj.eg.layers.lyr_order(new_val);
      
      fprintf('Move layer bottom %s:%s\n', group_name, name);
      
      cmds = [];
      cmds(end+1).undo_cmd = 'layer_edit';
      cmds(end).undo_args = {id,age,desc,group_name,name,order};
      cmds(end).redo_cmd = 'layer_edit';
      cmds(end).redo_args = {id,age,desc,group_name,name,new_order};
      for val = val+1:new_val
        age = obj.eg.layers.lyr_age(val);
        desc = obj.eg.layers.lyr_desc{val};
        group_name = obj.eg.layers.lyr_group_name{val};
        id = obj.eg.layers.lyr_id(val);
        name = obj.eg.layers.lyr_name{val};
        order = obj.eg.layers.lyr_order(val);
        new_order = obj.eg.layers.lyr_order(val-1);
        cmds(end+1).undo_cmd = 'layer_edit';
        cmds(end).undo_args = {id,age,desc,group_name,name,order};
        cmds(end).redo_cmd = 'layer_edit';
        cmds(end).redo_args = {id,age,desc,group_name,name,new_order};
      end
      cmds = cmds([2:end 1]);
      
      % Push the new command(s) to the stack
      obj.undo_stack.push(obj.cmds_convert_units(cmds));
    end
  end
  
elseif source == obj.left_panel.layerCM_delete
  if strcmpi(obj.eg.layers.source,'layerData')
    % Get the currently selected layers.
    vals = get(obj.left_panel.layerLB,'Value');
    vals = vals(vals>2);
    if length(vals) > 1
      
      prompt = questdlg(sprintf('Are you sure you want to delete the %d selected layers?', ...
        length(vals)), ...
        'Delete Layer','Yes','Cancel','Cancel');
      
      switch prompt
        case 'Yes'
          cmds = [];
          % Sort in descending order or vals will change as layers get
          % deleted.
          vals = sort(vals,'descend');
          for val = vals
            age = obj.eg.layers.lyr_age(val);
            desc = obj.eg.layers.lyr_desc{val};
            group_name = obj.eg.layers.lyr_group_name{val};
            id = obj.eg.layers.lyr_id(val);
            name = obj.eg.layers.lyr_name{val};
            order = obj.eg.layers.lyr_order(val);
            fprintf('Delete layer %s:%s\n', group_name, name);
            
            cmds(end+1).undo_cmd = 'layer_new';
            cmds(end).undo_args = {id,age,desc,group_name,name,order};
            cmds(end).redo_cmd = 'layer_delete';
            cmds(end).redo_args = {id};
            
            % Push the new command(s) to the stack
          end
          obj.undo_stack.push(obj.cmds_convert_units(cmds));
        case 'Cancel'
      end
      
    elseif length(vals) == 1
      age = obj.eg.layers.lyr_age(vals);
      desc = obj.eg.layers.lyr_desc{vals};
      group_name = obj.eg.layers.lyr_group_name{vals};
      id = obj.eg.layers.lyr_id(vals);
      name = obj.eg.layers.lyr_name{vals};
      order = obj.eg.layers.lyr_order(vals);
      
      prompt = questdlg(sprintf('Are you sure you want to delete layer %s:%s?', ...
        group_name,name), ...
        'Delete Layer','Yes','Cancel','Cancel');
      
      switch prompt
        case 'Yes'
          fprintf('Delete layer %s:%s\n', group_name, name);
          
          cmds = [];
          cmds(end+1).undo_cmd = 'layer_new';
          cmds(end).undo_args = {id,age,desc,group_name,name,order};
          cmds(end).redo_cmd = 'layer_delete';
          cmds(end).redo_args = {id};
          
          % Push the new command(s) to the stack
          obj.undo_stack.push(obj.cmds_convert_units(cmds));
        case 'Cancel'
      end
    end
    
  end
  
end