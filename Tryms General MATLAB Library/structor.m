classdef structor < handle

   %{
structor - is meant to be a "struct" data type and a vector (standing
tuple) at the same time. 

It has a struct-part; "str" and a vector-part; "vec".

The idea is that where you would normally need a vector, you may create a
stuct instead, so that all variables/values are nicely organized into various fields of the struct, similarly to
folders in a computer. This way you have more control over the values, and
it is easier to work with, than a vector where all variables/values are
bundled into one long vector. Retrieving the values from that vector would
be a nigtmare.

By using a structor, you may add values to the stuct part;
"my_stuctor.str", and then access the equivalent vector via the vector
part; "my_structor.vec".

Whenever the vec property is accessed, the vector is generated based on the
struct, if it has not already been generated since the last time the str
property was modified.

The vector that is generated currently has three different ways it stacks
the elements of the struct into a vector:
1) "separated": goes throught the fields of the struct, each time adding
the enitre array stored in the field to the vector, reshaping it to a
standing vector.
2) "vector_mixed": goes through all fields, each time only adding the fist
column of the array stored in the field. This is repeated until all
fields-arrays have been full added to the vector.
3) "scalar_mixed": goes through all field of the struct, each time adding
only the first element of the field-array. repeat until all elements of all
fields have been added to the vector.


If you modify the vector in some way, then need to revtrieve the values,
you may simply access the correct index my using

"new_vector(my_structor.ind.(*field to access*)", 
or 
retrieve the whole structure by using 
"new_structor = my_structor.retrieve(new_vector)"


In the future:
- "str" will be automatically updated based on updates in the vector part.
- the class will keep track of what has bee modified, and only re-generate the
modified parts of the vector/struct
--- this is a more memory intensive approach than simply recomputing
everything each time, but it should be faster.
- upon initializing a new structor, onw may choose the fast or the
low-memory version.
   %}


   properties
      str (1,1) struct = struct % a structure containing arrays of stuff
      default_mix (1,1) string {mustBeMember(default_mix,["separated","scalar_mixed","vector_mixed"])} = "separated";
   end
   properties(SetAccess = private)
      vec (:,1) % vector consisting of all elements of the arrays of the struct-filds, at indices descbribed by "ind"
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




   % Copy etc.
   methods
      function new_structor = copy(C)
         new_structor = structor(default_mix=C.default_mix);
         new_structor.str = C.str;
      end


      function retrieved_structor = retrieve(C,vector)
         retrieved_structor = structor(default_mix=C.default_mix);
         retrieved_structor.str = loop_structure(C.str,C.ind);

         function S_out = loop_structure(S,I)
            S_out = struct;
            for name = string(fieldnames(S))'
               if isstruct(S.(name))
                  S_out.(name) = loop_structure(S.(name),I.(name));
               else
                  S_out.(name) = reshape(vector(I.(name)),size(S.(name)));
               end
            end
         end
      end


      function retrieved_structor = interp(C,original_samples,new_samples)
         
         new_samples(new_samples>original_samples(end)) = original_samples(end);
         new_samples(new_samples<original_samples(1)) = original_samples(1);

         retrieved_structor = structor(default_mix=C.default_mix);
         retrieved_structor.str = loop_structure(C.str);

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

      function new_structor = subcopy(C,str)
         new_structor = structor(default_mix=C.default_mix);
         new_structor.str = loop_structure(C.str,str);

         function S_out = loop_structure(O,S)
            S_out = struct;
            for name = string(fieldnames(S))'
               if isfield(O,name)
                  if isstruct(S.(name))
                     S_out.(name) = loop_structure(O.(name),S.(name));
                  else
                     S_out.(name) = O.(name);
                  end
               end
            end
         end
      end

      function out = zeros(C)
         out = C.retrieve(zeros(C.len,1));
      end

      function out = ones(C)
         out = C.retrieve(ones(C.len,1));
      end
   end




   methods(Static)
      function help
         disp(' ')
         disp('====================== help: "structor" =======================')
         disp(' - PROPERTIES:')
         disp('            "str" - a structure containing fields that are either cell arrays or dictionaries.')
         disp('            "vec" - a vector containing all end-elements of "str".')
         disp('            "len" - the length of "vec".')
         disp('            "ind" - a copy of the "str" structure, but the values are instead the indices of the elements position within "vec".')
         disp(' "default_mixing" - the order in which to mix the elements of the struct-fields into a single vector.')
         disp('                    ->     "separated": stacks the fields in order of appearance in the struct.')
         disp('                    ->  "vector_mixed": stacks the first column of each struct-field, then the second columns, etc.')
         disp('                    ->  "scalar_mixed": adds first element of each struct-field, then the second element, etc.')
         disp(' - METHODS:')
         disp('     "genvec" - generates "vec", and updates "ind".')
         disp('       "copy" - creates a copy of the sturctor instance. This is handy since the class is a handle-class.')
         disp('    "subcopy" - creates a copy only of the fields similar to the reference structure provided by argument.')
         disp('   "retrieve" - creates a new structor with the same fields as the current structor, where the struct-fields are based on the vector you provide.')
         disp('                 This enables you to generate a vector of your sturct, then modify the vector and retrieve the equivalent struct from that changed vector.')
         disp('     "interp" - creates a new structor where all fields are interpolated based on an "original" sample vector and a "new" sample vector.')
         disp('                 Each field is linearly interpolated as if the columns are the values at each sample.')
         disp('                 i.e: the number of columns of each field must be the same as the number elements of the "original" sample vector.')
         disp('                 The output stuct-fields then have the same number of columns as the "new" sample vector.')
         disp('                  (if any struct-field has fewer columns than elements of the original sample vector, then the columns are mapped to the first elements of the sample vector, and the rest are ignored.)')
         disp('===============================================================')
         disp(' ')
      end

   end
end