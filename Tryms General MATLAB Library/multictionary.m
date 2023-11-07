classdef multictionary < handle

   properties(SetAccess = private)
      n_keys (1,1) double {mustBeNonnegative,mustBeReal} = 0;
      in (1,1) dictionary = configureDictionary("cell","double"); % holds key to prime factor mapping
      out (1,1) dictionary = configureDictionary("double","cell"); % hold product to output mapping
   end

   methods
      function C = multictionary()

      end


      function out = get(C,varargin)
         product = 1;
         for key = varargin
            product = C.in(key)*product;
         end
         out = C.out{product};
      end

      function C = set(C,value,varargin)
         keys = varargin;
         
         out_product = 1;

         for key = keys

            if isKey(C.in,key)
               prime = C.in(key);
            else
               C.n_keys = C.n_keys + 1; 
               prime = nthprime(C.n_keys);
               C.in(key) = prime;              
            end
            out_product = out_product*prime;
         end

         C.out(out_product) = {value};
      end

   end
end