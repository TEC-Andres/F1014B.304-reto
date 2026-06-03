%% entregable2.m
clear; clc;
addpath("lib")

sup = nodoMagnetoMecanico();
sup.cylinder.rx = 1;
sup.cylinder.ry = 1;
sup.cylinder.height = 3;
sup.cylinder.z0 = 30;
sup.cylinder.color = [0.2 0.6 0.8];

% Toro (iniciando desde el 2 con altura de 12 m)
sup.torus.R = 3.6;
sup.torus.r = 0.5;
sup.torus.center = [0 0 2];
sup.torus.height = 12;
sup.torus.color = [0.9 0.6 0.2];

% Piso
sup.ground.isSquare = true;
sup.ground.size = max(sup.cylinder.rx, sup.cylinder.ry)*2.5; % half-side length
sup.ground.z0 = 0;
sup.ground.color = [0.8 0.8 0.8];

% Tamaño de paso por segundo
stepDt = 0.05;
startZ = sup.cylinder.z0;

% Configure UI fields to match script parameters
sup.EditField.Value = startZ;
sup.EditField2.Value = sup.torus.R;

% Run simulation programmatically (blocking) and then save figures
sup.runFallEngine([], stepDt);

hist = sup.getHistory();
outdir = fullfile(pwd, 'outputs');
if ~exist(outdir, 'dir')
	mkdir(outdir);
end

if isempty(hist.t)
    warning('No simulation history recorded. Run may have been interrupted.');
else
    t = hist.t;
    z = hist.z;
    F = hist.F_mag;

    % Define common palette based on the UI screenshot
    bgColor = '#F6F4E8';
    textColor = '#202020';

    % 1) z vs t compared with free-fall
    g = 9.81;
    z_free = startZ - 0.5 * g .* (t.^2);
    f1 = figure('Visible','off', 'Color', bgColor);
    
    % Simulated z in bright Sunlight Gold
    plot(t, z, '-', 'Color', '#FFD700', 'LineWidth', 1.6); hold on;
    % Free fall in Sunrise Orange-Red
    plot(t, z_free, '--', 'Color', '#FF4500', 'LineWidth', 1.2);
    
    % Customize axes and text colors
    ax1 = gca;
    ax1.Color = bgColor;
    ax1.XColor = textColor;
    ax1.YColor = textColor;
    grid on;
    
    xlabel('Time (s)', 'Color', textColor); 
    ylabel('z (m)', 'Color', textColor); 
    title('Posición z vs Tiempo', 'Color', textColor);
    
    lgd = legend('Simulated z','Free fall','Location','best');
    lgd.TextColor = textColor;
    lgd.Color = bgColor;
    lgd.EdgeColor = textColor;
    
    saveas(f1, fullfile(outdir, 'z_vs_time.png'));
    saveas(f1, fullfile(outdir, 'z_vs_time.fig'));
    close(f1);

    % 2) Force vs position
    f2 = figure('Visible','off', 'Color', bgColor);
    
    % Force in Warm Bright Orange
    plot(z, F, '-', 'Color', '#FFA500', 'LineWidth', 1.6);
    
    % Customize axes and text colors
    ax2 = gca;
    ax2.Color = bgColor;
    ax2.XColor = textColor;
    ax2.YColor = textColor;
    grid on;
    
    xlabel('Posición z (m)', 'Color', textColor); 
    ylabel('F_{mag} (N)', 'Color', textColor); 
    title('Fuerza total sobre el imán vs Posición', 'Color', textColor);
    
    saveas(f2, fullfile(outdir, 'force_vs_position.png'));
    saveas(f2, fullfile(outdir, 'force_vs_position.fig'));
    close(f2);

    % 3) Force vs time
    f3 = figure('Visible','off', 'Color', bgColor);
    
    % Force in Deep Amber / Sun Orange
    plot(t, F, '-', 'Color', '#FF8C00', 'LineWidth', 1.6);
    
    % Customize axes and text colors
    ax3 = gca;
    ax3.Color = bgColor;
    ax3.XColor = textColor;
    ax3.YColor = textColor;
    grid on;
    
    xlabel('Tiempo (s)', 'Color', textColor); 
    ylabel('F_{mag} (N)', 'Color', textColor); 
    title('Fuerza total sobre el imán vs Tiempo', 'Color', textColor);
    
    saveas(f3, fullfile(outdir, 'force_vs_time.png'));
    saveas(f3, fullfile(outdir, 'force_vs_time.fig'));
    close(f3);
end

% Launch the interactive plot/UI
sup.plotLoop();


