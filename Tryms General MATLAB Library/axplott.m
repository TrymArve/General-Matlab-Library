function[] = axplott(ax,x,y,addleg,varargin)
% o	Circle
% +	Plus sign
% *	Asterisk
% .	Point
% x	Cross
% s	Square
% d	Diamond
% ^	Upward-pointing triangle
% v	Downward-pointing triangle
% >	Right-pointing triangle
% <	Left-pointing triangle
% p	Pentagram
% h	Hexagram


% Get Info:
ny = size(y,1);
F = gcf;
L = legend();
s = L.String;

% Plot Data:
hold on
P = plot(ax,x,y,varargin{:});


% Colors and Legends
% if isprop(F.CurrentAxes,'NumberOfDataClusters_Trym')
%     Clusters = F.CurrentAxes.NumberOfDataClusters_Trym+1;
%     F.CurrentAxes.NumberOfDataClusters_Trym = Clusters;
% else
%     Clusters = 1;
%     try
%     F.CurrentAxes = addprop(F.CurrentAxes,'NumberOfDataClusters_Trym');
%     catch
%     end
%     F.CurrentAxes.NumberOfDataClusters_Trym = 1;
% end



if ny > 1
    ind = find(string(varargin{:}) == "Color");
    if ~isempty(ind)
        color = varargin{ind+1};
    else
        color = [0 0 0];
    end
    colors = {};
    Multi_Legs = {};
    for i = 1:ny
        Multi_Legs{end+1} = [addleg,'_',num2str(i)];
        colors{end+1} = color + [1 1 1]*(i/ny);
    end
    set(P, {'Color'}, colors')
    legend([s, Multi_Legs(:)'])
else
    legend([s, {addleg}])
end
   

end