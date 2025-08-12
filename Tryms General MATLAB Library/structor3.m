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
      default_depth (1,1) double  {mustBeInteger,mustBeNonnegative} = 1;
      

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
      ind (1,1) struct = struct
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
      node_tree (:,2) cell = cell(0,2); % contains the node-ID of all nodes, adjoined by the element indices in a matrix with the same size and the data.
      map (:,2) cell = cell(0,2); % contains the node-ID map{i,1}, and the element index map{i,2} in order.


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
            default_depth (1,1) double  {mustBeInteger,mustBeNonnegative}  = 1;
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



         if index_composition(1).type == "." 
            if index_composition(1).subs == "str"
               % Require a re-identification and strucure-build if C.str is
               % touched at all...
               C.flag_must_identify_nodes = true;
               C.flag_must_build_structure = true;
            elseif index_composition(1).subs == "vec"
               set_like_normal = false;
               if isscalar(index_composition)
                  % are setting the entire vector at once
                  if isscalar(value)
                     value(1:C.len) = value;
                  end
                  C.set_vec(value);
               else
                  % if index_composition(2).type == "()" && index_composition(2).subs == ":"
                  % 
                  % end
                  vector = C.subsref(index_composition(1)); % get the current C.vec as "vector" using the CUSTOM 'subsref' defined by this class.
                  vector = builtin('subsasgn', vector, index_composition(2:end), value); % Update the relevant elements of "vector" by normal matlab functionality
                  C.set_vec(vector); % assign the new vector elements to the "str" part.
               end
            end
         end


         if set_like_normal
            funciton_set_like_normal(value)
         end

         function funciton_set_like_normal(value)
            C = builtin('subsasgn', C, index_composition, value);
         end
      end % END OF SUBSASGN




      function set.flag_must_identify_nodes(C,in)
         C.flag_must_identify_nodes = in;
         C.flag_must_build_structure = C.flag_must_build_structure + in; % if the nodes need to be re-identified, then the structure must also be re-built.
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
                  if C.flag_must_build_structure
                     C.build_structure
                  end
                  % we are trying to get a the vector value or indexed
                  % values
                  if isscalar(index_composition)
                     % We are requesting the enitre vector.
                     value = C.get_vec(1:C.len);

                  elseif length(index_composition) == 2 && string(index_composition(2).type) == "()"
                     % we are trying to index into the vector.

                     %%% NOTE: This is very inefficient, since we are
                     %%% constructing the entire vector, then extracting
                     %%% just the few we are indexing to. (instead of constructing only the elements we are requesting)
                     %%% BUT: This was quick to implement, and is very
                     %%% robust w.r.t. maintaining the syntax of normal
                     %%% vectors.
                     %%% (did the same for cell syntax under)
                     value = C.get_vec(1:C.len);
                     value = builtin('subsref', value, index_composition(2:end));

                  elseif string(index_composition(2).type) == "{}"
                     % we are trying to index into the vector with cell
                     % notation.
                     value = C.get_vec(1:C.len);
                     value = builtin('subsref', value, index_composition(2:end));



                     %%%%%% SPECIAL SYNTAXes:
                  elseif length(index_composition) == 3 && string(index_composition(2).type) == "()" && string(index_composition(3).type) == "." && ischar(index_composition(3).subs)
                     value = C.get_vec(1:C.len); % create wholse vector
                     value = builtin('subsref', value, index_composition(2)); % extract relevant elements

                     % Perform special syntax related stuff:
                     switch string(index_composition(3).subs)
                        case "subcopy"
                           warning("Special vec-syntax 'subcopy' not defined yet.")
                        otherwise
                           error("USER ERROR: Special get.vec syntax not defined. You entered: C.vec(...)." + string(index_composition(3).subs) + ", which is not a valid special syntax.")
                     end






                  else
                     error("USER ERROR: You may not index into 'vec' in any other way than using paranteses () or curly braces {}.")
                  end

                  % make matlab display output if semicolon is not used:
                  if nargout == 0
                     ind_comp.type = "()";
                     ind_comp.subs = {1:length(value)};
                     disp('Always displaying "vec" output when "vec" is called without assigning output to new variable.')
                     builtin('subsref', value, ind_comp)
                  end


               case "str"
                  % We make a case for "str" in order to add special syntax
                  % to substruts. If no special syntax is used, we proceed
                  % as normal.

                  %%% If special syntax
                  if length(index_composition) >= 3 && all(cellfun(@(type) string(type),{index_composition([1:end-2 end]).type}) == ".") && index_composition(end-1).type == "()" && isempty(index_composition(end-1).subs) && ischar(index_composition(end).subs)
                     % note the condition: length(index_composition) >= 3
                     % This is because we only accept special syntax for
                     % str, which amounts to at least one indexing,
                     % and the special syntax itself creates two more, thus
                     % there should be at least 3.

                     switch string(index_composition(end).subs)
                        case "copy"
                           create_pre_copy
                        case "zeros"
                           create_pre_copy
                           value.set_vec_all(0);
                        case "ones"
                           create_pre_copy
                           value.set_vec_all(1);
                        case "nan"
                           create_pre_copy
                           value.set_vec_all(nan);
                        case "vec" % if vec is used as special syntax on a subfield, then return vector of only those elements
                           % substr = structor3(C.default_mix,C.default_structure,C.default_depth);
                           % substr.str = builtin('subsref', C.str, index_composition(2:end-2));
                           substr_ID = C.find_ID_from_ind_comp(index_composition(2:end-2));
                           value = cell(C.len,1);
                           % C.loop_str(C.str,@loop_str_get_subvec);
                           subIDlen = length(substr_ID);
                           submap = C.map(cellfun(@(ID) length(ID) >= subIDlen && all(ID(1:subIDlen) == substr_ID), C.map(:,1)),:);
                           value = C.get_vec(1:size(submap,1),submap);
                        case "len"
                           value = structor3;
                           value.str = builtin('subsref', C.str, index_composition(2:end-2));
                           value = value.len;
                     end

                  else % Not special syntax
                     function_get_like_normal(nargout) % if no special syntax is used, simply proceed without interfering with the subsref method.
                  end


               otherwise
                  function_get_like_normal(nargout)
            end


         else
            function_get_like_normal(nargout)
         end


         if nargout == 0 && exist('value','var')
            clear('value')
         end


         function function_get_like_normal(outer_nargout)
            if outer_nargout == 0
               % No output expected — call without capturing output
               builtin('subsref', C, index_composition)
            else
               % Output expected — capture result
               value = builtin('subsref', C, index_composition);
            end
         end

         function create_pre_copy
            value = structor3(C.default_mix,C.default_structure,C.default_depth);
            if ~isempty(index_composition(2:end-2))
               value.str = builtin('subsref', C.str, index_composition(2:end-2));
            else
               value.str = C.str;
            end

         end


      end

      function out = get.len(C)
         if C.flag_must_build_structure
            C.build_structure
         end
         out = size(C.map,1);
      end


      function ind = get.ind(C)
         if C.flag_must_build_structure
            C.build_structure
         end
         if isempty(fieldnames(C.ind))
            C_copy = C.copy;
            C_copy.set_vec(1:C.len);
            C.ind = C_copy.str;
         end
         ind = C.ind;
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

         if depth == 0
            warning('Note that "bredth-to-first" with infinite depth (depth=0) will simply yield "first-fields-first".')
         end

         C.map = cell(0,2); % ensure the previous map is not lurking...

         % Ensure the node_tree is up to date
         if C.flag_must_identify_nodes
            C.identify_nodes
         end

         % Extract keys and values:
         node_IDs = C.node_tree(:,1);
         node_sizes = C.node_tree(:,2);

         criteria = [];

         % Define order to add nodes:
         switch structure
            case "first-fields-first"
               % Do nothing... (already in this order)
               %{
                  The recursive "traverse_nodes" function already traverses
                  in a 'top-down' order, thus V is already in the correct
                  order, and does not need to be re-sorted.
               %}
            case "shallow-values-first"
               criteria = cellfun(@(k) length(k),node_IDs,'UniformOutput',false);
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
               [node_IDs, node_sizes] = C.bredth_first(depth);


         end

         if ~isempty(criteria)
            % Reorder the entire cell array
            [~, sortIdx] = sortrows(reshape(criteria,[],1));
            node_IDs = node_IDs(sortIdx);
            node_sizes = node_sizes(sortIdx);
         end

         if mix == "scalar"
            node_sizes = cellfun(@(v) reshape(v,[],1),node_sizes,'UniformOutput',false);
         end


         mapping = {}; % will contain the node-ID and the specific element index in correct order

         while ~isempty(node_IDs)
            for i = 1:size(node_IDs,1)
               switch mix
                  case "bulk"
                     element_indices = node_sizes{i};
                     node_sizes{i} = [];
                  case "column"
                     element_indices = node_sizes{i}(:,1);
                     node_sizes{i}(:,1) = [];
                  case "row"
                     element_indices = node_sizes{i}(1,:);
                     node_sizes{i}(1,:) = [];
                  case "scalar"
                     element_indices = node_sizes{i}(1);
                     node_sizes{i}(1) = [];
               end
               mapping(end+(1:numel(element_indices)),1) = node_IDs(i);
               mapping(end+1-(numel(element_indices):-1:1), 2) = num2cell(element_indices(:));
            end
            % remove cells that contain empty doubles (in node_sizes):
            node_IDs   = node_IDs(  ~cellfun(@isempty, node_sizes));
            node_sizes = node_sizes(~cellfun(@isempty, node_sizes));
         end

         C.map = mapping;

         C.flag_must_build_structure = false;



      end
   end














   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Internal methods:
   methods(Access = private)

      function set_vec_all(C,scalar_value)
         % sets all elements of str to the new value, allowing one to
         % switch data types.
         C.str = loop_set_vec(C.str);

         function S_out = loop_set_vec(S)
            S_out = S;
            for name = string(fieldnames(S))'
               if isstruct(S.(name))
                  S_out.(name) = loop_set_vec(S.(name));
               else
                  matrix = [];
                  matrix(1:numel(S_out.(name))) = scalar_value;
                  S_out.(name) = reshape(matrix,size(S_out.(name)));
               end
            end
         end
      end

      function set_vec(C,vector)
         for i = 1:size(C.map(:,1),1)
            id = C.map{i,1};
            element_ind = C.map{i,2};
            element = vector(i);
            C.str = loop_set_vec(C.str,id);
         end

         %%% WARNING: suffers the same inefficiencies as the get_vec
         %%% function
         function S_out = loop_set_vec(S,sub_node_ID)
            S_out = S;
            Fields = fieldnames(S);
            field_ind = sub_node_ID(1);
            name = Fields{field_ind};
            if isstruct(S.(name))
               S_out.(name) = loop_set_vec(S.(name),sub_node_ID(2:end));
            else
               S_out.(name)(element_ind) = element;
            end
         end
      end

      function vector = get_vec(C,indices,map)
         arguments
            C
            indices (:,1) double {mustBeInteger,mustBePositive}
            map (:,2) cell = C.map;
         end
