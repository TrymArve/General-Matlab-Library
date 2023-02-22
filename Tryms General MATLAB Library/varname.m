function[names] = varname(varargin)

    for i = 1:length(varargin)
        names(i) = string(inputname(i));
    end

end