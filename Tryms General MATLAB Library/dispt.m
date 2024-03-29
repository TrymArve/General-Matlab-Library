function[] = dispt(varargin)

L = length(varargin);
i = 1;
    while i <= L
    
        if isa(varargin{i},'char') || isa(varargin{i},'string') % if it is text
    
            fprintf([varargin{i},' \t \t'])
            i = i+1;
             % if the next is NOT a string, and IS a row-vector, then print
             % before going to new line:
            if (i <= L) && (isa(varargin{i},'double')) && (size(varargin{i},1) == 1) && (length(size(varargin{i})) < 3)
                fprintf(num2str(varargin{i}))
                %disp(varargin{i})
                i = i+1;
            end

            % If the next is a string that starts with "~~", then print
            % before going to new line
            if (i <= L) && (isa(varargin{i},'string') || isa(varargin{i},'char'))
                text = char(varargin{i});
                if (length(text) > 2) && (text(1) == '~') && (text(2) == '~')
                fprintf(text(3:end))
                i = i+1;
                end
            end
            disp(' ')
        else
            disp(varargin{i})
            i = i+1;
        end
    
    end

end