%{
WARNING !!!!!!
I know this is a super inefficient way of doing this, since we should
actually retrieve all elements of the subfield while we are already inside
that subfield, rather than going in and out for each element...
I simply do not have time to write a better version right now, but might
get back to it later.
%}

         % remember to re-build structure if necessary:
         if C.flag_must_build_structure
            C.build_structure
         end


         vector = [];
         element = [];
         for index = indices'
            node_ID = map{index,1};
            element_ind = map{index,2};
            loop_get_vec(C.str,node_ID);
            vector = [vector; element];
         end

         function loop_get_vec(S,sub_node_ID)
            Fields = fieldnames(S);
            field_ind = sub_node_ID(1);
            name = Fields{field_ind};
            if isstruct(S.(name))
               loop_get_vec(S.(name),sub_node_ID(2:end));
            else
               element = S.(name)(element_ind);
            end
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

         node_tree_temp = {};
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
                  node_tree_temp{end+1,1} = tempID; % store the node ID
                  node_tree_temp{end  ,2} = reshape(1:numel(S.(name)),size(S.(name))); % replace the elements with its index (and store too)
               end
               S = rmfield(S,name);
            end
         end
      end

      function [Node_IDs, Node_sizes] = bredth_first(C,depth)

         if depth == 0
            depth = inf;
         end

         % splits into the bredth groups:
         [ID_groups, size_groups] = C.split_to_groups(C.node_tree(:,1),C.node_tree(:,2),depth,1);


         % Add 1 node from each group sequentially until all groups are
         % empty: (bredth-first)
         Node_IDs = {};
         Node_sizes = {};
         while ~isempty(ID_groups)
            for group = 1:length(ID_groups)
               Node_IDs(  end+1,1) = ID_groups{  group}(1);
               Node_sizes(end+1,1) = size_groups{group}(1);
               ID_groups{  group}(1) = [];
               size_groups{group}(1) = [];
            end
            non_empty_cells = ~cellfun(@isempty,   ID_groups);
            ID_groups   = ID_groups(  non_empty_cells);
            size_groups = size_groups(non_empty_cells);
         end
      end

      function [ID_groups, size_groups] = split_to_groups(C,node_IDs,node_sizes,depth_to_go,current_depth)
         arguments
            C
            node_IDs (:,1)
            node_sizes (:,1)
            depth_to_go; current_depth;
         end

         subtrees = {configureDictionary('double','cell');
                     configureDictionary('double','cell')};

         for i = 1:length(node_IDs)
            node_ID = node_IDs(i);
            sorting_int = node_ID{1}(min(current_depth,length(node_ID{1})));
            if ~isKey(subtrees{1},sorting_int)
               subtrees{1}(sorting_int) = {{}};
               subtrees{2}(sorting_int) = {{}};
            end
            subtrees{1}{sorting_int}(end+1) = node_IDs(i);
            subtrees{2}{sorting_int}(end+1) = node_sizes(i);

         end




         if depth_to_go > 1 && numEntries(subtrees{1}) > 1
            ID_groups = {};
            size_groups = {};
            for i = 1:numEntries(subtrees{1})
               [ID_group_i, size_group_i] = C.split_to_groups(subtrees{1}.values{i},subtrees{2}.values{i},depth_to_go-1,current_depth+1);
               ID_groups = [ID_groups; ID_group_i];
               size_groups = [size_groups; size_group_i];
            end
         else
            ID_groups = subtrees{1}.values;
            size_groups = subtrees{2}.values;
         end
      end




      function loop_str(C,S,do_to_field)
         for name = string(fieldnames(S))'
            if isstruct(S.(name))
               C.loop_str(S.(name),do_to_field)
            else
               do_to_field(C,S.(name));
            end
         end
      end


      function ID = find_ID_from_ind_comp(C,ind_comp)
         S = C.str;
         ID = [];
         for name = string({ind_comp.subs})
            Names = string(fieldnames(S));
            ind = find(Names == name);
            ID(1,end+1) = ind;
            S = S.(name);
         end
      end

   end




