function[str] = num2strt(number,characters,options)

arguments
   number (1,1) double
   characters (1,1) double {mustBeInteger,mustBePositive}
   options.padding (1,1) string {mustBeMember(options.padding,["right","left"])} = "right";
end
% Tryms function for converting numbers to strings with a specified number
% of charecters. 
% This is useful to handle numbers when you don't know if the number has a
% point(".") in it or not

% OLD version:
    % str = num2str(number);
    % 
    % L = length(str);
    % p = L - characters;
    % 
    % DOT = find(str == '.',1);
    % 
    % if isempty(DOT)
    %     if p < 0
    %     c = char;
    %     c(1) = '.';
    %     c(2:-p) = '0';
    %     str = [str, c];
    %     end
    % else
    %     if p >= 0 && characters > DOT
    %         str = str(1:characters);
    %     else
    %         c = char;
    %         c(1:-p) = '0';
    %         str = [str, c];
    %     end
    % end
  
   % New version
   str = num2str(number);
   DOT = find(str == '.',1);
   missing = characters - length(str);

   if missing > 0
      switch options.padding
         case "right"
            str = [str, repmat(' ',1,missing)];
         case "left"
            str = [repmat(' ',1,missing), str];
      end
   elseif ~isempty(DOT)
      str = str(1:characters);
   end




end