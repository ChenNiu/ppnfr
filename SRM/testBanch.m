clc;
clear all;
close all;

addpath('input','output');

%% read input
filename = 'testing.txt';
nfMeas = PPNFR_NF_Measurement(filename);
freq = nfMeas.freq;

%% Reconstruction Surface
fprintf('Building Reconstruction Plane...');
reconSurf = Recon_Surface(nfMeas.aut_dim_x, nfMeas.aut_dim_y, freq);
fprintf('done.\n');


%% Build the near-field operator matrix
tic;
fprintf('Building the near-field operator matrices...');
nf_op = NearField_Operator(reconSurf,nfMeas,freq);
fprintf('done.\n');
toc;
%% Build the far-field operator matrix
fprintf('Building the far-field operator matrices...');
phi = 0;
dtheta = 1;
ff_op = FarField_Operator(reconSurf, phi, dtheta, freq);
fprintf('done.\n');

%% CG
fprintf('Solving using CG...\n');
maxIter = 100;
[X,rho,eta] = cgls_simple(nf_op.A,nfMeas.S21,maxIter);
M = X(:,end);
E_FF_SRM = ff_op.A.mat*M;
fprintf('done.\n');


%% plots
% meas.plot_xy_S21_dB_Enor;
% meas.plot_xyS21_dB_Etan;
% meas.plot_autAng_penAng_S21_dB_Enor;
% meas.plot_autAng_penAng_S21_dB_Etan;
% meas.plot_phaseAng;

% figure;
% scatter(test.x,test.y,10,S21_dB,'filled');
% axis('equal');
% 
% figure;
% scatter(test.time,test.penAng,20,S21_dB,'filled');