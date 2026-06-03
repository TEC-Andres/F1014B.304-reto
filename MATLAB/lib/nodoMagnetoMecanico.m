%% nodoMagnetoMecanico.m
% Fusión de nodoDeFuerza y nodoDeElectromagnetismo
% Simula la caída libre con frenado magnético y renderiza los campos.
classdef nodoMagnetoMecanico < superficies

    properties (Access = private)
        % Constantes físicas
        g = 9.81           % Gravedad
        m = 1200           % Masa del cilindro (kg)
        mu_0 = 4*pi*1e-7   % Permeabilidad del vacío
        mu_dipole = 8.6e6  % Momento dipolar magnético del cilindro (A*m^2)
        R_res = 1e-4       % Resistencia eléctrica del anillo (Ohms)
        
        % Handles para las flechas (quiver3)
        hQuiverCyl = []
        hQuiverTor = []
        
        % Estado de simulación
        isPlaying = false
    end

    methods
        function I = metodoDeRomberg(~, f, a, b, tol)
        % Integración numérica usando el método de Romberg
        if nargin < 5
            tol = 1e-6;
        end
        
        max_iter = 12; % Límite de iteraciones para evitar cuelgues
        R = zeros(max_iter, max_iter);
        h = b - a;
        
        % Evaluar los extremos
        R(1,1) = (h/2) * (f(a) + f(b));
        
        for i = 2:max_iter
            h = h / 2;
            sum_term = 0;
            for k = 1:2^(i-2)
                sum_term = sum_term + f(a + (2*k-1)*h);
            end
            R(i,1) = 0.5 * R(i-1,1) + h * sum_term;
            
            for j = 2:i
                R(i,j) = R(i,j-1) + (R(i,j-1) - R(i-1,j-1)) / (4^(j-1) - 1);
            end
            
            % Condición de salida si se alcanza la tolerancia
            if i > 3 && abs(R(i,i) - R(i-1,i-1)) < tol
                I = R(i,i);
                return;
            end
        end
        I = R(max_iter, max_iter); % Retornar mejor esfuerzo si no converge
    end


        function obj = nodoMagnetoMecanico()
            obj = obj@superficies();
            obj.plotLoop();
        end

        function bindRunButton(obj, callback)
            obj.Button.ButtonPushedFcn = @(~, ~) callback();
        end
        % AQUI %
        function runFallEngine(obj, startZ, dt)
        if nargin < 2 || isempty(startZ)
            startZ = obj.cylinder.z0;
        end
        if nargin < 3 || isempty(dt)
            dt = 0.05;
        end

        obj.Button.Enable = 'off';
        obj.isPlaying = true;
        
        z = startZ;
        v = 0;
        a = -obj.g;
        
        a_ring = obj.torus.R;          
        z_torus = obj.torus.center(3); 
        H = obj.torus.height; % Altura del tubo (Asegúrate de agregar esto en superficies.m)
        
        % Límites de integración (Fondo y Tope del tubo)
        z_bottom = z_torus - H/2;
        z_top = z_torus + H/2;
        
        suelo = obj.cylinder.height / 2;

        try
            while z > suelo && obj.isPlaying
                
                % 1. Definir la función a integrar (Fuerza de un anillo diferencial)
                % Usamos la derivación combinada de Faraday + Fuerza magnética
                const_term = (9 * obj.mu_0^2 * obj.mu_dipole^2 * a_ring^4 * v) / (4 * obj.R_res);
                force_integrand = @(zp) -const_term .* (z - zp).^2 ./ ((z - zp).^2 + a_ring^2).^5;
                
                % 2. Integrar usando el método de Romberg
                F_mag = obj.metodoDeRomberg(force_integrand, z_bottom, z_top, 1e-4);
                
                % 3. Actualización de movimiento (Integración de Euler)
                a_old = a;
                a = -obj.g + (F_mag / obj.m); 
                jerk = (a - a_old) / dt;
                
                v = v + a * dt;
                z = z + v * dt;
                
                if z < suelo
                    z = suelo;
                    v = 0; % Detener al tocar el piso
                end
                
                % --- Para visualización (Quiver) ---
                % Calcular una corriente "total" aproximada integrando I_ind a lo largo del tubo
                % I_ind_slice = (3 * mu_0 * mu_dipole * a^2 * (z-zp) * v) / (2 * R_res * ((z-zp)^2 + a^2)^(5/2))
                I_const = (3 * obj.mu_0 * obj.mu_dipole * a_ring^2 * v) / (2 * obj.R_res);
                current_integrand = @(zp) I_const .* (z - zp) ./ ((z - zp).^2 + a_ring^2).^(5/2);
                I_ind_total = obj.metodoDeRomberg(current_integrand, z_bottom, z_top, 1e-3);
                
                % 4. Renderizado
                obj.setCylinderPose(z);
                obj.plotLoop(true); 
                obj.renderMagneticFields(z, z_torus, I_ind_total);
                
                appText = sprintf('V: %.2f | A: %.2f | F_mag: %.2f', v, a, F_mag);
                obj.UIFigure.Name = appText;
                
                drawnow;
            end
        catch ME
            obj.Button.Enable = 'on';
            obj.isPlaying = false;
            rethrow(ME);
        end
        
        obj.isPlaying = false;
        obj.Button.Enable = 'on';
    end

    end

    methods (Access = private)
        function renderMagneticFields(obj, z_cyl, z_torus, I_ind)
            ax = obj.UIAxes;
            hold(ax, 'on');
            
            scale = 2.0; % Factor de escala para hacer las flechas visibles
            
            % ==========================================
            % 1. CAMPO DEL CILINDRO (Imán Permanente)
            % ==========================================
            % Obtener las dimensiones reales del cilindro
            r_cyl = max(obj.cylinder.rx, obj.cylinder.ry);
            h_cyl = obj.cylinder.height;
            z_center = z_cyl + h_cyl/2; % El verdadero centro magnético
            
            % Crear una cuadrícula 3D que envuelva dinámicamente al cilindro
            % (Desde -3 veces su radio hasta +3 veces su radio)
            [Xc, Yc, Zc] = meshgrid(linspace(-r_cyl*3, r_cyl*3, 6), ...
                                    linspace(-r_cyl*3, r_cyl*3, 6), ...
                                    linspace(z_center - h_cyl*2, z_center + h_cyl*2, 6));
            
            % Vector de posición relativo al CENTRO del cilindro
            rx = Xc; 
            ry = Yc; 
            rz = Zc - z_center; 
            r_mag = sqrt(rx.^2 + ry.^2 + rz.^2) + 1e-5; 
            
            % Momento dipolar del cilindro orientado en Z
            m_vec_cyl = [0, 0, obj.mu_dipole];
            dot_pr_c = m_vec_cyl(3) .* rz; 
            
            % Aplicar fórmula del dipolo
            Bx_c = (obj.mu_0 / (4*pi)) * (3 * rx .* dot_pr_c ./ r_mag.^5);
            By_c = (obj.mu_0 / (4*pi)) * (3 * ry .* dot_pr_c ./ r_mag.^5);
            Bz_c = (obj.mu_0 / (4*pi)) * (3 * rz .* dot_pr_c ./ r_mag.^5 - m_vec_cyl(3) ./ r_mag.^3);
            
            % Opcional: Ocultar flechas que queden DENTRO del cilindro físico para mayor claridad
            inside_cyl = (sqrt(rx.^2 + ry.^2) < r_cyl) & (abs(rz) < h_cyl/2);
            Bx_c(inside_cyl) = 0;
            By_c(inside_cyl) = 0;
            Bz_c(inside_cyl) = 0;
            
            % Normalización para la visualización
            B_norm_c = sqrt(Bx_c.^2 + By_c.^2 + Bz_c.^2) + 1e-5;
            
            % Dibujar o actualizar Quiver del Cilindro
            if isempty(obj.hQuiverCyl) || ~isgraphics(obj.hQuiverCyl)
                obj.hQuiverCyl = quiver3(ax, Xc, Yc, Zc, ...
                    (Bx_c./B_norm_c)*scale, (By_c./B_norm_c)*scale, (Bz_c./B_norm_c)*scale, ...
                    0, 'Color', [0.149, 0.545, 0.824], 'LineWidth', 1.2);
            else
                set(obj.hQuiverCyl, 'XData', Xc, 'YData', Yc, 'ZData', Zc, ...
                    'UData', (Bx_c./B_norm_c)*scale, ...
                    'VData', (By_c./B_norm_c)*scale, ...
                    'WData', (Bz_c./B_norm_c)*scale);
            end
            
            % ==========================================
            % 2. CAMPO DEL TUBO/TOROIDE (Corriente Inducida)
            % ==========================================
            if abs(I_ind) > 1e-6
                % Ajustamos la cuadrícula estática al tamaño del tubo
                R_tubo = obj.torus.R;
                H_tubo = obj.torus.height;
                
                [Xt, Yt, Zt] = meshgrid(linspace(-R_tubo-3, R_tubo+3, 5), ...
                                        linspace(-R_tubo-3, R_tubo+3, 5), ...
                                        linspace(z_torus - H_tubo/2 - 2, z_torus + H_tubo/2 + 2, 5));
                
                rt_x = Xt; 
                rt_y = Yt; 
                rt_z = Zt - z_torus;
                rt_mag = sqrt(rt_x.^2 + rt_y.^2 + rt_z.^2) + 1e-5;
                
                % Momento dipolar total aproximado del tubo
                m_ind_mag = pi * R_tubo^2 * I_ind;
                dot_pr_t = m_ind_mag .* rt_z;
                
                Bx_t = (obj.mu_0 / (4*pi)) * (3 * rt_x .* dot_pr_t ./ rt_mag.^5);
                By_t = (obj.mu_0 / (4*pi)) * (3 * rt_y .* dot_pr_t ./ rt_mag.^5);
                Bz_t = (obj.mu_0 / (4*pi)) * (3 * rt_z .* dot_pr_t ./ rt_mag.^5 - m_ind_mag ./ rt_mag.^3);
                
                Bt_norm = sqrt(Bx_t.^2 + By_t.^2 + Bz_t.^2) + 1e-5;
                
                if isempty(obj.hQuiverTor) || ~isgraphics(obj.hQuiverTor)
                    obj.hQuiverTor = quiver3(ax, Xt, Yt, Zt, ...
                        (Bx_t./Bt_norm)*scale, (By_t./Bt_norm)*scale, (Bz_t./Bt_norm)*scale, ...
                        0, 'Color', [0.796, 0.294, 0.086], 'LineWidth', 1.2);
                else
                    % Si el tubo es estático, solo actualizamos los vectores U, V, W
                    set(obj.hQuiverTor, 'XData', Xt, 'YData', Yt, 'ZData', Zt, ...
                                        'UData', (Bx_t./Bt_norm)*scale, ...
                                        'VData', (By_t./Bt_norm)*scale, ...
                                        'WData', (Bz_t./Bt_norm)*scale);
                end
            else
                if ~isempty(obj.hQuiverTor) && isgraphics(obj.hQuiverTor)
                    set(obj.hQuiverTor, 'UData', zeros(size(get(obj.hQuiverTor, 'UData'))), ...
                                        'VData', zeros(size(get(obj.hQuiverTor, 'VData'))), ...
                                        'WData', zeros(size(get(obj.hQuiverTor, 'WData'))));
                end
            end
            
            hold(ax, 'off');
        end
    end
end