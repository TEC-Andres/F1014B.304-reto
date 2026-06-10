%% nodoMagnetoMecanico.m
% Fusión de nodoDeFuerza y nodoDeElectromagnetismo
% Simula la caída libre con frenado magnético y renderiza los campos.
classdef nodoMagnetoMecanico < superficies
    properties (Access = private)
        g = 9.81           
        m = 1200           
        mu_0 = 4*pi*1e-7   
        mu_dipole = 3e7  
        R_res = 1e-4       
        
        hQuiverCyl = []
        hQuiverTor = []
        
        isPlaying = false
        
        % Inicializar historial para slider
        history = struct('t',[], 'z',[], 'v',[], 'a',[], 'jerk',[], 'F_mag',[], 'I_ind',[])
    end

    methods
        function I = metodoDeRomberg(~, f, a, b, tol)
            if nargin < 5
                tol = 1e-6;
            end
            max_iter = 12; 
            R = zeros(max_iter, max_iter);
            h = b - a;
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
                if i > 3 && abs(R(i,i) - R(i-1,i-1)) < tol
                    I = R(i,i);
                    return;
                end
            end
            I = R(max_iter, max_iter); 
        end

        function obj = nodoMagnetoMecanico()
            obj = obj@superficies();
            
            obj.TimeSlider.ValueChangingFcn = @(src, event) obj.onSliderChanging(src, event);
            obj.TimeSlider.ValueChangedFcn  = @(src, event) obj.onSliderChanged(src, event);
            
            obj.plotLoop();
        end

        function bindRunButton(obj, callback)
            obj.Button.ButtonPushedFcn = @(~, ~) callback();
        end

        function bindGraficasButton(obj, callback)
            obj.GraficasButton.ButtonPushedFcn = @(~, ~) callback();
        end

        function hist = getHistory(obj)
            hist = obj.history;
        end

        function runFallEngine(obj, ~, dt)
            if nargin < 3 || isempty(dt)
                dt = 0.05;
            end            
            startZ = obj.EditField.Value;
            obj.torus.R = obj.EditField2.Value;
            obj.mu_dipole = obj.EditField3.Value;
    
            obj.Button.Enable = 'off';
            obj.isPlaying = true;
            
            z = startZ;
            v = 0;
            a = -obj.g;
            t = 0;
            
            a_ring = obj.torus.R;          
            ring_z = obj.torus.ring_z;
            ring_h = obj.torus.ring_h;
            N = numel(ring_z);
            suelo = obj.cylinder.height / 2;
            
            % Liberar memoria
            obj.history = struct('t',[], 'z',[], 'v',[], 'a',[], 'jerk',[], 'F_mag',[], 'I_ind',[]);
    
            try
                while z > suelo && obj.isPlaying
                    const_term = (9 * obj.mu_0^2 * obj.mu_dipole^2 * a_ring^4 * v) / (4 * obj.R_res);
                    F_mag = 0;
                    for k = 1:N
                        dz = z - ring_z(k);
                        F_mag = F_mag + (-const_term * dz^2 / (dz^2 + a_ring^2)^5) * ring_h;
                    end
                    
                    a_old = a;
                    a = -obj.g + (F_mag / obj.m); 
                    jerk = (a - a_old) / dt;
                    
                    v = v + a * dt;
                    z = z + v * dt;
                    t = t + dt;
                    
                    if z < suelo
                        z = suelo;
                        v = 0; 
                    end
                    
                    I_const = (3 * obj.mu_0 * obj.mu_dipole * a_ring^2 * v) / (2 * obj.R_res);
                    I_ind_total = 0;
                    for k = 1:N
                        dz = z - ring_z(k);
                        I_ind_total = I_ind_total + (I_const * dz / (dz^2 + a_ring^2)^(5/2)) * ring_h;
                    end
                    
                    % Save state for slider functionality
                    obj.history.t(end+1) = t;
                    obj.history.z(end+1) = z;
                    obj.history.v(end+1) = v;
                    obj.history.a(end+1) = a;
                    obj.history.jerk(end+1) = jerk;
                    obj.history.F_mag(end+1) = F_mag;
                    obj.history.I_ind(end+1) = I_ind_total;
                    
                    % Dynamically update the slider
                    obj.TimeSlider.Limits = [0, max(0.01, t)];
                    obj.TimeSlider.Value = t;
                    
                    obj.setCylinderPose(z);
                    obj.plotLoop(true); 
                    obj.renderMagneticFields(z, ring_z, v);
                    obj.updateInfoLabel(z, v, a, jerk, (obj.m * obj.g), F_mag);
                    
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
        
        % Slider callback hookups
        function onSliderChanging(obj, ~, event)
            obj.updateFromTime(event.Value);
        end

        function onSliderChanged(obj, ~, event)
            obj.updateFromTime(event.Value);
        end
        
        function updateFromTime(obj, tVal)
            if isempty(obj.history.t)
                return;
            end
            % Lookup closest recorded history point
            [~, idx] = min(abs(obj.history.t - tVal));
            
            z = obj.history.z(idx);
            v = obj.history.v(idx);
            a = obj.history.a(idx);
            jerk = obj.history.jerk(idx);
            F_mag = obj.history.F_mag(idx);
            
            obj.setCylinderPose(z);
            obj.plotLoop(true);
            obj.renderMagneticFields(z, obj.torus.ring_z, v);
            obj.updateInfoLabel(z, v, a, jerk, (obj.m * obj.g), F_mag);
        end
        
        % Leyenda de info
        function updateInfoLabel(obj, z, v, a, jerk, W, F_mag)
            str = sprintf('Pos (z) : %8.2f m\nVel (v) : %8.2f m/s\nAcc (a) : %8.2f m/s²\nJerk (j): %8.2f m/s³\nWeight  : %8.2f N\nF_mag   : %8.2f N', z, v, a, jerk, W, F_mag);
            obj.InfoLabel.Text = str;
        end

        % Render de flechas 
        function renderMagneticFields(obj, z_cyl, ring_z, v)
            ax = obj.UIAxes;
            hold(ax, 'on');
            scale = 2.0; 
            
            % ==========================================
            % 1. CAMPO DEL CILINDRO
            % ==========================================
            r_cyl = max(obj.cylinder.rx, obj.cylinder.ry);
            h_cyl = obj.cylinder.height;
            z_center = z_cyl + h_cyl/2; 
            
            [Xc, Yc, Zc] = meshgrid(linspace(-r_cyl*3, r_cyl*3, 6), ...
                                    linspace(-r_cyl*3, r_cyl*3, 6), ...
                                    linspace(z_center - h_cyl*2, z_center + h_cyl*2, 6));
            
            rx = Xc; ry = Yc; rz = Zc - z_center; 
            r_mag = sqrt(rx.^2 + ry.^2 + rz.^2) + 1e-5; 
            
            m_vec_cyl = [0, 0, obj.mu_dipole];
            dot_pr_c = m_vec_cyl(3) .* rz; 
            
            Bx_c = (obj.mu_0 / (4*pi)) * (3 * rx .* dot_pr_c ./ r_mag.^5);
            By_c = (obj.mu_0 / (4*pi)) * (3 * ry .* dot_pr_c ./ r_mag.^5);
            Bz_c = (obj.mu_0 / (4*pi)) * (3 * rz .* dot_pr_c ./ r_mag.^5 - m_vec_cyl(3) ./ r_mag.^3);
            
            inside_cyl = (sqrt(rx.^2 + ry.^2) < r_cyl) & (abs(rz) < h_cyl/2);
            Bx_c(inside_cyl) = 0; By_c(inside_cyl) = 0; Bz_c(inside_cyl) = 0;
            B_norm_c = sqrt(Bx_c.^2 + By_c.^2 + Bz_c.^2) + 1e-5;
            
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
            % 2. CAMPO DE LOS ANILLOS (corriente individual por anillo)
            % ==========================================
            ring_h = obj.torus.ring_h;
            R_ring = obj.torus.R;
            N = numel(ring_z);
            
            anyActive = false;
            gridN = 8;
            z_min = min(ring_z) - ring_h/2 - 2;
            z_max = max(ring_z) + ring_h/2 + 2;
            [Xt, Yt, Zt] = meshgrid(linspace(-R_ring-3, R_ring+3, gridN), ...
                                    linspace(-R_ring-3, R_ring+3, gridN), ...
                                    linspace(z_min, z_max, gridN));
            
            Bx_t = zeros(size(Xt));
            By_t = zeros(size(Xt));
            Bz_t = zeros(size(Xt));
            
            I_const = (3 * obj.mu_0 * obj.mu_dipole * R_ring^2 * v) / (2 * obj.R_res);
            for k = 1:N
                dz = z_cyl - ring_z(k);
                I_ind_k = I_const * dz / (dz^2 + R_ring^2)^(5/2) * ring_h;
                
                if abs(I_ind_k) > 1e-6
                    anyActive = true;
                    rt_x = Xt; rt_y = Yt; rt_z = Zt - ring_z(k);
                    rt_mag = sqrt(rt_x.^2 + rt_y.^2 + rt_z.^2) + 1e-5;
                    
                    m_ind_k = pi * R_ring^2 * I_ind_k;
                    dot_pr_t = m_ind_k .* rt_z;
                    
                    Bx_t = Bx_t + (obj.mu_0 / (4*pi)) * (3 * rt_x .* dot_pr_t ./ rt_mag.^5);
                    By_t = By_t + (obj.mu_0 / (4*pi)) * (3 * rt_y .* dot_pr_t ./ rt_mag.^5);
                    Bz_t = Bz_t + (obj.mu_0 / (4*pi)) * (3 * rt_z .* dot_pr_t ./ rt_mag.^5 - m_ind_k ./ rt_mag.^3);
                end
            end
            
            if anyActive
                Bt_norm = sqrt(Bx_t.^2 + By_t.^2 + Bz_t.^2) + 1e-5;
                
                if isempty(obj.hQuiverTor) || ~isgraphics(obj.hQuiverTor)
                    obj.hQuiverTor = quiver3(ax, Xt, Yt, Zt, ...
                        (Bx_t./Bt_norm)*scale, (By_t./Bt_norm)*scale, (Bz_t./Bt_norm)*scale, ...
                        0, 'Color', [0.796, 0.294, 0.086], 'LineWidth', 1.2);
                else
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