% utility methods:
   methods
      function C_copy = copy(C)
         C_copy = C.subsref(structor3.make_ind_comp_for_str_special_syntax("copy"));
      end
      function C_zeros = zeros(C)
         C_zeros = C.subsref(structor3.make_ind_comp_for_str_special_syntax("zeros"));
      end
      function C_ones = ones(C)
         C_ones = C.subsref(structor3.make_ind_comp_for_str_special_syntax("ones"));
      end
      function C_nan = nan(C)
         C_nan = C.subsref(structor3.make_ind_comp_for_str_special_syntax("nan"));
      end
      function C_empty_copy = empty(C)
         C_empty_copy = structor3(C.default_mix,C.default_structure,C.default_depth);
      end

      % Interpolation funciton:
      function C_interp = interp(C,original_samples,new_samples)
%{
This function assumes that each field contains a sample-series, and allows
one to create a copy structor, containing a series of interpolated points
instead.
Fields are on form: [ sample_1 sample_2 sample_3 ... ]
where "sample_i" is a column vector.
"original_samples" are the sample-points at which the current structor
fields are sampled, and must thus be of same length.
"new_samples" are the samples at which we want to find interpolated values
for the new series.
%}

         % % Interpolation only works for doubles:
         % if ~isa(C.vec(1),'double')
         %    errro("USER ERROR: You are trying to perform interpolation of a non-double datatype. You have: " + class(C.vec(1)))
         % end


         % Make sure that the new samples don't exceed the edge-samles of
         % the original samples. (we don't want to extrapolate)
         new_samples(new_samples>original_samples(end)) = original_samples(end);
         new_samples(new_samples<original_samples(1)) = original_samples(1);

         C_interp = C.copy;
         C_interp.str = loop_structure(C.str);

         function S_out = loop_structure(S)
            S_out = struct;
            for name = string(fieldnames(S))'
               if isstruct(S.(name))
                  S_out.(name) = loop_structure(S.(name));
               else
                  S_name = S.(name);
                  org_samp = original_samples;
                  if size(S.(name),2) < length(original_samples)
                     org_samp = original_samples(1:size(S.(name),2));
                  elseif size(S.(name),2) > length(original_samples)
                     S_name = S.(name)(:,1:length(org_samp));
                  end
                  new_samp = new_samples;
                  new_samp(new_samp > org_samp(end)) = org_samp(end);
                  new_samp(new_samp < org_samp(1)) = org_samp(1);
                  S_out.(name) =  transpose(reshape(interp1(reshape(org_samp,[],1),S_name',new_samp),[],size(S.(name),1)));
               end
            end
         end
      end
   end



   % Static methods
   methods(Static)
      function ind_comp = make_ind_comp_for_str_special_syntax(syntax)
         arguments
            syntax (1,1) string {mustBeMember(syntax,["copy","zeros","ones","nan"])}
         end
         ind_comp(1).type = ".";
         ind_comp(1).subs = "str";
         ind_comp(2).type = "()";
         ind_comp(2).subs = {};
         ind_comp(3).type = ".";
         ind_comp(3).subs = char(syntax);
      end
   end



end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Tester script for structor version 3

%%%%%%%%%% Some code to test the structor functionality...

% fresh
% 
% disp('===============================')
% disp('--- Instantiating structor3 ---')
% C = structor3("bulk","first-fields-first");
% 
% C.str.a1.a2 = ["aa11","aa12"; "aa21","aa22"];
% C.str.a1.b2 = "ab";
% C.str.b1 = "b";
% C.str.c1.a2.a3 = "caa";
% C.str.c1.a2.b3 = "cab";
% C.str.c1.b2 = "cb";
% C.str.a1.c2 = "ac";
% C.str.c1.a2.c3.a4 = ["caca11", "caca12"];
% C.str.c1.a2.c3.b4 = ["cacb11"; "cacb21"];
% 
% disp("====== str:")
% C.str
% 
% 
% C.build_structure("first-fields-first","bulk",1);
% C.vec
% 
% 
% %% Testing structures
% disp('===========================')
% disp('--- Building structures ---')
% 
% C.build_structure("shallow-values-first","bulk")
% disp("shallow-values-first / bulk")
% C.vec
% 
% C.build_structure("shallow-values-first","row")
% disp("shallow-values-first / row")
% C.vec
% 
% C.build_structure("shallow-values-first","column")
% disp("shallow-values-first / column")
% C.vec
% 
% C.build_structure("shallow-values-first","scalar")
% disp("shallow-values-first / scalar")
% C.vec
% 
% C.build_structure("bredth-to-first","bulk",0);
% disp("bredth-to-first / bulk / depth 0")
% C.vec
% 
% C.build_structure("bredth-to-first","bulk",2);
% disp("bredth-to-first / bulk / depth 2")
% C.vec
% 
% C.build_structure("bredth-to-first","bulk",1);
% disp("bredth-to-first / bulk / depth 1")
% C.vec
% 
% 
% %% Getting Vec
% 
% disp('===================')
% disp('--- Getting vec ---')
% C.vec
% 
% C.vec(1)
% 
% C.vec(2:6)
% 
% C.vec([1 3 5])
% 
% C.vec(:)
% 
% C.vec{1}
% 
% %% Getting str
% disp('===================')
% disp('--- Getting str ---')
% 
% C.str
% 
% C.str.a1
% 
% C.str.a1.a2
% 
% C.str.a1.a2(1,1)
% 
% %% special syntax:
% disp('======================')
% disp('--- Special syntax ---')
% 
% disp('copy:')
% S = C.str.a1().copy;
% S.str
% S.vec
% 
% disp('Zeros:')
% Z = C.str.a1().zeros;
% Z.str
% Z.vec
% 
% disp('ones:')
% O = C.str.a1().ones;
% O.str
% O.vec
% 
% disp('nan:')
% N = C.str.a1().nan;
% N.str
% N.vec
% 
% disp('Typing: C.str.c1.a2().vec')
% v = C.str.c1.a2().vec;
% disp(v)
% 
% 
% %% Setting str
% 
% disp('===================')
% disp('--- Setting str ---')
% 
% C.str.ne.b2.nonexistant = "New value!!";
% C.str.a1.a2(1,2) = "indexed value !";
% C.vec
% C.str.a1.a2(:) = "setting the whole thing at once via indexing!";
% C.vec
% 
% C.str.a1.a2 = "overriding the field /!\";
% C.vec
% 
% %% Setting vec
% disp('===================')
% disp('--- Setting vec ---')
% 
% disp('Typing: C.vec(1) = "(1)";')
% C.vec(1) = "(1)";
% C.vec
% 
% disp('Typing: C.vec(2:6) = "2:6";')
% C.vec(2:6) = "2:6";
% C.vec
% 
% disp('Typing: C.vec([1 3 5]) = "[1 3 5]";')
% C.vec([1 3 5]) = "[1 3 5]";
% C.vec
% 
% disp('Typing: C.vec = "setting all elements to this...";')
% C.vec = "setting all elements to this...";
% C.vec
% 
% disp('Typing: C.vec(:) = "setting all elements to this via indexing...";')
% C.vec(:) = "setting all elements to this via indexing...";
% C.vec
% 
% 
% %% Practical methods:
% disp('======================')
% disp('--- Practical methods (goes via special syntax) ---')
% 
% disp('copy:')
% S = C.copy;
% S.str
% S.vec
% 
% disp('zeros:')
% Z = C.zeros;
% Z.str
% Z.vec
% 
% disp('ones:')
% O = C.ones;
% O.str
% O.vec
% 
% disp('nan:')
% N = C.nan;
% N.str
% N.vec
% 
% 
% 
% %% Interpolation:
% disp('=====================')
% disp('--- Interpolating ---')
% 
% C = structor3("column");
% C.str.X = [ 1  2  3  4;
%            10 20 30 40];
% C.str.U = [200 400 600 800];
% 
% disp('Non-interpolated:')
% C.str
% C.vec
% 
% C_interp = C.interp(1:4,(1:4)+0.5);
% 
% disp('interpolated:')
% C_interp.str
% C_interp.vec