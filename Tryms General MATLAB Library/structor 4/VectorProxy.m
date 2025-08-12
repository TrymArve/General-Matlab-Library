


   % -------- VectorProxy definition --------
   classdef VectorProxy < handle
      properties (Access = private)
         parent
      end
      methods
         function obj = VectorProxy(parent)
            obj.parent = parent;
         end
         function out = subsref(obj, S)
            if strcmp(S(1).type, '()')
               if ~obj.parent.cacheValid
                  obj.parent.buildMapping();
               end
               vecData = obj.toVector();
               out = builtin('subsref', vecData, S);
            else
               error('Unsupported indexing');
            end
         end
         function obj2 = subsasgn(obj, S, val)
            if strcmp(S(1).type, '()')
               if ~obj.parent.cacheValid
                  obj.parent.buildMapping();
               end
               idxList = builtin('subsref', 1:numel(obj), S);
               if numel(val) ~= numel(idxList)
                  error('Assignment dimension mismatch');
               end
               for k = 1:numel(idxList)
                  map = obj.parent.mappingCache.vec2store{idxList(k)};
                  storeIdx = map{1};
                  arr = obj.parent.masterStore{storeIdx};
                  if numel(map) == 2
                     arr(map{2}) = val(k);
                  elseif numel(map) == 3
                     if obj.parent.mix == "row"
                        arr(map{2}, map{3}) = val(k);
                     elseif obj.parent.mix == "column"
                        arr(map{3}, map{2}) = val(k);
                     elseif obj.parent.mix == "scalar"
                        arr(1) = val(k);
                     end
                  end
                  obj.parent.masterStore{storeIdx} = arr;
               end
               obj2 = obj;
            else
               error('Unsupported indexing');
            end
         end
         function n = numel(obj,varargin)
            if ~obj.parent.cacheValid
               obj.parent.buildMapping();
            end
            n = numel(obj.parent.mappingCache.vec2store);
         end
         function v = toVector(obj)
            if ~obj.parent.cacheValid
               obj.parent.buildMapping();
            end
            v = [];
            for k = 1:numel(obj.parent.mappingCache.vec2store)
               map = obj.parent.mappingCache.vec2store{k};
               arr = obj.parent.masterStore{map{1}};
               if numel(map) == 2
                  v(end+1,1) = arr(map{2});
               elseif numel(map) == 3
                  if obj.parent.mix == "row"
                     v(end+1,1) = arr(map{2}, map{3});
                  elseif obj.parent.mix == "column"
                     v(end+1,1) = arr(map{3}, map{2});
                  elseif obj.parent.mix == "scalar"
                     v(end+1,1) = arr(1);
                  end
               end
            end
         end
      end
   end