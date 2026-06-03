%% superficies.m
classdef superficies < windowHandler
    % superficies Class to hold and plot a cylinder, an elongated ring (tube), and a ground surface.
    % The class stores geometric parameters, current positioning, and color vectors.
    
    properties
        cylinder   = struct('rx',1,'ry',1.5,'height',2,'z0',0,'color',[0.149, 0.545, 0.824]); % azul
        % The torus is now treated as an elongated tube. 'height' defines its length.
        torus      = struct('R',3,'r',0.5,'height',20,'center',[0 0 15],'color',[0.796, 0.294, 0.086]); % naranja
        ground     = struct('radius',5,'z0',0,'color',[0.933, 0.910, 0.835]); % suave crema
        pilar      = struct('rx',0.5,'ry',0.5,'height',30,'z0',0,'color',[0.676,0.676,0.676]); % gris
        resolution = struct('theta',120,'z',50,'u',120,'v',40); 
        camera     = struct('xlim',[-5 5],'ylim',[-5 5],'zlim',[-1 35]); 
    end

    properties (Access = private)
        hCylinderSurface = []
        hCylinderTop = []
        hCylinderBottom = []
        hGroundPatch = []
        hTorusSurface = []
        hPilarSurface = []
    end
    
    methods
        function obj = superficies()
            obj = obj@windowHandler();
            validateattributes(obj.camera.xlim, {'numeric'}, {'size',[1,2]});
            validateattributes(obj.camera.ylim, {'numeric'}, {'size',[1,2]});
            validateattributes(obj.camera.zlim, {'numeric'}, {'size',[1,2]});
        end
        
        function setCylinderPose(obj, z0)
            validateattributes(z0, {'numeric'}, {'scalar'});
            obj.cylinder.z0 = z0;
        end
        
        function setTorusCenter(obj, center)
            validateattributes(center, {'numeric'}, {'vector','numel',3});
            obj.torus.center = center(:).';
        end
        
        function setColors(obj, cylColor, torColor, groundColor)
            if nargin>1 && ~isempty(cylColor), obj.cylinder.color = cylColor; end
            if nargin>2 && ~isempty(torColor), obj.torus.color = torColor; end
            if nargin>3 && ~isempty(groundColor), obj.ground.color = groundColor; end
        end
        
        function plotLoop(obj, fast)
            if nargin < 2
                fast = false;
            end
            
            % Cylinder mesh 
            rx = obj.cylinder.rx;
            ry = obj.cylinder.ry;
            h = obj.cylinder.height;
            z0 = obj.cylinder.z0;
            if fast
                theta = linspace(0, 2*pi, max(20, round(obj.resolution.theta/4)));
                cyl_z = linspace(0, h, max(8, round(obj.resolution.z/4)));
            else
                theta = linspace(0, 2*pi, obj.resolution.theta);
                cyl_z = linspace(0, h, obj.resolution.z);
            end
            [TH, Z] = meshgrid(theta, cyl_z);
            Xc = rx * cos(TH);
            Yc = ry * sin(TH);
            Zc = Z + z0;

            % Pilar mesh
            prx = obj.pilar.rx;
            pry = obj.pilar.ry;
            ph = obj.pilar.height;
            pz0 = obj.pilar.z0;
            if fast
                ptheta = linspace(0, 2*pi, max(20, round(obj.resolution.theta/4)));
                pz = linspace(0, ph, max(8, round(obj.resolution.z/4)));
            else
                ptheta = linspace(0, 2*pi, obj.resolution.theta);
                pz = linspace(0, ph, obj.resolution.z);
            end
            [PTH, PZ] = meshgrid(ptheta, pz);
            Xp = prx * cos(PTH);
            Yp = pry * sin(PTH);
            Zp = PZ + pz0;
            
            % Elongated Ring (Tube) mesh
            R = obj.torus.R;
            tube_h = obj.torus.height;
            if fast
                u = linspace(0, 2*pi, max(40, round(obj.resolution.u/3)));
                v = linspace(0, tube_h, max(12, round(obj.resolution.v/3)));
            else
                u = linspace(0, 2*pi, obj.resolution.u);
                v = linspace(0, tube_h, obj.resolution.v);
            end
            [U, V] = meshgrid(u, v);
            Xr = R * cos(U);
            Yr = R * sin(U);
            % Center the tube vertically around the torus.center(3)
            Zr = (V - tube_h/2); 
            
            Xr = Xr + obj.torus.center(1);
            Yr = Yr + obj.torus.center(2);
            Zr = Zr + obj.torus.center(3);
            
            % Ground disk
            disk_r = obj.ground.radius;
            th_disk = linspace(0,2*pi,200);
            Xd = disk_r * cos(th_disk);
            Yd = disk_r * sin(th_disk);
            Zd = ones(size(th_disk)) * obj.ground.z0;
            
            ax = obj.UIAxes;
            hold(ax, 'on');
            axis(ax, 'equal');

            % Cylinder surface
            if isempty(obj.hCylinderSurface) || ~isgraphics(obj.hCylinderSurface)
                obj.hCylinderSurface = surf(ax, Xc, Yc, Zc, 'FaceColor', obj.cylinder.color, 'EdgeColor', 'none', 'FaceAlpha', 1, 'FaceLighting', 'gouraud');
            else
                set(obj.hCylinderSurface, 'XData', Xc, 'YData', Yc, 'ZData', Zc, 'FaceColor', obj.cylinder.color);
            end

            % Cylinder caps
            th_cap = linspace(0,2*pi, max(60, round(obj.resolution.theta/2)));
            Xt = rx*cos(th_cap);
            Yt = ry*sin(th_cap);
            Zt = ones(size(th_cap)) * (h + z0);
            Zb = ones(size(th_cap)) * z0;
            if isempty(obj.hCylinderTop) || ~isgraphics(obj.hCylinderTop)
                obj.hCylinderTop = fill3(ax, Xt, Yt, Zt, obj.cylinder.color, 'EdgeColor', 'none');
            else
                set(obj.hCylinderTop, 'XData', Xt, 'YData', Yt, 'ZData', Zt, 'FaceColor', obj.cylinder.color);
            end
            if isempty(obj.hCylinderBottom) || ~isgraphics(obj.hCylinderBottom)
                obj.hCylinderBottom = fill3(ax, Xt, Yt, Zb, obj.cylinder.color, 'EdgeColor', 'none');
            else
                set(obj.hCylinderBottom, 'XData', Xt, 'YData', Yt, 'ZData', Zb, 'FaceColor', obj.cylinder.color);
            end

            % Pilar surface
            if isempty(obj.hPilarSurface) || ~isgraphics(obj.hPilarSurface)
                obj.hPilarSurface = surf(ax, Xp, Yp, Zp, 'FaceColor', obj.pilar.color, 'EdgeColor', 'none', 'FaceAlpha', 1, 'FaceLighting', 'gouraud');
            else
                set(obj.hPilarSurface, 'XData', Xp, 'YData', Yp, 'ZData', Zp, 'FaceColor', obj.pilar.color);
            end

            % Ground
            if isempty(obj.hGroundPatch) || ~isgraphics(obj.hGroundPatch)
                obj.hGroundPatch = fill3(ax, Xd, Yd, Zd, obj.ground.color, 'EdgeColor', 'none', 'FaceAlpha', 1);
            else
                set(obj.hGroundPatch, 'XData', Xd, 'YData', Yd, 'ZData', Zd, 'FaceColor', obj.ground.color);
            end

            % Tube (previously Torus)
            if isempty(obj.hTorusSurface) || ~isgraphics(obj.hTorusSurface)
                % FaceAlpha made slightly transparent to see the magnet inside
                obj.hTorusSurface = surf(ax, Xr, Yr, Zr, 'FaceColor', obj.torus.color, 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'FaceLighting', 'gouraud');
            else
                set(obj.hTorusSurface, 'XData', Xr, 'YData', Yr, 'ZData', Zr, 'FaceColor', obj.torus.color);
            end

            try
                if isempty(obj.hTorusSurface) || ~isgraphics(obj.hTorusSurface)
                    camlight(ax, 'headlight');
                    lighting(ax, 'gouraud');
                    material(ax, 'dull');
                end
            catch
            end
            view(ax, 35, 20);
            xlabel(ax, 'X'); ylabel(ax, 'Y'); zlabel(ax, 'Z');

            % Limits updated for tube geometry
            maxDim = max([R, rx, ry, disk_r]) + 5;
            cx = obj.torus.center(1);
            cy = obj.torus.center(2);
            cz = obj.torus.center(3);
            xlim(ax, [min([ -maxDim, cx - R - 1 ]), max([ maxDim, cx + R + 1 ])]);
            ylim(ax, [min([ -maxDim, cy - R - 1 ]), max([ maxDim, cy + R + 1 ])]);
            zmin = min([z0, cz - (tube_h/2+1)]) - 5;
            zmax = max([h+z0, cz + (tube_h/2+1)]) + 5;
            zlim(ax, [zmin, zmax]);

            try
                xlim(ax, obj.camera.xlim);
                ylim(ax, obj.camera.ylim);
                zlim(ax, obj.camera.zlim);
            catch
            end

            grid(ax, 'on');
            drawnow limitrate;
            hold(ax, 'off');
        end
    end
end