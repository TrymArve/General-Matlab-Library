function[color] = colorgradient(options)

arguments
   options.values (1,:) double = [0 1];
   options.colors (:,1) cell = { [0  , 150, 255]/255; [253, 218,  13]/255; [210,   4,  45]/255 };
end

n = length(options.colors);

sa = sort(options.values);
if ~(n == length(options.values) || length(options.values)==2) || any(options.values ~= sa) || any(sa(2:end) == sa(1:end-1))
   error('USER ERROR: "values" must be a row array of exacly two values, or the same length as the number of colors, in srictly ascending order.')
end

if length(options.values)==2
   values = linspace(options.values(1), options.values(end), n);
end

colors = cell2mat(options.colors);
color  = @(x) interp1(values,colors,x);

end