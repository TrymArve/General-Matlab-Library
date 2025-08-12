   % -------- StructProxy definition --------
   classdef StructProxy < handle
      properties (Access = private)
         parent
         path
      end
      methods
         function obj = StructProxy(parent, path)
            obj.parent = parent;
            obj.path = path;
         end
         function out = subsref(obj, S)
            if strcmp(S(1).type, '.')
               newPath = S(1).subs;
               if obj.path ~= ""
                  newPath = obj.path + "." + newPath;
               end
               % Check if field exists as leaf
               idx = find(strcmp(obj.parent.pathList, newPath),1);
               if isempty(idx)
                  % Return new StructProxy for substruct
                  out = structor4.StructProxy(obj.parent, newPath);
               else
                  out = obj.parent.masterStore{idx};
               end
               if numel(S) > 1
                  out = builtin('subsref', out, S(2:end));
               end
            else
               error('Unsupported indexing');
            end
         end
         function obj2 = subsasgn(obj, S, val)
            if strcmp(S(1).type, '.')
               newPath = S(1).subs;
               if obj.path ~= ""
                  newPath = obj.path + "." + newPath;
               end
               idx = find(strcmp(obj.parent.pathList, newPath),1);
               if isempty(idx)
                  obj.parent.pathList{end+1} = newPath;
                  obj.parent.masterStore{end+1} = val;
                  obj.parent.cacheValid = false;
               else
                  if numel(S) == 1
                     obj.parent.masterStore{idx} = val;
                  else
                     obj.parent.masterStore{idx} = builtin('subsasgn', obj.parent.masterStore{idx}, S(2:end), val);
                  end
               end
               obj2 = obj;
            else
               error('Unsupported indexing');
            end
         end
      end
   end