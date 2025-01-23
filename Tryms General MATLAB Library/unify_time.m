function [t_out,x_out] = unify_time(t,x,options)

arguments(Input,Repeating)
   t (1,:) double {mustBeReal}
   x (:,:) double {mustBeReal} % expecting time axis in horizontal direction (dim 2)
end
arguments(Input)
   options.dt (1,1) double {mustBePositive} % use this to manually set the increment of the new timeseries (default: smallest average time increment of the two series is used)
end
arguments(Output)
   t_out (1,:) double {mustBeReal}
end
arguments(Output,Repeating)
   x_out (:,:) double {mustBeReal}
end

%{
 takes multiple trejectories:
   (t1,x1):
             - [x1_1, x1_2, ... , x1_N]
             - [t1_1, t1_2, ... , t1_N]
   (t2,x2):
             - [x2_1, x2_2, ... , x2_N]
             - [t2_1, t2_2, ... , t2_N]
and computes a common set of time points and (linearly) interpolates both x-series
onto the new time grid.

Note: both trajectories must be stricly increasing in time, to be
interpolable.
%}

n = length(t);
t_min = t{1}(1);
t_max = t{1}(end);
for i = 2:n
   t_min = max(t{i}(1),t_min);
   t_max = min(t{i}(end),t_max);
end

if isfield(options,'dt')
   dt = options.dt;
else
   for i = 1:n
      dt = sum(t{1}([1 end]))/(length(t{1})-1);
   end
end

t_out = t_min:dt:t_max; % better to use linespace? (prolly doesn't matter)

x_out = cell(1,n);
for i = 1:n
   x_out{i} = transpose(interp1(t{i},transpose([x{i};zeros(1,size(x{i},2))]),t_out));
   x_out{i} = x_out{i}(1:end-1,:);
end


end