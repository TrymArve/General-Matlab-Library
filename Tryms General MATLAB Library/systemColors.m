function systemColors(colorscheme,options)
   arguments
      colorscheme string {mustBeMember(colorscheme,["Trym's Dark","Christmas"])}
      options.ValueType string {mustBeMember(options.ValueType,["TemporaryValue"])} = "TemporaryValue";
   end

   s = settings;

   switch colorscheme
      case "Trym's Dark"

         %%% General:
         s.matlab.colors.KeywordColor.(options.ValueType) = [0 190 190];
         s.matlab.colors.StringColor.(options.ValueType) = [200 150 250];
         s.matlab.colors.CommentColor.(options.ValueType) = [118 171 48];
         s.matlab.colors.ValidationSectionColor.(options.ValueType) = [199 101 55];
         s.matlab.colors.UnterminatedStringColor.(options.ValueType) = [181 47 42];
         s.matlab.colors.SyntaxErrorColor.(options.ValueType) = [197 77 120];
         s.matlab.colors.SystemCommandColor.(options.ValueType) = [165 127 28];

         %%% Command Window:
         s.matlab.colors.commandwindow.HyperlinkColor.(options.ValueType) = [68 134 217];
         s.matlab.colors.commandwindow.ErrorColor.(options.ValueType) = [213 87 87];
         s.matlab.colors.commandwindow.WarningColor.(options.ValueType) = [215 124 18];

         %%% Programming Tools:
         % flags
         s.matlab.colors.programmingtools.HighlightAutofixes.(options.ValueType) = 1;
         s.matlab.colors.programmingtools.AutomaticallyHighlightVariables.(options.ValueType) = 1;
         s.matlab.colors.programmingtools.ShowVariablesWithSharedScope.(options.ValueType) = 1;
         % colors
         s.matlab.colors.programmingtools.VariablesWithSharedScopeColor.(options.ValueType) = [159 243 243];
         s.matlab.colors.programmingtools.AutofixHighlightColor.(options.ValueType) = [120 111 67];
         s.matlab.colors.programmingtools.VariableHighlightColor.(options.ValueType) = [91 112 93];
         s.matlab.colors.programmingtools.CodeAnalyzerWarningColor.(options.ValueType) = [222 125 0];

         %%% Editor:
         s.matlab.editor.displaysettings.HighlightCurrentLineColor.(options.ValueType) = [229 250 221];

         background = 80/255*[1 1 1];
         com.mathworks.services.Prefs.setColorPref('ColorsBackground', java.awt.Color(background(1),background(2),background(3)))
         com.mathworks.services.ColorPrefs.notifyColorListeners('ColorsBackground');

         text = 190/255*[1 1 1];
         com.mathworks.services.Prefs.setColorPref('ColorsText', java.awt.Color(text(1),text(2),text(3)))
         com.mathworks.services.ColorPrefs.notifyColorListeners('ColorsText');

      case "Christmas"

         %%% General:
         s.matlab.colors.KeywordColor.(options.ValueType) = [200 100 100]; % Changed
         s.matlab.colors.StringColor.(options.ValueType) = [42, 166, 131]; % changed
         s.matlab.colors.CommentColor.(options.ValueType) = [74, 162, 22]; % changed
         s.matlab.colors.ValidationSectionColor.(options.ValueType) = [200 100 100]; % changed
         s.matlab.colors.UnterminatedStringColor.(options.ValueType) = [1, 23, 29];% changed
         s.matlab.colors.SyntaxErrorColor.(options.ValueType) = [29, 2, 2]; % changed
         s.matlab.colors.SystemCommandColor.(options.ValueType) = [200 100 100];  % changed


         %%% Command Window:
         s.matlab.colors.commandwindow.HyperlinkColor.(options.ValueType) = [130, 154, 114]; % changed
         s.matlab.colors.commandwindow.ErrorColor.(options.ValueType) = [206, 141, 35]; % changed
         s.matlab.colors.commandwindow.WarningColor.(options.ValueType) = [206, 93, 34]; % changed

         %%% Programming Tools:
         % flags
         s.matlab.colors.programmingtools.HighlightAutofixes.(options.ValueType) = 1;
         s.matlab.colors.programmingtools.AutomaticallyHighlightVariables.(options.ValueType) = 1;
         s.matlab.colors.programmingtools.ShowVariablesWithSharedScope.(options.ValueType) = 1;
         % colors
         s.matlab.colors.programmingtools.VariablesWithSharedScopeColor.(options.ValueType) =[208, 18, 17];
         s.matlab.colors.programmingtools.AutofixHighlightColor.(options.ValueType) = round([81, 41, 41]*0.9);
         s.matlab.colors.programmingtools.VariableHighlightColor.(options.ValueType) = round([81, 41, 41]*1.4);
         s.matlab.colors.programmingtools.CodeAnalyzerWarningColor.(options.ValueType) = [200 100 100];

         %%% Editor:
         s.matlab.editor.displaysettings.HighlightCurrentLineColor.(options.ValueType) = [229 250 221];
         
         % background = [81, 41, 41]./255;
         % background = [100, 40, 40]./255;
         % background = [100, 62, 62]./255;
         background = [93, 37, 37]./255;
         com.mathworks.services.Prefs.setColorPref('ColorsBackground', java.awt.Color(background(1),background(2),background(3)))
         com.mathworks.services.ColorPrefs.notifyColorListeners('ColorsBackground');

         text = [203, 188, 164]/255;
         com.mathworks.services.Prefs.setColorPref('ColorsText', java.awt.Color(text(1),text(2),text(3)))
         com.mathworks.services.ColorPrefs.notifyColorListeners('ColorsText');

      otherwise
         disp('Unrecognized color scheme.')
   end

end