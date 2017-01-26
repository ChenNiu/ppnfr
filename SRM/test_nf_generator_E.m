clc;
clear all;
close all;

%% contents
freq = 10e9;
c = 299792458;
lamda = c/freq;
%%
Jmat = elliptical_apertrue_AUT( 5, 2, 0.5, 20, 45, 20, 45, freq);
% make Jx = 0;
% Jmat(:,3) = zeros(length(Jmat),1); 

z_near = 6*lamda;
x_near = 30*lamda;
y_near = x_near;
step_near = 0.5*lamda;

r_c_near = null(4);
for x = -x_near/2:step_near:x_near/2
    for y = -y_near/2:step_near:y_near/2
        r_c_near = [r_c_near;[x,y,0,pi/2]];
    end
end
[ nf ] = nf_generator_E( Jmat, r_c_near, z_near, freq );
%% 
recon.step = 0.1*lamda;
recon.xSize = 6*lamda;
recon.ySize = 3*lamda;
recon.dist = 0.1*lamda;
[ recon ] = recon_plane_generaor( recon );
[ A_nf ] = nf_operatorMat_generator( recon, nf, freq );
ff.theta = -90:1:90;
ff.phi = 45;
ff.r = 100*lamda;
[ ff ] = ff_generator_E( Jmat, ff, freq );
[ A_FF ] = ff_operatorMat_generator( recon, ff, freq );

%%
maxIter = 100;
[X,rho,eta] = cgls_simple(A_nf,nf.Etheta,maxIter);

M = X(:,end);

E_FF_SRM = A_FF.mat*M;

Ex_FF_SRM = E_FF_SRM(1:size(ff.x,1),1);
Ey_FF_SRM = E_FF_SRM(size(ff.x,1)+1:2*size(ff.x,1),1);
Ez_FF_SRM = E_FF_SRM(2*size(ff.x,1)+1:end,1);
E_mag_FF_SRM = sqrt(abs(Ex_FF_SRM).^2+abs(Ey_FF_SRM).^2+abs(Ez_FF_SRM).^2);
E_mag_FF_SRM_norm_dB = 20*log10(E_mag_FF_SRM/max(E_mag_FF_SRM));

Ex_FF_True = ff.Ex;
Ey_FF_True = ff.Ey;
Ez_FF_True = ff.Ez;
E_mag_FF_True = sqrt(abs(Ex_FF_True).^2+abs(Ey_FF_True).^2+abs(Ez_FF_True).^2);
E_mag_FF_True_norm_dB = 20*log10(E_mag_FF_True/max(E_mag_FF_True));

figure;
plot(ff.theta,E_mag_FF_SRM_norm_dB,ff.theta,E_mag_FF_True_norm_dB);
legend('SRM','True');


%%
numX = length(-x_near/2:step_near:x_near/2);
numY = length(-y_near/2:step_near:y_near/2);
Ex_norm_dB = 20*log10(abs(nf.Ex(1:length(r_c_near)))/max(abs(nf.Ex(1:length(r_c_near)))));
Ey_norm_dB = 20*log10(abs(nf.Ey(1:length(r_c_near)))/max(abs(nf.Ey(1:length(r_c_near)))));
Exang = angle(nf.Ex(1:length(r_c_near))).*180/pi;
Eyang = angle(nf.Ey(1:length(r_c_near))).*180/pi;
crossMeg = reshape(Ex_norm_dB,numY,numX);
crossPha = reshape(Exang,numY,numX);
coMeg = reshape(Ey_norm_dB,numY,numX);
coPha = reshape(Eyang,numY,numX);
figure;
surf(crossMeg,'EdgeColor','none');
figure;
surf(crossPha,'EdgeColor','none');
figure;
surf(coMeg,'EdgeColor','none');
figure;
surf(coPha,'EdgeColor','none');

