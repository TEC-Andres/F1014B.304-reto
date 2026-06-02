%% windowHandler 
% UI/UX realizado en appDesigner, mejorado en VSC
classdef windowHandler < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        ControlPanel                  matlab.ui.container.Panel
        THISISAMAGNIFICENTTITLELabel  matlab.ui.control.Label
        EditField3                    matlab.ui.control.NumericEditField
        EditField3Label               matlab.ui.control.Label
        EditField2                    matlab.ui.control.NumericEditField
        EditField2Label               matlab.ui.control.Label
        TimeSlider                    matlab.ui.control.Slider
        EditField                     matlab.ui.control.NumericEditField
        EditFieldLabel                matlab.ui.control.Label
        Button                        matlab.ui.control.Button
        UIAxes                        matlab.ui.control.UIAxes
    end

    % Component initialization
    properties (Access = private)
        % Solarized-light-ish palette (approximate)
        COLOR_BG           = [0.992, 0.965, 0.894]; % base3 - background (soft off-white)
        COLOR_AXES         = [0.396, 0.482, 0.514]; % base00 - foreground (muted slate)
        COLOR_ESPIRA       = [0.149, 0.545, 0.824]; % blue - primary plot color
        COLOR_LINEA        = [0.796, 0.294, 0.086]; % orange - accent
        COLOR_ORIGEN       = [0.992, 0.965, 0.894]; % origin - match background
        COLOR_LINEA_TIEMPO = [0.165, 0.631, 0.596]; % cyan/teal - time line
        COLOR_FLECHAS      = [0.165, 0.631, 0.596]; % cyan/teal - arrows/accents
    end

    methods (Access = private)
        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            % Apply background color (solarized light)
            app.UIFigure.Color = app.COLOR_BG;
            app.UIFigure.Name = 'Entregable II | Hijos de Gauss';

            rootGrid = uigridlayout(app.UIFigure, [2, 1]);
            rootGrid.RowHeight = {'0.05x', '1x'}; % first ~3% for title, rest for UI
            rootGrid.ColumnWidth = {'1x'};
            rootGrid.Padding = [0 0 0 0];
            rootGrid.BackgroundColor = app.COLOR_BG;

            % Create main grid inside the bottom row: left column fixed for controls, right column stretches for axes
            mainGrid = uigridlayout(rootGrid, [2, 2]);
            mainGrid.ColumnWidth = {260, '1x'}; % left panel fixed 260px, right column flexible
            mainGrid.RowHeight = {'1x', 40};
            mainGrid.Padding = [8 8 8 8];
            mainGrid.Layout.Row = 2;
            mainGrid.Layout.Column = 1;
            mainGrid.BackgroundColor = app.COLOR_BG;

            % Create ControlPanel to group inputs and center them (fixed-width column)
            app.ControlPanel = uipanel(mainGrid);
            app.ControlPanel.Title = '';
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;
            app.ControlPanel.BackgroundColor = app.COLOR_BG;
            app.ControlPanel.BorderType = 'none';

            % Create UIAxes in the flexible right column so it grows with the window
            app.UIAxes = uiaxes(mainGrid);
            % Axes styling for light (muted labels, off-white background)
            title(app.UIAxes, 'Title', 'Color', app.COLOR_AXES)
            xlabel(app.UIAxes, 'X', 'Color', app.COLOR_AXES)
            ylabel(app.UIAxes, 'Y', 'Color', app.COLOR_AXES)
            zlabel(app.UIAxes, 'Z', 'Color', app.COLOR_AXES)
            app.UIAxes.Color = app.COLOR_BG;
            app.UIAxes.XColor = app.COLOR_AXES;
            app.UIAxes.YColor = app.COLOR_AXES;
            app.UIAxes.ZColor = app.COLOR_AXES;
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = 2;

            % Create TimeSlider below the axes for simulation playback
            app.TimeSlider = uislider(mainGrid);
            app.TimeSlider.Layout.Row = 2;
            app.TimeSlider.Layout.Column = 2;
            app.TimeSlider.Limits = [0 3];
            app.TimeSlider.Value = 0;

                
            % Use a grid layout inside the panel so controls flex with width
            % Create a grid with top and bottom flexible rows so content is vertically centered
            grid = uigridlayout(app.ControlPanel, [12, 1]);
            grid.RowHeight = {'1x', 'fit', 30, 10, 'fit', 30, 10, 'fit', 30, 10, 'fit', '1x'};
            grid.ColumnWidth = {'1x'};
            grid.Padding = [10 10 10 10];
            grid.BackgroundColor = app.COLOR_BG;

            % Create EditFieldLabel (centered in grid)
            app.EditFieldLabel = uilabel(grid);
            app.EditFieldLabel.Layout.Row = 2;
            app.EditFieldLabel.Layout.Column = 1;
            app.EditFieldLabel.HorizontalAlignment = 'center';
            app.EditFieldLabel.Text = 'Edit Field';
            app.EditFieldLabel.FontColor = app.COLOR_AXES;

            % Create EditField (flexes to grid column width)
            app.EditField = uieditfield(grid, 'numeric');
            app.EditField.Layout.Row = 3;
            app.EditField.Layout.Column = 1;
            app.EditField.BackgroundColor = [1 1 1];
            app.EditField.FontColor = app.COLOR_AXES;

            % Create EditField2Label (centered)
            app.EditField2Label = uilabel(grid);
            app.EditField2Label.Layout.Row = 5;
            app.EditField2Label.Layout.Column = 1;
            app.EditField2Label.HorizontalAlignment = 'center';
            app.EditField2Label.Text = 'Edit Field2';
            app.EditField2Label.FontColor = app.COLOR_AXES;

            % Create EditField2 (flexes)
            app.EditField2 = uieditfield(grid, 'numeric');
            app.EditField2.Layout.Row = 6;
            app.EditField2.Layout.Column = 1;
            app.EditField2.BackgroundColor = [1 1 1];
            app.EditField2.FontColor = app.COLOR_AXES;

            % Create EditField3Label (centered)
            app.EditField3Label = uilabel(grid);
            app.EditField3Label.Layout.Row = 8;
            app.EditField3Label.Layout.Column = 1;
            app.EditField3Label.HorizontalAlignment = 'center';
            app.EditField3Label.Text = 'Edit Field3';
            app.EditField3Label.FontColor = app.COLOR_AXES;

            % Create EditField3 (flexes)
            app.EditField3 = uieditfield(grid, 'numeric');
            app.EditField3.Layout.Row = 9;
            app.EditField3.Layout.Column = 1;
            app.EditField3.BackgroundColor = [1 1 1];
            app.EditField3.FontColor = app.COLOR_AXES;

            % Create Button (fills grid column)
            app.Button = uibutton(grid, 'push');
            app.Button.Layout.Row = 11;
            app.Button.Layout.Column = 1;
            app.Button.Text = 'Run Simulation';
            app.Button.BackgroundColor = [0.992, 0.827, 0.384];
            app.Button.FontColor = app.COLOR_AXES;

            % Create THISISAMAGNIFICENTTITLELabel in the top reserved area
            app.THISISAMAGNIFICENTTITLELabel = uilabel(rootGrid);
            app.THISISAMAGNIFICENTTITLELabel.Layout.Row = 1;
            app.THISISAMAGNIFICENTTITLELabel.Layout.Column = 1;
            app.THISISAMAGNIFICENTTITLELabel.HorizontalAlignment = 'center';
            app.THISISAMAGNIFICENTTITLELabel.FontWeight = 'bold';
            app.THISISAMAGNIFICENTTITLELabel.Text = 'THIS IS A MAGNIFICENT TITLE';
            app.THISISAMAGNIFICENTTITLELabel.FontColor = app.COLOR_AXES;
            app.THISISAMAGNIFICENTTITLELabel.BackgroundColor = app.COLOR_BG;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = windowHandler

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end