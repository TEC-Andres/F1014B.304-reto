%% windowHandler 
% UI/UX realizado en appDesigner, mejorado en VSC
classdef windowHandler < matlab.apps.AppBase

    properties (Access = public)
        UIFigure          matlab.ui.Figure
        ControlPanel      matlab.ui.container.Panel
        titleLabel        matlab.ui.control.Label
        EditField3        matlab.ui.control.NumericEditField
        EditField3Label   matlab.ui.control.Label
        EditField2        matlab.ui.control.NumericEditField
        EditField2Label   matlab.ui.control.Label
        TimeSlider        matlab.ui.control.Slider
        EditField         matlab.ui.control.NumericEditField
        EditFieldLabel    matlab.ui.control.Label
        Button            matlab.ui.control.Button

        % FEMFieldLabel     matlab.ui.control.Label
        % FEMField          matlab.ui.control.NumericEditField
        UIAxes            matlab.ui.control.UIAxes
        InfoLabel         matlab.ui.control.Label 
    end

    properties (Access = private)
        COLOR_BG           = [0.992, 0.965, 0.894]; 
        COLOR_AXES         = [0.396, 0.482, 0.514]; 
        COLOR_ESPIRA       = [0.149, 0.545, 0.824]; 
        COLOR_LINEA        = [0.796, 0.294, 0.086]; 
        COLOR_ORIGEN       = [0.992, 0.965, 0.894]; 
        COLOR_LINEA_TIEMPO = [0.165, 0.631, 0.596]; 
        COLOR_FLECHAS      = [0.165, 0.631, 0.596]; 
    end

    methods (Access = public)
        function resizeInfoLabel(app)
            pos = app.UIFigure.Position;
            W = pos(3); H = pos(4);
            lblW = 200; lblH = 110;
            topMargin = H * 0.02;
            leftMargin = W * 0.02;
            app.InfoLabel.Position = [leftMargin, H - lblH - topMargin - (H*0.05), lblW, lblH];
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Color = app.COLOR_BG;
            app.UIFigure.Name = 'Entregable II | Hijos de Gauss';            
            app.UIFigure.SizeChangedFcn = @(~, ~) app.resizeInfoLabel();

            rootGrid = uigridlayout(app.UIFigure, [2, 1]);
            rootGrid.RowHeight = {'0.05x', '1x'}; 
            rootGrid.ColumnWidth = {'1x'};
            rootGrid.Padding = [0 0 0 0];
            rootGrid.BackgroundColor = app.COLOR_BG;

            mainGrid = uigridlayout(rootGrid, [2, 2]);
            mainGrid.ColumnWidth = {260, '1x'}; 
            mainGrid.RowHeight = {'1x', 40};
            mainGrid.Padding = [8 8 8 8];
            mainGrid.Layout.Row = 2;
            mainGrid.Layout.Column = 1;
            mainGrid.BackgroundColor = app.COLOR_BG;

            app.ControlPanel = uipanel(mainGrid);
            app.ControlPanel.Title = '';
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;
            app.ControlPanel.BackgroundColor = app.COLOR_BG;
            app.ControlPanel.BorderType = 'none';

            app.UIAxes = uiaxes(mainGrid);
            title(app.UIAxes, 'Simulación', 'Color', app.COLOR_AXES)
            xlabel(app.UIAxes, 'Eje X (m)', 'Color', app.COLOR_AXES)
            ylabel(app.UIAxes, 'Eje Y (m)', 'Color', app.COLOR_AXES)
            zlabel(app.UIAxes, 'Altura (m)', 'Color', app.COLOR_AXES)
            app.UIAxes.Color = app.COLOR_BG;
            app.UIAxes.XColor = app.COLOR_AXES;
            app.UIAxes.YColor = app.COLOR_AXES;
            app.UIAxes.ZColor = app.COLOR_AXES;
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = 2;

            app.TimeSlider = uislider(mainGrid);
            app.TimeSlider.Layout.Row = 2;
            app.TimeSlider.Layout.Column = 2;
            app.TimeSlider.Limits = [0 3];
            app.TimeSlider.Value = 0;

            grid = uigridlayout(app.ControlPanel, [13, 1]);
            grid.RowHeight = {'1x', 'fit', 30, 10, 'fit', 30, 10, 'fit', 30, 10, 'fit', 10, '1x'};
            grid.ColumnWidth = {'1x'};
            grid.Padding = [10 10 10 10];
            grid.BackgroundColor = app.COLOR_BG;

            app.EditFieldLabel = uilabel(grid);
            app.EditFieldLabel.Layout.Row = 2;
            app.EditFieldLabel.Layout.Column = 1;
            app.EditFieldLabel.HorizontalAlignment = 'center';
            app.EditFieldLabel.Text = 'Altura de caída (m)';
            app.EditFieldLabel.FontColor = app.COLOR_AXES;

            app.EditField = uieditfield(grid, 'numeric');
            app.EditField.Layout.Row = 3;
            app.EditField.Layout.Column = 1;
            app.EditField.BackgroundColor = [1 1 1];
            app.EditField.FontColor = app.COLOR_AXES;
            app.EditField.Value = 30;
            app.EditField.Limits = [10 35];
            app.EditField.ValueChangedFcn = @(src,event) app.clampRadius(src,event);

            app.EditField2Label = uilabel(grid);
            
            app.EditField2Label.Layout.Row = 5;
            app.EditField2Label.Layout.Column = 1;
            app.EditField2Label.HorizontalAlignment = 'center';
            app.EditField2Label.Text = 'Radio del toro (m)';
            app.EditField2Label.FontColor = app.COLOR_AXES;

            app.EditField2 = uieditfield(grid, 'numeric');
            app.EditField2.Layout.Row = 6;
            app.EditField2.Layout.Column = 1;
            app.EditField2.BackgroundColor = [1 1 1];
            app.EditField2.FontColor = app.COLOR_AXES;
            app.EditField2.Value = 4.6; % Default torus radius
            app.EditField2.Limits = [3 5];
            app.EditField2.ValueChangedFcn = @(src,event) app.clampTorusRadius(src,event);

            app.EditField3Label = uilabel(grid);
            app.EditField3Label.Layout.Row = 8;
            app.EditField3Label.Layout.Column = 1;
            app.EditField3Label.HorizontalAlignment = 'center';
            app.EditField3Label.Text = 'Dipolo Magnético (A*m^2)';
            app.EditField3Label.FontColor = app.COLOR_AXES;

            app.EditField3 = uieditfield(grid, 'numeric');
            app.EditField3.Layout.Row = 9;
            app.EditField3.Layout.Column = 1;
            app.EditField3.BackgroundColor = [1 1 1];
            app.EditField3.FontColor = app.COLOR_AXES;
            app.EditField3.Value = 1.4e7; % Default dipole
            app.EditField3.Limits = [1e7 9e7];
            app.EditField3.ValueChangedFcn = @(src,event) app.clampDipole(src,event);

            app.Button = uibutton(grid, 'push');
            app.Button.Layout.Row = 11;
            app.Button.Layout.Column = 1;
            app.Button.Text = 'Correr simulación';
            app.Button.BackgroundColor = [0.992, 0.827, 0.384];
            app.Button.FontColor = app.COLOR_AXES;

            app.titleLabel = uilabel(rootGrid);
            app.titleLabel.Layout.Row = 1;
            app.titleLabel.Layout.Column = 1;
            app.titleLabel.HorizontalAlignment = 'center';
            app.titleLabel.FontWeight = 'bold';
            app.titleLabel.Text = 'Simulación de caida de la góndola';
            app.titleLabel.FontColor = app.COLOR_AXES;
            app.titleLabel.BackgroundColor = app.COLOR_BG;
            
            app.InfoLabel = uilabel(app.UIFigure);
            app.InfoLabel.HorizontalAlignment = 'left';
            app.InfoLabel.VerticalAlignment = 'top';
            app.InfoLabel.FontName = 'Courier';
            app.InfoLabel.FontColor = app.COLOR_AXES;
            app.InfoLabel.BackgroundColor = app.COLOR_BG;
            app.InfoLabel.Text = 'Esperando la simulación...';
            app.resizeInfoLabel();

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = windowHandler
            createComponents(app)
            registerApp(app, app.UIFigure)
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end