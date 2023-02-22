function[str] = num2strt(number,characters)

% Tryms function for converting numbers to strings with a specified number
% of charecters. 
% This is useful to handle numbers when you don't know if the number has a
% point(".") in it or not

    str = num2str(number);

    L = length(str);
    p = L - characters;
   
    DOT = find(str == '.',1);
  
    if isempty(DOT)
        if p < 0
        c = char;
        c(1) = '.';
        c(2:-p) = '0';
        str = [str, c];
        end
    else
        if p >= 0 && characters > DOT
            str = str(1:characters);
        else
            c = char;
            c(1:-p) = '0';
            str = [str, c];
        end
    end
  




end