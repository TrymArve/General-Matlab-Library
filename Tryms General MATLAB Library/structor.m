classdef structor < handle

   properties
      str (1,1) struct = struct % a structure containing dictionaries
      default_mix (1,1) string {mustBeMember(default_mix,["separated","scalar_mixed","vector_mixed"])} = "separated";
   end
   properties(SetAccess = private)
      vec (:,1) % vector consisting of all elements of the dictionaries, at indices descbribed by "ind"
      len (1,1) double {mustBeInteger,mustBeNonnegative} = 0 % length of vector "vec" (a.k.a. total numer of elements)
      ind (1,1) struct = struct % a structure that contains the indices of "dic" elements within vector "vec"
   end
   
   properties(Access = private,Hidden)
      flag_genvec (1,1) logical = false; % a flag that turns on when the vector is generated. This must be turned off manually.
   end
   
   

   methods
      % Constructor
      function C = structor(options)
         arguments
            options.default_mix (1,1) string {mustBeMember(options.default_mix,["separated","scalar_mixed","vector_mixed"])}
         end
         if isfield(options,'default_mix')
            C.default_mix = options.default_mix;
         end
      end

      function set.str(C,in)
         C.str = in;
         C.vec = []; %#ok<MCSUP>
         C.flag_genvec = false; %#ok<MCSUP>
      end

 


      function out = genvec(C,structure)
         arguments
            C
            structure (1,1) string {mustBeMember(structure,["separated","scalar_mixed","vector_mixed"])} = C.default_mix;
         end
         C.(['genvec_',char(structure)])
         C.flag_genvec = true;

         out = C.vec;
      end


      function retrieved_structor = retrieve(C,vector)
         retrieved_structor = structor(default_mix=C.default_mix);
         retrieved_structor.str = loop_structure(C.str,C.ind);

         function S_out = loop_structure(S,I)
            for name = string(fieldnames(S))'
               if isstruct(S.(name))
                  S_out.(name) = loop_structure(S.(name),I.(name));
               else
                  S_out.(name) = reshape(vector(I.(name)),size(S.(name)));
               end
            end
         end
      end


      function out = get.vec(C)
         if C.flag_genvec
            out = C.vec;
         else
            out = C.genvec;
         end
      end
   end



   methods(Access = private)
      function genvec_separated(C)
         vector = [];
         C.len = 0;
         C.ind = loop_structure(C.str);
         
         function I = loop_structure(S)
            I = struct;
            for name = string(fieldnames(S))'
               if isstruct(S.(name))
                  I.(name) = loop_structure(S.(name));
               else
                  if ~iscell(S.(name))
                     indices = add({S.(name)});
                     I.(name) = indices{:};
                  else
                     I.(name) = add(S.(name));
                  end
               end
            end
         end

         function indices = add(array)
           sz = size(array);
            indices = cell(sz);
            for i_1 = 1:sz(1)
               for i_2 = 1:sz(2)
                  object = array{i_1,i_2};
                  N_elements = numel(object);
                  indices{i_1,i_2} = C.len + reshape(1:N_elements,size(object));
                  vector = [vector; reshape(object,N_elements,1)]; %#ok<AGROW>
                  C.len = C.len + N_elements;
               end
            end
         end
         C.vec = vector;
      end

      function genvec_scalar_mixed(C)

         vector = [];
         C.len = 0;
         C.ind = loop_structure(C.str);
         
         function I = loop_structure(S)
            I = struct;
            while ~isempty(fieldnames(S))
               for name = string(fieldnames(S))'
                  if isstruct(S.(name))
                     I.(name) = loop_structure(S.(name));
                     S = rmfield(S,name);
                  elseif ~numel(S.(name))
                     S = rmfield(S,name);
                  else
                     if ~isfield(I,name)
                        I.(name) = nan(size(S.(name)));
                        S.(name) = reshape(S.(name),numel(S.(name)),1);
                     end
                     vector = [vector; S.(name)(1)]; %#ok<AGROW>
                     S.(name) = S.(name)(2:end);
                     C.len = C.len + 1;
                     I.(name)(find(isnan(I.(name)),1)) = C.len;
                  end
               end
            end
         end
         C.vec = vector;
      end

      function genvec_vector_mixed(C)

         vector = [];
         C.len = 0;
         C.ind = loop_structure(C.str);
         
         function I = loop_structure(S)
            I = struct;
            while ~isempty(fieldnames(S))
               for name = string(fieldnames(S))'
                  if isstruct(S.(name))
                     I.(name) = loop_structure(S.(name));
                     S = rmfield(S,name);
                  elseif ~numel(S.(name))
                     S = rmfield(S,name);
                  else
                     if ~isfield(I,name)
                        I.(name) = [];
                     end
                     to_add = S.(name)(:,1);
                     vector = [vector; to_add]; %#ok<AGROW>
                     I.(name) = [I.(name) C.len+(1:numel(to_add))'];
                     C.len = C.len + numel(to_add);
                     S.(name) = S.(name)(:,2:end);
                  end
               end
            end
         end
         C.vec = vector;
      end
   end



   methods(Static)
      function help
         disp('====== help: "structor" ======')
         disp(' - PROPERTIES:')
         disp('     "str" - a structure containing fields that are either cell arrays or dictionaries.')
         disp('     "vec" - a vector containing all end-elements of "str".')
         disp('     "len" - the length of "vec".')
         disp('     "ind" - a copy of the "str" structure, but the values are instead the indices of the elements position within "vec".')
         disp(' - METHODS:')
         disp('     "genvec" - generates "vec", and updates "ind".')
      end

   end
end