function printfigure(filename,options)

% | Code taken from youtube video:
% |       "https://www.youtube.com/watch?v=wP3jjk1O18A"
% |          - by PhysicsLaure. (2023)
% |  Use
% |       "printfigure(filename,options)"
% |  to save a nice-looking pdf of your
% |  figure, ready for use in a nice report/article
% | 
% |  The option: "fig" allows you to specify what figure is printed.
% |  Otherwise it prints the current figure (gcf)
% | 
% |  Use "columntype" to specify if the figure is used for a double of single
% |  type article. This determines the size of the figure. (default "single")
% | 
% |  "hw_ratio" determines the aspect ratio (default 0.65)
% |  "fontsize" determines the fontsize (default 10)
% |  "filetype" determines what filetype: "pdf" or "png" (default "pdf")
% | 
% |  "keep_Lims" = "on" (default) makes sure the limits of the plot axes are not
% |  changed.

   arguments
      filename
      options.columntype (1,1) string {ismember(options.columntype,["single","double"])} = "single";
      options.fig matlab.ui.Figure = gcf;
      options.hw_ratio (1,1) double {mustBePositive} = 0.65;
      options.fontsize (1,1) double {mustBePositive} = 10;
      options.filetype (1,1) string {mustBeMember(options.filetype,["pdf","png"])} = "pdf";
      options.picturewidth (1,1) double {mustBeNonnegative} = 0;
      options.keep_size (1,1) logical = false;
      options.keep_font (1,1) logical = false;
      options.keep_Lims (1,1) string {mustBeMember(options.keep_Lims,["on","off"])} = "on";
   end
   
   hfig = options.fig;
   hw_ratio = options.hw_ratio; % feel free to play with this ratio
   fontsize = options.fontsize; % adjust fontsize to your document
   
   if options.columntype == "single"
      picturewidth = 15; % set this parameter and keep it forever for continuity in your work
   elseif options.columntype == "double"
      picturewidth = 9; % set this parameter and keep it forever for continuity in your work
   else
      error('invalid columntype.')
   end
   options.picturewidth
   if options.picturewidth ~= 0
      picturewidth = options.picturewidth;
   end
   
   if options.keep_Lims == "on" 
      % store all limits:
      Axes = findall(hfig,'-property','XLim');
      Lax = length(Axes);
      XLims = cell(1,Lax);
      YLims = cell(1,Lax);
      for i = 1:Lax
         XLims(i) = {Axes(i).XLim};
         YLims(i) = {Axes(i).YLim};
      end
   end


   % Manage Font
   if ~options.keep_font
   set(findall(hfig,'-property','FontSize'),'FontSize',fontsize)
   set(findall(hfig,'-property','Box'),'Box','off') % optional
   set(findall(hfig,'-property','Interpreter'),'Interpreter','latex')
   set(findall(hfig,'-property','TickLabelInterpreter'),'TickLabelInterpreter','latex')
   end

   % set size:
   if options.keep_size
      pos = get(hfig,'Position');
   else
      pos = [3 3 picturewidth hw_ratio*picturewidth];
   end
   set(hfig,'Units','centimeters','Position',[3 3 pos(3), pos(4)])
   pos = get(hfig,'Position');
   set(hfig,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3), pos(4)])




   if options.keep_Lims == "on" 
      % restore all limits:
      for i = 1:Lax
         Axes(i).XLim = XLims{i};
         Axes(i).YLim = YLims{i};
      end
   end



   if options.filetype == "pdf"
      exportgraphics(hfig,[char(filename),'.pdf'],'ContentType','vector')
   elseif options.filetype == "png"
      exportgraphics(hfig,[char(filename),'.png'],'ContentType','image')
   else
      error('Invalid filetype.')
   end
end
