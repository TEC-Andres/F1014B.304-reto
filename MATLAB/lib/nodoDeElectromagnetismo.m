classdef nodoDeElectromagnetismo < superficies
	properties (Access = public)
        Bx
        By
        Bz
        points
    end

	methods (Access = private)
			% Parametrización del vector r:
			% R(\theta) = R_{dentro} +\frac{\Delta R}{2\pi N}\theta
			% R(\theta) = R_{dentro} +k\theta
			% r_seg     = [ R(\theta)\cos(\theta) ]
			%             [ R(\theta)\sin(\theta) ]
			%             [           0           ]
			%
			% dl = \frac{dr'}{d\theta} d\theta
			%
			% \frac{d}{d\theta}(r_seg[ELEMENTO_X]) = k\cos(\theta)-R(\theta)\sin(\theta) 
			% \frac{d}{d\theta}(r_seg[ELEMENTO_Y]) = k\sin(\theta)+R(\theta)\cos(\theta) 
			% \frac{d}{d\theta}(r_seg[ELEMENTO_Z]) = 0
			%
			% dl = [ k\cos(\theta)-R(\theta)\sin(\theta) ] d\theta
			%      [ k\sin(\theta)+R(\theta)\cos(\theta) ]
			%      [                   0                 ]
			%
			% Nota: para una espira circular R es constante y usamos la forma analítica
			% r'(theta) = R*[cos(theta), sin(theta), 0], dr'/dtheta = R*[-sin(theta), cos(theta), 0]
			function out = integrandAtTheta(obj, theta, R, mu_cero, I_ciclo)
				% devuelve (Npoints x 3) el valor del integrando en el ángulo theta
			rprime = R * [cos(theta), sin(theta), 0];
			drdtheta = R * [-sin(theta), cos(theta), 0];
			Rvec = obj.points - rprime; % Npoints x 3
			dist3 = sqrt(sum(Rvec.^2,2)).^3; % Npoints x 1
			crossprod = cross(repmat(drdtheta, size(Rvec,1),1), Rvec, 2);
			out = (mu_cero/(4*pi)) * I_ciclo * crossprod ./ dist3;
		end
	end

    properties (Access = private)
        COLOR_BG      = [1 1 1]; % fondo blanco
        COLOR_AXES    = [0 0 0]; % ejes negra
        COLOR_ESPIRA  = [0 0 0]; % espira negra
        COLOR_LINEA   = [0 0 0]; % línea central negra
        COLOR_ORIGEN  = [1 1 1]; % origen blanco
        COLOR_FLECHAS = [0 0 1]; % color de flechas
    end
    
    methods
		function obj = nodoDeElectromagnetismo()
			obj = obj@superficies();
		end

		% Romberg integration for vector-valued integrands.
		% Usage: I = obj.metodoDeRomberg(fh, a, b, tol, maxLevel)
		% - fh: function handle that accepts scalar theta and returns an (Npoints x 3) array
		% - a,b: integration limits (scalars)
		% - tol: optional tolerance (default 1e-6)
		% - maxLevel: optional maximum Romberg level (default 6)
		function I = metodoDeRomberg(obj, fh, a, b, tol, maxLevel)
			if nargin < 4 || isempty(tol)
				tol = 1e-6;
			end
			if nargin < 5 || isempty(maxLevel)
				maxLevel = 6; % up to 2^(maxLevel-1) intervals
			end

			% Pre-allocate cell to hold Romberg table entries (each entry is Npoints x 3)
			R = cell(maxLevel, maxLevel);

			for k = 1:maxLevel
				n = 2^(k-1);
				h = (b - a) / n;
				x = a:h:b; % sample points for trapezoid

				% Accumulate trapezoid sum over vector-valued fh evaluations
				S = zeros(size(obj.points,1), 3);
				for xi = 1:numel(x)
					fx = fh(x(xi)); % returns Npoints x 3
					if xi == 1 || xi == numel(x)
						S = S + 0.5 * fx;
					else
						S = S + fx;
					end
				end

				T = h * S; % trapezoidal approximation (Npoints x 3)
				R{1, k} = T;

				% Richardson extrapolation
				for j = 2:k
					% R{j,k} computed from R{j-1,k} and R{j-1,k-1}
					R{j, k} = R{j-1, k} + (R{j-1, k} - R{j-1, k-1}) / (4^(j-1) - 1);
				end

				% Convergence check comparing diagonal entries
				if k > 1
					err = max(abs(R{k,k} - R{k-1,k-1}), [], 'all');
					if err < tol
						I = R{k,k};
						return
					end
				end
			end

			% if not converged, return highest-level approximation
			I = R{maxLevel, maxLevel};
		end

		function biotSavart(obj)
			%% Biot Savart
			% Constantes
			mu_cero = 4*pi*1e-7;  % Permeatividad del vacio
			I_linea = 1;          % corriente en la línea (A)
			I_ciclo = 1;          % corriente en la espira (A)
			R = 0.5;              % radio de la espira (m)
			obj.zmin = -1; obj.zmax = 1;  % rango en z para la línea y la gráfica
			obj.limites_xy = 1;       % extensión en x,y para la cuadrícula (m)

			% Definición del espacio en el cuál calcularemos el campo
			nx = 75; ny = 75; nz = 20;
			[x, y, z] = meshgrid(linspace(-obj.limites_xy,obj.limites_xy,nx), ...
			                     linspace(-obj.limites_xy,obj.limites_xy,ny), ...
			                     linspace(-obj.limites_xy,obj.limites_xy,nz));
			obj.points = [x(:), y(:), z(:)];

			% Cálculos del campo B multiplicado por su respectiva magnitud
			r_xy = sqrt(obj.points(:,1).^2 + obj.points(:,2).^2); % magnitud
			B_linea_x = -mu_cero*I_linea./(2*pi*r_xy) .* (obj.points(:,2)./r_xy);
			B_linea_y =  mu_cero*I_linea./(2*pi*r_xy) .* (obj.points(:,1)./r_xy);
			B_linea_z = zeros(size(B_linea_x));
			B_linea = [B_linea_x, B_linea_y, B_linea_z]; % Vector de campo generado por la linea de corriente

			% Ley de Biot-Savart en R^3:
			% \vec{B} = \frac{\mu_0 I}{4\pi}\int \frac{d\vec{s}\times \hat{r}}{r^3}
			% B = \frac{\mu_0 I}{4\pi}\sum_{k=1}^n \frac{\Delta l_k\times r_k}{r^3_k} | as n\to \infty

			% Integración usando Romberg: definimos el integrando como función
			% que para un escalar theta devuelve un array (Npoints x 3)
			% fh = @(th) arrayfun(@(t) integrandAtTheta(obj, t, R, mu_cero, I_ciclo), th, 'UniformOutput', false);
			% % arrayfun above returns a cell array of (Npoints x 3) arrays; convert to combined function
			% fh_vec = @(th) vertcat(fh(th){:});

			% Alternatively use a scalar-evaluating wrapper (metodoDeRomberg expects fh(theta) -> Npoints x 3)
			fh_scalar = @(theta_scalar) integrandAtTheta(obj, theta_scalar, R, mu_cero, I_ciclo);

			tol = 1e-4; % Tolerancia para la integración numérica
			B_ciclo = obj.metodoDeRomberg(fh_scalar, 0, 2*pi, tol);

			% Suma total de los campos
			B_total = B_linea + B_ciclo;

			% Reshape para volver a la malla 3D y guardado en objeto para uso posterior
			obj.Bx = reshape(B_total(:,1), size(x));
			obj.By = reshape(B_total(:,2), size(y));
			obj.Bz = reshape(B_total(:,3), size(z));
			obj.points = obj.points; % opcional: conservar puntos cartesianos

			% No devolver desde método (mantener estilo orientado a objetos)
			% Si se desea el vector plano como salida, descomente la línea siguiente:
			% varargout{1} = B_total;
			return
	    end
    end
end