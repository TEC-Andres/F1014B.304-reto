%% nodoGraficas.m
% Genera gráficas de la simulación y las guarda en outputs/
classdef nodoGraficas < handle
    properties (Access = private)
        sim
        outdir
    end

    methods (Access = public)
        function obj = nodoGraficas(simObj)
            obj.sim = simObj;
            obj.outdir = fullfile(pwd, 'outputs');
            if ~exist(obj.outdir, 'dir')
                mkdir(obj.outdir);
            end
        end

        function run(obj, stepDt)
            if nargin < 2 || isempty(stepDt)
                stepDt = 0.05;
            end
            startZ = obj.sim.EditField.Value;
            obj.sim.runFallEngine([], stepDt);
            hist = obj.sim.getHistory();
            if isempty(hist.t)
                warning('No simulation history recorded.');
                return;
            end
            obj.plotZvsTime(hist, startZ);
            obj.plotForceVsPosition(hist);
            obj.plotForceVsTime(hist);
            obj.plotFEMVsPosition(hist);
            obj.plotCurrentVsPosition(hist);
        end

        function plotZvsTime(obj, hist, startZ)
            t = hist.t;
            z = hist.z;
            g = 9.81;
            z_free = startZ - 0.5 * g .* (t.^2);
            bgColor = '#F6F4E8';
            textColor = '#202020';
            f = figure('Visible','off', 'Color', bgColor);
            plot(t, z, '-', 'Color', '#FFD700', 'LineWidth', 1.6); hold on;
            plot(t, z_free, '--', 'Color', '#FF4500', 'LineWidth', 1.2);
            ax = gca; ax.Color = bgColor; ax.XColor = textColor; ax.YColor = textColor;
            grid on;
            xlabel('Time (s)', 'Color', textColor);
            ylabel('z (m)', 'Color', textColor);
            title('Posición z vs Tiempo', 'Color', textColor);
            lgd = legend('Simulated z','Free fall','Location','best');
            lgd.TextColor = textColor; lgd.Color = bgColor; lgd.EdgeColor = textColor;
            saveas(f, fullfile(obj.outdir, 'z_vs_time.png'));
            saveas(f, fullfile(obj.outdir, 'z_vs_time.fig'));
            close(f);
        end

        function plotForceVsPosition(obj, hist)
            z = hist.z;
            F = hist.F_mag;
            bgColor = '#F6F4E8';
            textColor = '#202020';
            f = figure('Visible','off', 'Color', bgColor);
            plot(z, F, '-', 'Color', '#FFA500', 'LineWidth', 1.6);
            ax = gca; ax.Color = bgColor; ax.XColor = textColor; ax.YColor = textColor;
            grid on;
            xlabel('Posición z (m)', 'Color', textColor);
            ylabel('F_{mag} (N)', 'Color', textColor);
            title('Fuerza total sobre el imán vs Posición', 'Color', textColor);
            saveas(f, fullfile(obj.outdir, 'force_vs_position.png'));
            saveas(f, fullfile(obj.outdir, 'force_vs_position.fig'));
            close(f);
        end

        function plotForceVsTime(obj, hist)
            t = hist.t;
            F = hist.F_mag;
            bgColor = '#F6F4E8';
            textColor = '#202020';
            f = figure('Visible','off', 'Color', bgColor);
            plot(t, F, '-', 'Color', '#FF8C00', 'LineWidth', 1.6);
            ax = gca; ax.Color = bgColor; ax.XColor = textColor; ax.YColor = textColor;
            grid on;
            xlabel('Tiempo (s)', 'Color', textColor);
            ylabel('F_{mag} (N)', 'Color', textColor);
            title('Fuerza total sobre el imán vs Tiempo', 'Color', textColor);
            saveas(f, fullfile(obj.outdir, 'force_vs_time.png'));
            saveas(f, fullfile(obj.outdir, 'force_vs_time.fig'));
            close(f);
        end

        function plotFEMVsPosition(obj, hist)
            z = hist.z;
            FEM = hist.FEM;
            bgColor = '#F6F4E8';
            textColor = '#202020';
            f = figure('Visible','off', 'Color', bgColor);
            plot(z, FEM, '-', 'Color', '#FF0000', 'LineWidth', 1.6);
            ax = gca; ax.Color = bgColor; ax.XColor = textColor; ax.YColor = textColor;
            grid on;
            xlabel('Posición del imán z (m)', 'Color', textColor);
            ylabel('FEM Inducida (V)', 'Color', textColor);
            title('Evolución de la FEM según la posición del Imán', 'Color', textColor);
            xline(obj.sim.torus.ring_z(1), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
            saveas(f, fullfile(obj.outdir, 'fem_vs_position.png'));
            saveas(f, fullfile(obj.outdir, 'fem_vs_position.fig'));
            close(f);
        end

        function plotCurrentVsPosition(obj, hist)
            z = hist.z;
            I = hist.I_ind;
            bgColor = '#F6F4E8';
            textColor = '#202020';
            f = figure('Visible','off', 'Color', bgColor);
            plot(z, I, '-', 'Color', '#0000FF', 'LineWidth', 1.6);
            ax = gca; ax.Color = bgColor; ax.XColor = textColor; ax.YColor = textColor;
            grid on;
            xlabel('Posición del imán z (m)', 'Color', textColor);
            ylabel('Corriente Inducida (A)', 'Color', textColor);
            title('Evolución de la Corriente según la posición del Imán', 'Color', textColor);
            xline(obj.sim.torus.ring_z(1), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
            saveas(f, fullfile(obj.outdir, 'current_vs_position.png'));
            saveas(f, fullfile(obj.outdir, 'current_vs_position.fig'));
            close(f);
        end
    end
end
