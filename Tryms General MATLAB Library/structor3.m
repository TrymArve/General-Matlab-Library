classdef structor3 < handle
 % ===== Structor Version 3 =====
 % The new and better structor class. Uses pointer-like handling of
 % values for more efficient automatic updating of struct.
 % Improved and updated mixing strategy, options, and interface.
 % New in v3:
 %{
This version uses the struct part as the main storage of data, this is in
order to maintain all syntax and funcitonality associated with structs,
since this the way we will mainly interact with the structor. 
The vector part will be required more seldom, and will simpl query the data
from the structor. Still with a pointer like behavior.
 %}








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
   properties(Dependent)
      len (1,1) double {mustBeNonnegative,mustBeInteger} % length of vec
   end






   %%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE PROPERTIES:
   properties(SetAccess = public, Hidden)
      data (:,1) dictionary = dictionary; % this is the internal data-vector that contains all the actual values of the structor. The keys are data-IDs that are stored in the 'str' variable.
      data_length (1,1) double {mustBeNonnegative,mustBeInteger} = 0; % simply keeps track of the number of entreis in "data", to avoid calling "numEntries".
      % node_ID (:,1) dictionary = dictionary; % This dictionary contains the placement of each node in the struct-hierarchy. The key is the same as in "data".
      % node_ID_length (1,1) double {mustBeNonnegative,mustBeInteger} = 0; % keeps track of the number of nodes in the struct-hierarchy
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
      function C = structor3(default_mix,default_structure,default_depth)
         arguments
            default_mix (1,1) string {mustBeMember(default_mix,["column","row","scalar","bulk"])} = "bulk";
            default_structure (1,1) string {mustBeMember(default_structure,["first-fields-first","shallow-values-first","bredth-to-first"])} = "first-fields-first";
            default_depth (1,1) double  {mustBeInteger,mustBeNonnegative}  = 0;
         end

         C.default_mix = default_mix;
         C.default_structure = default_structure;
         C.default_depth = default_depth;
      end
   end








   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Set/Get functions:
   methods

      % -------------- SET FUNCTIONS:

      % Intercept any changes made to class properties (Set-funcitons):
      function C = subsasgn(C,index_composition,value)
         set_like_normal = true; % if not changed by the end of the function, the normal matlab routine for setting values is called.



         if set_like_normal
            funciton_set_like_normal(value)
         end

         function funciton_set_like_normal(value)
            C = builtin('subsasgn', C, index_composition, value);
         end
      end % END OF SUBSASGN




      function set.flag_must_identify_nodes(C,in)
         C.flag_must_identify_nodes = in;
         C.flag_must_build_structure = C.flag_must_build_structure + in;
      end


      %%% Default structure settigns:
      function set.default_mix(C,in)
         C.flag_must_build_structure = true;
         C.default_mix = in;
      end
      function set.default_structure(C,in)
         C.flag_must_build_structure = true;
         C.default_structure= in;
      end
      function set.default_depth(C,in)
         C.flag_must_build_structure = true;
         C.default_depth= in;
      end










      % -------------- GET FUNCTIONS:

      function value = subsref(C,index_composition)

         if string(index_composition(1).type) == "."
            switch string(index_composition(1).subs)
               case "vec"
                  % we are trying to get a the vector value or indexed
                  % values
                  if isscalar(index_composition)
                     % We are requesting the enitre vector.


                  elseif string(index_composition(2).type) == "()"
                     % we are trying to index into the vector.

                  elseif string(index_composition(2).type) == "{}"
                     % we are trying to index into the vector with cell
                     % notation.

                  else
                     error("USER ERROR: You may not index into 'vec' in any other way than using paranteses () or curly braces {}.")
                  end
               otherwise
                  function_get_like_normal
            end
         else
            function_get_like_normal
         end


         if nargout == 0 && exist('value','var')
            clear('value')
         end


         function function_get_like_normal
            if nargout == 0
               % No output expected — call without capturing output
               builtin('subsref', C, index_composition)
            else
               % Output expected — capture result
               value = builtin('subsref', C, index_composition);
            end
         end


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

         % Don't bother if not necessary....
         if ~C.flag_must_build_structure
            return
         end
         % This function takes reoranizes "map" so as to extract the data
         % in the correct order

         % Ensure the node_tree is up to date
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

' continue making the structor3, it should store data in the struct part, then have the vec query the struct in a neat way.

      end
   end














   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Internal methods:
   methods(Access = private)



      function get_vec(C)
         
         vector = loo_get_vec(C.node_tree)

         % assume that nodes is a cell array of node-id-vectors
         function vector = loo_get_vec(nodes)
            
         end
      end









      function node_tree_temp = identify_nodes(C,options)
         arguments
            C
            options.str (1,1) struct
         end

         if isfield(options,'str')
            S = options.str;
         else
            S = C.str;
         end

         node_tree_temp = dictionary;
         traverse_struct(S,[])

         if nargout == 0
            C.node_tree = node_tree_temp;
            clear('node_tree_temp')
         end

         function traverse_struct(S,ID)
            counter = 0;
            for name = string(fieldnames(S))'
               counter = counter + 1;
               tempID = [ID counter];
               if isstruct(S.(name))
                  traverse_struct(S.(name),tempID);
               else
                  node_tree_temp({tempID}) = {[S.(name)]};
               end
               S = rmfield(S,name);
            end
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

   end



end

