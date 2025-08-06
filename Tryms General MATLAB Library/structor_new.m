classdef structor < handle
 % ===== Structor Version 2 =====
 % The new and better structor class. Uses pointer-like handling of
 % values for more efficient automatic updating of struct.
 % Improved and updated mixing strategy, options, and interface.








   %%%%%%%%%%%%%%%%%%%%%%%%%%%%% PUBLIC PROPERTIES:

   % ===============================
   % Settings:
   properties
      default_mix (1,1) string {mustBeMember(default_mix,["column","row","scalar","bulk"])} = "bulk";
      default_structure (1,1) string {mustBeMember(default_structure,["first-fields-first","shallow-values-first","bredth-to-first"])} = "first-fields-first";
      default_depth (1,1) double  {mustBeInteger,mustBeNonnegative} = 0;
      

      %{ 
         mix:
              - When the struct is traversed, to build the vector, the
              "mix" determined whether to only add one element, column, or
              row each time the struct-node is visited, or whether to add
              the wholde node at once ("bulk").

         structure:
              - The structure determines in what order the nodes of the
              struct hierarchy are added to the vector.

         depth: 
              - A "bredth-to-first" specific property.
              - Then depth determines at what depth of the struct-hierarchy
              the traversal shifts from bredth-first to first-fields-first, when building the vector. 
      %}
   end



   % ===============================
   % Struct/Vector -- These are the user interfaces into the structor data.
   properties
      str (1,1) struct = struct
   end
   properties(Dependent)
      vec (:,1) % returns a vector of the structor-data, organized according to the "pattern" and "mix" settigs
   end



   % ===============================
   % Miscellaneous Properties:
   properties(SetAccess = private)
      len (1,1) double {mustBeNonnegative,mustBeInteger} = 0; % length of vec
   end






   %%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE PROPERTIES:
   properties(SetAccess = public, Hidden)
      data (:,1) dictionary = dictionary; % this is the internal data-vector that contains all the actual values of the structor. The keys are data-IDs that are stored in the 'str' variable.
      data_length (1,1) double {mustBeNonnegative,mustBeInteger} = 0; % simply keeps track of the number of entreis in "data", to avoid calling "numEntries".
      node_ID (:,1) dictionary = dictionary; % This dictionary contains the placement of each node in the struct-hierarchy. The key is the same as in "data".
      node_ID_length (1,1) double {mustBeNonnegative,mustBeInteger} = 0; % keeps track of the number of nodes in the struct-hierarchy
      map (:,1) double = [] % a map from the struct index to the new mixed index in the vector.
      node_tree (1,1) dictionary = dictionary % Maps node-IDs to the data-ID
      %{
        map:
           The fields of str have values that are indices into the "map" vector, which
           contains indices into the "vec" vector, where the relevant values lie.
           Thus "map" simply reroutes from the struct index to the vec-index.
      %}

      %%%%% flags:
      flag_must_build_structure(1,1) logical = true; % this will trigger a remixing of the vector from the struct, when getting vector elements.
      flag_must_identify_nodes (1,1) logical = true; % this will trigger a re-traversal of the struct-hierarchy, to ensure proper labelling of str-nodes.
   end







   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constructor:
   methods
      function C = structor(default_mix,default_depth)
         arguments
            default_mix (1,1) string {mustBeMember(default_mix,["column","row","scalar","bulk"])} = "bulk";
            default_depth (1,1) double  {mustBeInteger,mustBeNonnegative}  = 0;
         end

         C.default_mix = default_mix;
         C.default_depth = default_depth;
      end
   end








   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Set/Get functions:
   methods

      % -------------- SET FUNCTIONS:

      % Intercept any changes made to class properties (Set-funcitons):
      function C = subsasgn(C,index_composition,value)
         set_like_normal = true; % if not changed by the end of the function, the normal matlab routine for setting values is called.

         switch index_composition(1).subs
            case "vec"
               % do nothing here, there is a catch condition in the normal
               % set.vec function.
            case "str"


               %{
               %%%%%%%%%% Note:
                 We could simply do this:
                     "current_value = subsref(C.str,index_composition(2:end));"
                 to get the current value, which also functions to
                 check whether field does indeed exist or not, since
                 this would catch an error is it does not, which could
                 be handled by "try-catch". However, I refrain from
                 this approach to avoid "try-catch" procedures, as they
                 could be sources of confusion and complicate
                 debugging.
                 Instead we proceed as follows.
               %}


               % Get the current field value, if already a field:
               set_like_normal = false; % assume we are rewriting an old value, which does not require the builtin function afterwards.
               S = C.str;
               for i = 2:length(index_composition)
                  if index_composition(i).type == "." 
                     if isfield(S,index_composition(i).subs)
                        S = S.(index_composition(i).subs);
                     else
                        set_like_normal = true; % The field does not already exist, so continue like normal after all.
                        break;
                     end
                  else
                     if i ~= length(index_composition)
                        error("USER ERROR: All substructs of 'str' must be scalar, thus one may not index into them.")
                     else
                        % We are now trying to index into a subfield (an end-field / node), which
                        % is allowed, but we do not continue like normal.
                        set_like_normal = false; % redundant, but for clarity...
                        break; % this is redundant, since we will not enter here unless this is the last iteration anyways...
                     end
                  end
               end

               %{
                 If we reach this point with
                      set_like_normal == true,
                 then we know that we are not indexing, and the field does
                 not already exist.
                 If 
                      set_like_normal == false, 
                 then the field definitely already exists, and we may be indexing into it.
               %}




               if set_like_normal
                  % Field does not exists, and must be properly
                  % initialized:
                  initialize_str_field
               else % The field does already exist, and we need to handle the change correctly:
                  
                  % Note that S is now the "current value". We rename for
                  % readability:
                  current_value = S;
                  
                  % We get the size of the current value and new values:
                  current_size = size(current_value);
                  new_size = size(value);
                  
                  if index_composition(end).type == "."
                     % The entire field is begin re-set:

                     if ~all(new_size == current_size)
                        % The field already exists, and the new dimensions are the same as previously, so we simply update the data:
                        C.data(current_value) = value;
                     else % The dimensions are different, so we delete the previous data and re-initialize.
                        C.data(current_value) = []; % delete old data
                        initialize_str_field % re-initialize like a normal set operation for fields that don't exist.
                     end

                  elseif index_composition(end).type == "{}"
                     error("DEV ERROR: indexing with braces is not supported yet... use parantheses")
                  else % The data is beign indexed somehow
                     
                     % if we are indexing, then "current_value" will be a
                     % field that is begin indexed into by
                     % index_composition(end).subs.

                     % Make sure the number of indices are consitent with
                     % current number of dimensions.
                     if length(current_size) ~= length(index_composition(end).subs)
                        error("USER ERROR: When setting 'str' field values by using indexing, the number of dimentions must be consistent.")
                     end

                     % for each dimension, find the indices that exceed the
                     % current size of the array.
                     for i = 1:length(current_size)
                        if max(index_composition(end).subs{i}) > current_size(i)
                           error("USER ERROR: When setting 'str'-fields with indexing, make sure not to change the size of the value. To change the size of the value at that field, re-set the enitre field with the new value.")
                        end
                     end

                     % Now we know that the indices do not exceed the
                     % array, so we can simply update the data at the given
                     % indices:
                     C.data(current_value(index_composition(end).subs{:})) = value;

                  end
               end



            case "len"
               disp("Setting the C.len property.")
            case "map"
               disp(" - - - - - setting map")
         end


         if set_like_normal
            % Continue making the property changes with MATLAB's normal functionality:
            C = builtin('subsasgn', C, index_composition, value);
         end



         function initialize_str_field
            C.flag_must_build_structure = true;
            C.flag_must_identify_nodes = true;

            inds = reshape(1:numel(value),size(value));
            C.data(C.data_length + inds) = value;
            value = C.data_length + inds;
            C.data_length = value(end);

            C.node_ID_length = C.node_ID_length + 1;
            C.node_ID(value) = C.node_ID_length;
         end
      end


      function set.flag_must_identify_nodes(C,in)
         C.flag_must_identify_nodes = in;
         C.flag_must_build_structure = C.flag_must_build_structure + in;
      end


      function set.vec(C,in)
         if length(in) ~= length(C.vec)
            % Do not set the vec directly! Then there would not be an
            % equivalent field in the str-property, creating inconsistency.
            error("USER ERROR: You may only set the 'vec'-property if the length is not changed. This is . You may add new elements by adding the values to the 'str'-property instead. Note: You may also directly redefine values of individulal elements of vec, by using indexing. Ex: myStructor.vec(5) = *newvalue*;")
         end

         C.data(C.map) = in;
      end

      % -------------- GET FUNCTIONS:

      function value = subsref(C,index_composition)
         if ~isprop(C,index_composition(1).subs)
            builtin('subsref', C, index_composition);
         else
            value = builtin('subsref', C, index_composition);

            switch index_composition(1).subs
               case "str"
                  if ~isstruct(value)
                     % Override output, and return the correct data:
                     value = C.data(value);
                  else
                     warning('The struct field values are not the actual data, but pointer to the data. To access the data itself, access the field value directly, not the whole struct.')
                  end
               otherwise
                  % do nothing, rely on the normal matlab procedure.
            end


         end
      end


      function out = get.vec(C)
         if C.flag_must_build_structure
            C.build_structure 
         end
         out = C.data(C.map);
      end

      



      function out = get.len(C)
         if C.flag_must_build_structure
            C.build_structure
         end
         out = C.len;
      end



   end



   % Generation function for structuring the struct hierarchy into a
   % vector:
   methods
      function build_structure(C,structure,mix,depth)
         arguments
            C 
            structure (1,1) string {mustBeMember(structure,["first-fields-first","shallow-values-first","bredth-to-first"])} = C.default_structure;
            mix (1,1) string {mustBeMember(mix,["column","row","scalar","bulk"])} = C.default_mix;
            depth (1,1) double {mustBeInteger,mustBeNonnegative} = C.default_depth;
         end
         % This function takes reoranizes "map" so as to extract the data
         % in the correct order

         % Enusre the node_tree is up to date
         if C.flag_must_identify_nodes
            C.identify_nodes
         end

         % Extract keys and values:
         K = keys(C.node_tree);
         V = values(C.node_tree);

         criteria = [];

         % Define order to add nodes:
         switch structure
            case "first-fields-first"
               criteria = 1:length(V);
               %{
                  The recursive "traverse_nodes" function already traverses
                  in a 'top-down' order, thus V is already in the correct
                  order, and does not need to be re-sorted.
               %}
            case "shallow-values-first"
               criteria = cellfun(@(k) length(k),K,'UniformOutput',false);
               %{
                  This chooses the values that appear fewest fields deep
                  into the struct hierarchy first. Ties are broken by
                  "first-field-first".
               %}
            case "bredth-to-first"
               %{
                  This separates the fields at depth d into the struct
                  hierarchy, into 'groups', then chooses one from each,
                  then another from each, then another, until all groups
                  are empty. The field chosen from a group is according to
                  'first-field-first'.
               %}
               NodeKeys= C.bredth_first(K,depth)';
               NodeValues = C.node_tree(NodeKeys);


         end

         if ~isempty(criteria)
            % Reorder the entire cell array
            [~, sortIdx] = sortrows(reshape(criteria,[],1));
            NodeValues = V(sortIdx);
         end

         %{
         %%%%%%%%% NOTE:
            When adding as "bulk", we can simply do this:
               dataIDs = cellfun(@(v) reshape(v,[],1),NodeValues,'UniformOutput',false);
               C.map = vertcat(dataIDs{:});
         %}

         if mix == "scalar"
            NodeValues = cellfun(@(v) reshape(v,[],1),NodeValues,'UniformOutput',false);
         end
         mapping = [];
         while ~isempty(NodeValues)
            for i = 1:length(NodeValues)
               switch mix
                  case "bulk"
                     nodval = NodeValues{i};
                     NodeValues{i} = [];
                  case "column"
                     nodval = NodeValues{i}(:,1);
                     NodeValues{i}(:,1) = [];
                  case "row"
                     nodval = NodeValues{i}(1,:);
                     NodeValues{i}(1,:) = [];
                  case "scalar"
                     nodval = NodeValues{i}(1);
                     NodeValues{i}(1) = [];
               end
               mapping = [mapping; reshape(nodval,[],1)];
            end
            NodeValues = NodeValues(~cellfun(@isempty, NodeValues)); % remove cells that contain empty doubles
         end

         C.map = mapping;

         C.flag_must_build_structure = false;


      end
   end





   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Internal methods:
   methods(Access = private)


      function identify_nodes(C)

         C.node_tree = dictionary;
         traverse_struct(C.str,[])

         function traverse_struct(S,ID)
            counter = 0;
            for name = string(fieldnames(S))'
               counter = counter + 1;
               tempID = [ID counter];
               if isstruct(S.(name))
                  traverse_struct(S.(name),tempID);
               else
                  C.node_tree({tempID}) = {[S.(name)]};
               end
               S = rmfield(S,name);
            end
         end
      end

      % function gen_vec(C)
      %    data_map = [];
      %    struct_queue = {};
      %    bredth_first(C.str,0);
      %    C.map = data_map;
      %    C.len = length(C.map);
      %    C.flag_must_generate_vector = false;
      % 
      % 
      % 
      %    function bredth_first(S,depth)
      %       for name = string(fieldnames(S))'
      %          if isstruct(S.(name))
      %             if depth >= C.default_depth
      %                struct_queue{end+1} = S.(name);
      %             else
      %                bredth_first(S.(name),depth+1);
      %             end
      %          else
      %             temp_S.name = S.(name);
      %             struct_queue{end+1} = temp_S;
      %          end
      %       end
      %    end
      % 
      % 
      %    function depth_first(S)
      %       names = string(fieldnames(S))';
      %       i = 0;
      %       while ~isempty(names)
      %          i = mod(i,length(names))+1;
      %          name = names(i);
      %          if isstruct(S.(name))
      %             depth_first(S.(name));
      %             remove_field
      %          else
      %             switch C.default_mix
      %                case "bulk"
      %                   inds = reshape(S.(name),[],1);
      %                   S.(name) = [];
      %                case "column"
      %                   inds = S.(name)(:,1);
      %                   S.(name)(:,1) = [];
      %                case "row"
      %                   inds = reshape(S.(name)(1,:),[],1);
      %                   S.(name)(1,:) = [];
      %                case "scalar"
      %                   S.(name) = reshape(S.(name),[],1);
      %                   inds = S.(name)(1);
      %                   S.(name)(1) = [];
      %             end
      %             data_map = [data_map; inds];
      % 
      %             if isempty(S.(name))
      %                remove_field
      %             end
      %          end
      %       end
      % 
      % 
      %       function remove_field
      %          S = rmfield(S,name);
      %          names(i) = [];
      %          i=i-1;
      %       end
      %    end
      % 
      % 


         function subtrees = split_to_groups(C,K,depth_to_go,current_depth)

            subtrees = configureDictionary('double','cell');

            for i = 1:length(K)
               key = K(i);
               sorting_int = key{1}(min(current_depth,length(key{1})));

               if ~isKey(subtrees,sorting_int)
                  subtrees(sorting_int) = {{}};
               end

               subtrees{sorting_int}(end+1) = key;
            end

            
            if depth_to_go > 1 && numEntries(subtrees) > 1
               new_V = {};
               for i = 1:numEntries(subtrees)
                  subsubtrees = C.split_to_groups(subtrees{i},depth_to_go-1,current_depth+1);
                  new_V = [new_V; subsubtrees.values];
               end
               subtrees = dictionary(1:length(new_V),new_V');
            end
         end


         function Nodes = bredth_first(C,K,depth)

            if depth == 0
               depth = inf;
            end
            subtrees = C.split_to_groups(K,depth,1);

            Nodes = {};
            while numEntries(subtrees) > 0
               for k = keys(subtrees)'
                  Nodes{end+1} = subtrees{k}{1};
                  subtrees{k}(1) = [];
                  if isempty(subtrees{k})
                     subtrees = remove(subtrees,k);
                  end
               end
            end
         end





      end









   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Miscellaneous User-methods:
   methods
      function C_copy = copy(C)

      end

      function C_zeros = zeros(C)

      end

      function C_ones = ones(C)

      end

      function C_interp = interp(C)

      end

      function C_subcopy = subcopy(C)

      end

      function C_retrieved = retrieve(C)
         % may be obsolete?
      end
   end

end