classdef random < handle
   properties
      type (1,1) string
      augmentation (1,1) function_handle = @(rand) rand
      minimum double = -inf;
      maximum double = inf;
      memory (1,1) double {mustBeInteger, mustBePositive} = 2;
      momentum (1,1) double {mustBeInRange(momentum,0,1)} = 0.5;
      weights (1,:)
      weight_type (1,1) string = "mean";
   end
   properties(SetAccess=private)
      walk double = [0 0];
      r double = [0 0];
   end

   methods
      function C = random(options)
         arguments
            options.type (1,1) string {mustBeMember(options.type,["independent","wandering","drunk","heavy"])} = "wandering";
         end
         C.type = options.type;
         C.set_weights
      end


      function new = new(C)
         C.r(end+1) = rand-0.5;
         switch C.type
            case "independent"
               new = C.r(end);%sign(C.r(end))*C.r(end)^2;
            case "wandering"
               new = C.walk(end) + C.momentum*(C.walk(end)-C.walk(end-1)) + (1-C.momentum)*sum(C.r(end-C.memory+1:end).*C.weights);
            case "drunk"
               % C.walk(end+1) = C.walk(end) +  + (1-C.momentum)*C.r(end);
         end
         new = C.augmentation(new);
         new = max(C.minimum,new);
         new = min(C.maximum,new);
         C.walk(end+1) = new;
      end

      function new_walk(C,n)
         arguments
            C; n (1,1) double {mustBeInteger,mustBePositive} = 100;
         end
         C.walk = [0 0];
         for i = 1:n
            C.new;
         end
      end

      function set.memory(C,value)
         C.memory = value;
         C.set_weights
         if length(C.r) < value %#ok<MCSUP>
            C.r = [zeros(1,value) C.r]; %#ok<MCSUP>
         end
      end

      function set_weights(C)
         switch C.weight_type
            case "mean"
               C.weights = ones(1,C.memory)/C.memory;
            case "taper"
               C.weights = 1;
               for i = 2:C.memory
                  C.weights(end+1) = C.weights(end)/2;
               end
               C.weights = C.weights/sum(C.weights);
            case "reverse taper"
               C.weights = 1;
               for i = 2:C.memory
                  C.weights(end+1) = C.weights(end)/2;
               end
               C.weights = C.weights(end:-1:1)/sum(C.weights);
         end
      end

      function set.weight_type(C,type)
         arguments
            C
            type string {mustBeMember(type,["mean","taper","reverse taper"])}
         end
         C.weight_type = type;
         C.set_weights;
      end
   end
end