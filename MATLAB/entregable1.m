% HijosDeGauss.m
% Modelo 3D con curva de nivel de como luce un campo electromagnético en 
% 
% Integrantes: Daniel Eduardo Santiago Gutiérrez - A00844476
% David Eduardo Santiago Gutiérrez - A00844480
% Andres Rodríguez Cantú - A01287002



%% Biot Savart
COLOR_BG = [1 1 1];           % fondo blanco
COLOR_AXES = [0 0 0];         % ejes negra
COLOR_ESPIRA = [0 0 0];       % espira negra
COLOR_LINEA = [0 0 0];        % línea central negra
COLOR_ORIGEN = [1 1 1];       % origen blanco
COLOR_FLECHAS = [0 0 1];      % color de flechas

% Constantes
mu_cero = 4*pi*1e-7;  % Permeatividad del vacio
I_linea = 1;          % corriente en la línea (A)
I_ciclo = 1;          % corriente en la espira (A)
R = 0.5;              % radio de la espira (m)
zmin = -1; zmax = 1;  % rango en z para la línea y la gráfica
limites_xy = 1;       % extensión en x,y para la cuadrícula (m)

% Definición del espacio en el cuál calcularemos el campo
nx = 75; ny = 75; nz = 20;
[x, y, z] = meshgrid(linspace(-limites_xy,limites_xy,nx), ...
                     linspace(-limites_xy,limites_xy,ny), ...
                     linspace(-limites_xy,limites_xy,nz));
points = [x(:), y(:), z(:)];

% Cálculos del campo B multiplicado por su respectiva magnitud
r_xy = sqrt(points(:,1).^2 + points(:,2).^2); % magnitud
B_linea_x = -mu_cero*I_linea./(2*pi*r_xy) .* (points(:,2)./r_xy);
B_linea_y =  mu_cero*I_linea./(2*pi*r_xy) .* (points(:,1)./r_xy);
B_linea_z = zeros(size(B_linea_x));
B_linea = [B_linea_x, B_linea_y, B_linea_z]; % Vector de campo generado por la linea de corriente

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
nseg = 200;
theta = linspace(0, 2*pi, nseg+1)'; % Creación de espacio para un circulo 
theta(end) = [];
r_seg = R * [cos(theta), sin(theta), zeros(size(theta))];

% dl vectores (tangentes)
dtheta = 2*pi/nseg;
dl = R * [-sin(theta), cos(theta), zeros(size(theta))] * dtheta;

% Ley de Biot-Savart en R^3:
% \vec{B} = \frac{\mu_0 I}{4\pi}\int \frac{d\vec{s}\times \hat{r}}{r^3}
% B = \frac{\mu_0 I}{4\pi}\sum_{k=1}^n \frac{\Delta l_k\times r_k}{r^3_k} | as n\to \infty

B_ciclo = zeros(size(points));
for k = 1:nseg
    rprime = r_seg(k,:);
    dlk = dl(k,:);
    Rvec = points - rprime;
    dist3 = sqrt(sum(Rvec.^2,2)).^3;
    crossprod = cross(repmat(dlk,size(Rvec,1),1), Rvec, 2);
    dB = (mu_cero/(4*pi)) * I_ciclo * crossprod ./ dist3;
    B_ciclo = B_ciclo + dB;
end

% Suma total de los campos
B_total = B_linea + B_ciclo;

%% Plot 3D
figure('Color',COLOR_BG);

% Remoldeo de componentes (por si size(Bx) \neq size(By) \neq size(Bz)
Bx_3D = reshape(B_total(:,1), ny, nx, nz);
By_3D = reshape(B_total(:,2), ny, nx, nz);
Bz_3D = reshape(B_total(:,3), ny, nx, nz);

% Definir el plano z a graficar (el plano central) y el factor de submuestreo
z_medio = round(nz/2);
sub = 2; % Densidad de flechas

% Display de los puntos
X_sub = x(1:sub:end, 1:sub:end, z_medio);
Y_sub = y(1:sub:end, 1:sub:end, z_medio);
Z_sub = z(1:sub:end, 1:sub:end, z_medio);

% Evaluación del campo
U_sub = Bx_3D(1:sub:end, 1:sub:end, z_medio);
V_sub = By_3D(1:sub:end, 1:sub:end, z_medio);
W_sub = Bz_3D(1:sub:end, 1:sub:end, z_medio);

% Graficar
hq = quiver3(X_sub, Y_sub, Z_sub, U_sub, V_sub, W_sub, 1.5, 'Color', COLOR_FLECHAS);
hold on;

% Dibujar espira y la línea central
ang = linspace(0,2*pi,200);

plot3(R*cos(ang), R*sin(ang), zeros(size(ang)), 'Color', COLOR_ESPIRA, 'LineWidth', 1.5); % Espira
plot3([0 0], [0 0], [-0.3 0.3], 'Color', COLOR_LINEA, 'LineWidth', 2);                  % Linea vertical
plot3(0, 0, 0, 'o', 'MarkerEdgeColor', COLOR_ORIGEN, 'MarkerFaceColor', COLOR_ORIGEN);    % Punto marcando el origen

hold off;
axis equal;
xlabel('x (m)', 'Color', COLOR_AXES); ylabel('y (m)', 'Color', COLOR_AXES); zlabel('z (m)', 'Color', COLOR_AXES);
title('Campo magnético (vista 3D, plano central)', 'Color', COLOR_AXES);
view(3);
grid on;
set(gca, 'XColor', COLOR_AXES, 'YColor', COLOR_AXES, 'ZColor', COLOR_AXES, 'Color', COLOR_BG);

%% Curva de nivel en el eje Z
% Seleccionar plano z central ya usado en la gráfica 3D
Zplano= squeeze(z(:,:,z_medio));
% Campo magnitud en el plano (usar componentes reestructuradas)
magnitudDeBEnElPlanoZ = sqrt(Bx_3D(:,:,z_medio).^2 + By_3D(:,:,z_medio).^2 + Bz_3D(:,:,z_medio).^2);

% Plot
figure('Color',COLOR_BG);
hold on;
niveles = linspace(min(magnitudDeBEnElPlanoZ(:)), max(magnitudDeBEnElPlanoZ(:)), 15);
contourf(X_sub, Y_sub, magnitudDeBEnElPlanoZ(1:sub:end,1:sub:end), niveles, 'LineColor','none');
colormap(parula);
colorbar('Color', COLOR_AXES);

% Superponer líneas de contorno.
contour(X_sub, Y_sub, magnitudDeBEnElPlanoZ(1:sub:end,1:sub:end), 8, 'LineColor', COLOR_AXES);

% Dibujar la espira y la línea central proyectadas en el plano
ang = linspace(0,2*pi,200);
plot(R*cos(ang), R*sin(ang), 'Color', COLOR_ESPIRA, 'LineWidth', 1.5);
plot(0,0,'o','MarkerEdgeColor', COLOR_ORIGEN, 'MarkerFaceColor', COLOR_ORIGEN);

axis equal;
xlim([-limites_xy limites_xy]);
ylim([-limites_xy limites_xy]);
xlabel('x (m)', 'Color', COLOR_AXES); ylabel('y (m)', 'Color', COLOR_AXES);
title('Curvas de nivel de |B| en el plano z = 0', 'Color', COLOR_AXES);
set(gca,'Color',COLOR_BG,'XColor',COLOR_AXES,'YColor',COLOR_AXES);

hold off;
