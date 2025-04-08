function present(S)
   arguments
      S (1,1) struct
   end

text = '| FIELDS :';
disp(text)
width = length(text);

loop(S,width)

   function loop(S,width)
      
         names = field2str(S);
         width = max([width+3 strlength(names)]);
         for name = names
            disp_name = repmat(' ',[1,width]);
            disp_name = ['|',disp_name]; %#ok<*AGROW>
            disp_name(end-strlength(name)+1:end) = char(name);
            disp_name = [disp_name,':  '];
            
            if isstruct(S.(name))
               disp(disp_name)
               loop(S.(name),width)
            elseif class(S.(name)) == "casadi.SX"
               if isscalar(S.(name))
                  fprintf([disp_name,'(casadi.SX) (1,1) '])
                  var = S.(name);
                  try
                     if is_zero(var)
                        var_name = '0';
                     else
                        var_name = var.name;
                     end
                  catch
                     var_name = '<expr>';
                  end
                  disp(var_name)
               else
                  [nx,ny] = size(S.(name));
                  vec = '[';
                  for x = 1:nx
                     for y = 1:ny
                        var = S.(name)(x,y);
                        try
                           if is_zero(var)
                              var_name = '0';
                           else
                              var_name = var.name;
                           end
                        catch
                           var_name = '<expr>';
                        end
                        vec = [vec, var_name,' '];
                     end
                     vec = [vec(1:end-1), '; '];
                  end
                  vec = [vec(1:end-2), ']'];
                  disp([disp_name,'(casadi.SX) (',num2str(nx),',',num2str(ny),') ',vec])
               end
            else
               [nx,ny] = size(S.(name));
               fprintf([disp_name,'(',class(S.(name)),') (',num2str(nx),',',num2str(ny),') '])
               disp(reshape(S.(name),1,[]))
            end
         end
   end
end