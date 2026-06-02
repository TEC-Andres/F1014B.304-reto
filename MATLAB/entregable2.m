clear; clc;
% entregable2.m
addpath("lib")

sup = nodoDeFuerza();
sup.cylinder.rx = 1;
sup.cylinder.ry = 1;
sup.cylinder.height = 3;
sup.cylinder.z0 = 30;
sup.cylinder.color = [0.2 0.6 0.8];

% Torus: outer ring center moved to [0,0,10]
sup.torus.R = 3;
sup.torus.r = 0.5;
sup.torus.center = [0 0 10];
sup.torus.color = [0.9 0.6 0.2];

% Piso (cuadrado)
sup.ground.isSquare = true;
sup.ground.size = max(sup.cylinder.rx, sup.cylinder.ry)*2.5; % half-side length
sup.ground.z0 = 0;
sup.ground.color = [0.8 0.8 0.8];
% Tamaño de paso por segundo
stepDt = 0.05;
startZ = sup.cylinder.z0;

sup.bindRunButton(@() sup.runFallEngine(startZ, stepDt));

% Plot loop
sup.plotLoop();

