function[color] = TemperatureColorCodeHandle   (T_min,T_max,cold,luke,warm)

    if nargin == 2
        cold = [0  , 150, 255]/255;
        luke = [253, 218,  13]/255;
        warm = [210,   4,  45]/255;
    end
    
    T_max = T_max + 0.000001; % To prevent error when T_min = T_max
    
    color  = @(T) interp1([T_min, (T_max + T_min)/2, T_max],[cold; luke; warm],T);

end


