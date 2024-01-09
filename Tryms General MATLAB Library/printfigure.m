function printfigure(filename,options)

% Code taken from youtube video:
% "https://www.youtube.com/watch?v=wP3jjk1O18A"
% by PhysicsLaure.

   arguments
      filename
      options.columntype string {ismember(options.columntype,["single","double"])} = "single";
      options.fig = gcf;
      options.hw_ratio double {mustBePositive} = 0.65;
      options.fontsize double {mustBePositive} = 10;
      options.filetype string {ismember(options.filetype,["-dpdf","-dpng"])} = "pdf";

      options.keep_Lims = "on";
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



   set(findall(hfig,'-property','FontSize'),'FontSize',fontsize)
   set(findall(hfig,'-property','Box'),'Box','off') % optional
   set(findall(hfig,'-property','Interpreter'),'Interpreter','latex')
   set(findall(hfig,'-property','TickLabelInterpreter'),'TickLabelInterpreter','latex')
   set(hfig,'Units','centimeters','Position',[3 3 picturewidth hw_ratio*picturewidth])
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
