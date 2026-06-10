%% entregable3.m
clear; clc;
addpath("lib3")

sup = nodoMagnetoMecanico();
sup.cylinder.rx = 1;
sup.cylinder.ry = 1;
sup.cylinder.height = 3;
sup.cylinder.z0 = 30;
sup.cylinder.color = [0.2 0.6 0.8];

% Anillos (10 anillos desde z=2 con separación Δz=0.25)
sup.torus.R = 4.6;
sup.torus.r = 0.5;
sup.torus.ring_h = 0.25;
sup.torus.ring_z = 2:0.25:4.25;
sup.torus.color = [0.9 0.6 0.2];

% Piso
sup.ground.isSquare = true;
sup.ground.size = max(sup.cylinder.rx, sup.cylinder.ry)*2.5; % half-side length
sup.ground.z0 = 0;
sup.ground.color = [0.8 0.8 0.8];

% Tamaño de paso por segundo
stepDt = 0.01;
startZ = sup.cylinder.z0;

% Ejecución
graficas = nodoGraficas(sup);
sup.bindRunButton(@() graficas.run(stepDt));

% Plot loop
sup.plotLoop();