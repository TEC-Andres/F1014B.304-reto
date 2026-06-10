%% nodoFEM.m
% Calcula la FEM inducida usando el método de Romberg
classdef nodoFEM < handle
    methods (Access = public)
        function FEM = calculateFEM(~, mu_0, mu_dipole, R, z, v, ring_z, ring_h)
            N = numel(ring_z);
            FEM = 0;
            FEM_const = (3 * mu_0 * mu_dipole * R^2 * v) / 2;
            for k = 1:N
                z_bottom = ring_z(k) - ring_h/2;
                z_top = ring_z(k) + ring_h/2;
                FEM_integrand = @(zp) FEM_const .* (z - zp) ./ ((z - zp).^2 + R^2).^(5/2);
                FEM_k = nodoMagnetoMecanico.metodoDeRomberg(FEM_integrand, z_bottom, z_top, 1e-3);
                FEM = FEM + FEM_k;
            end 
        end
    end
end
