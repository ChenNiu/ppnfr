clc;
clear all;
close all;
%% contents
freq = 10e9;
c = 299792458;
lamda = c/freq;
now = datestr(datetime('now'),'mm_dd_HHMM');

%% paramters
% AUT ---------------------------------------------------------------------
major = 5;
minor = 2;
J_step = 0.25;
Jx_theta = 10;
Jx_phi = 30;
Jy_theta = 10;
Jy_phi = 30;
%--------------------------------------------------------------------------

% pendulum grid -----------------------------------------------------------
% length of the pendulum arm
% l = 30*lamda;
l = 0.924;
% dt is measurement time interval [sec]
dt = 0.005;
omegaAUT = 1; %x deg per sec
theta0 = 20;
%--------------------------------------------------------------------------

%synesthetic NF------------------------------------------------------------
z_near = 3*lamda;

% option = 1 colocated
% option = 2 not colocated but two polar measurement
% option = 3 one polar measurement
option = 2;
if option>1
    dt = dt/2;
end
%--------------------------------------------------------------------------

% Add Near-Field Noise ----------------------------------------------------
addNoise = false;
noiseLevel = 0.10;
%--------------------------------------------------------------------------

% synesthetic far-field----------------------------------------------------
ff.phi = 30;
%--------------------------------------------------------------------------

% reconstruction surface---------------------------------------------------
recon.step = 0.1*lamda;
recon.xSize = 6*lamda;
recon.ySize = 3*lamda;
recon.dist = 0.1*lamda;
%--------------------------------------------------------------------------




%% AUT

Jmat = elliptical_apertrue_AUT( major, minor, J_step, Jx_theta, Jx_phi, Jy_theta, Jy_phi, freq);
% make Jx = 0;
% Jmat(:,3) = zeros(length(Jmat),1); 

%% Near-field Measurement Plane

[ penGrid,Tpendulum, maxDis ] = pendulum_nf_dataGrid_generator( l,dt,theta0,omegaAUT,freq);
if option>1
    [ dummy1,dummy2, maxDis ] = pendulum_nf_dataGrid_generator( l,dt*2,theta0,omegaAUT,freq);
end

%% Generate Sny Near-Field
fprintf('Generating synesthetic NF...');

[ nf ] = nf_generator_E( Jmat, penGrid, z_near, freq, option );
nf.size = length(nf.x);

fprintf('done.\n');
%% Add Near-Field Noise
if addNoise
    fprintf('Adding %2.2f%% random noise to the sny near-field Etheta...', noiseLevel*100);
    Emax = max(nf.Etheta);
    randEtheta = complex(-1+2.*rand(length(nf.Etheta),1),-1+2.*rand(length(nf.Etheta),1));
    nf.Etheta = nf.Etheta + abs(Emax)*noiseLevel*(1/sqrt(2)).*randEtheta;
    fprintf('done.\n');
end
%% Generate Sny Far_Field
fprintf('Generating synesthetic FF...');
ff.theta = -90:1:90;
ff.r = 100*lamda;
[ ff ] = ff_generator_E( Jmat, ff, freq );
fprintf('done.\n');
nf.r = 2*l*sind(theta0);
critical_angle = atan2(nf.r-major*lamda/2,z_near)*180/pi;

%% Reconstruction Surface
fprintf('Building Reconstruction Plane...');
[ recon ] = recon_plane_generaor( recon );
recon.size = length(recon.x);
fprintf('done.\n');
%% Build the near-field operator matrix
tic;
fprintf('Building the near-field operator matrices...');
[ A_nf ] = nf_operatorMat_generator( recon, nf, freq );
fprintf('done.\n');
toc;
%% Build the far-field operator matrix
fprintf('Building the far-field operator matrices...');
[ A_FF ] = ff_operatorMat_generator( recon, ff, freq );
fprintf('done.\n');
%% CG
fprintf('Solving using CG...\n');
maxIter = 100;
[X,rho,eta] = cgls_simple(A_nf,nf.Etheta,maxIter);
M = X(:,end);
E_FF_SRM = A_FF.mat*M;
fprintf('done.\n');

%% error

Ex_FF_SRM = E_FF_SRM(1:size(ff.x,1),1);
Ey_FF_SRM = E_FF_SRM(size(ff.x,1)+1:2*size(ff.x,1),1);
Ez_FF_SRM = E_FF_SRM(2*size(ff.x,1)+1:end,1);
E_mag_FF_SRM = sqrt(abs(Ex_FF_SRM).^2+abs(Ey_FF_SRM).^2+abs(Ez_FF_SRM).^2);
E_mag_FF_SRM_norm_lin = E_mag_FF_SRM/max(E_mag_FF_SRM);
E_mag_FF_SRM_norm_dB = 20*log10(E_mag_FF_SRM/max(E_mag_FF_SRM));

Ex_FF_True = ff.Ex;
Ey_FF_True = ff.Ey;
Ez_FF_True = ff.Ez;
E_mag_FF_True = sqrt(abs(Ex_FF_True).^2+abs(Ey_FF_True).^2+abs(Ez_FF_True).^2);
E_mag_FF_True_norm_lin = E_mag_FF_True/max(E_mag_FF_True);
E_mag_FF_True_norm_dB = 20*log10(E_mag_FF_True/max(E_mag_FF_True));

E_mag_FF_SRM_norm_lin_valid = zeros(length(ff.theta),1);
E_mag_FF_True_norm_lin_valid = zeros(length(ff.theta),1);
for i = 1:length(ff.theta)
    if ff.theta(i)>-critical_angle && ff.theta(i)<critical_angle
        E_mag_FF_SRM_norm_lin_valid(i) = E_mag_FF_SRM_norm_lin(i);
        E_mag_FF_True_norm_lin_valid(i) = E_mag_FF_True_norm_lin(i);
    end
end
error = norm(E_mag_FF_SRM_norm_lin_valid-E_mag_FF_True_norm_lin_valid)/norm(E_mag_FF_True_norm_lin_valid);

%% plots 
figure;
quiver(nf.x/lamda,nf.y/lamda,cos(nf.theta),sin(nf.theta));
axis('equal');
xlabel('X [\lambda]');
ylabel('Y [\lambda]');
figName = [now,'_measGrid.fig'];
savefig(fullfile('output',figName));

figure;
quiver(recon.x/lamda,recon.y/lamda,abs(M(1:length(recon.x))),abs(M(length(recon.x)+1:end)));
axis([min(recon.x/lamda)-0.25,max(recon.x/lamda)+0.25,min(recon.y/lamda)-0.25,max(recon.y/lamda)+0.25]);
xlabel('X [\lambda]');
ylabel('Y [\lambda]');
figName = [now,'_mCurrent.fig'];
savefig(fullfile('output',figName));

figure;
plot(ff.theta,E_mag_FF_SRM_norm_dB,ff.theta,E_mag_FF_True_norm_dB);
ymin = min(min(E_mag_FF_SRM_norm_dB),min(E_mag_FF_True_norm_dB));
ymax = max(max(E_mag_FF_SRM_norm_dB),max(E_mag_FF_True_norm_dB));
axis([-90,90,ymin,ymax]);
legend('FF using SRM','FF true');
hold on;
plot([-critical_angle,-critical_angle],[ymin,ymax],'k',[critical_angle,critical_angle],[ymin,ymax],'k');
xlabel(['\theta [deg] @ \phi = ',sprintf('%.1f deg',ff.phi)]);
ylabel('Normalized far-field pattern [dB]');

figName = [now,'_ff.fig'];
savefig(fullfile('output',figName));

%% output file
fileName = [now,'_result.txt'];
fid = fopen(fullfile('output',fileName),'w');

fprintf(fid,'SRM pendulum synesthetic test\n');
fprintf(fid,'Frequency:\t\t\t\t%.2fGHz\n',freq/1e9);
fprintf(fid,'Num of meas points:\t\t%d\n',nf.size);
fprintf(fid,'Num of recon points:\t%d\n',recon.size);
fprintf(fid,'Sample frequency:\t\t%f lamda\n',maxDis);
fprintf(fid,'Critical angle:\t\t\t%.4f deg\n',critical_angle);
if option>1
    fprintf(fid,'Un co-located measurement.\n');
else
    fprintf(fid,'Co-located measurement.\n');
end
if addNoise
    fprintf(fid,'%2.2f%% random noise to the synesthetic near-field Etheta added.\n', noiseLevel*100);
else
    fprintf(fid,'No noise added.\n');
end


fprintf(fid,'\nError:\t\t\t\t\t%f\n',error);

fprintf(fid,'\nUsing ecliptical AUT\n');
fprintf(fid,'Major Axis:\t\t\t\t%.2f\n',major);
fprintf(fid,'Minor Axis:\t\t\t\t%.2f\n',minor);
fprintf(fid,'Current Step size:\t\t%.2f\n',J_step);
fprintf(fid,'x pahse taper:\t\t\ttheta:%.1f\tphi:%.1f\n',Jx_theta,Jx_phi);
fprintf(fid,'y pahse taper:\t\t\ttheta:%.1f\tphi:%.1f\n',Jy_theta,Jy_phi);


fprintf(fid,'\nPendulum Near-field grid\n');
fprintf(fid,'Arm length:\t\t\t\t%.1f lamda\n',l/lamda);
fprintf(fid,'Meas time interval:\t\t%.3f sec\n',dt);
fprintf(fid,'Omega AUT:\t\t\t\t%.1f deg/sec\n',omegaAUT);
fprintf(fid,'Initial angle:\t\t\t%.1f deg\n',theta0);
fprintf(fid,'Z distance:\t\t\t\t%.1f lamda\n',z_near/lamda);
fprintf(fid,'Radius:\t\t\t\t\t%.4f m\n',nf.r);



fprintf(fid,'\nReconstruction Surface\n');
fprintf(fid,'Step size:\t\t\t\t%.1f lamda\n',recon.step/lamda);
fprintf(fid,'X size:\t\t\t\t\t%.1f lamda\n',recon.xSize/lamda);
fprintf(fid,'Y size:\t\t\t\t\t%.1f lamda\n',recon.ySize/lamda);
fprintf(fid,'Z distance:\t\t\t\t%.1f lamda\n',recon.dist/lamda);


fprintf(fid,'\nSynesthetic Far-field\n');
fprintf(fid,'FF phi:\t\t\t\t\t%.1f deg\n',ff.phi);
fprintf(fid,'\n');
fprintf(fid,'\n');

fprintf(fid,'E_mag_FF_True_norm_dB,\tE_mag_FF_SRM_norm_dB\n');
for i=1:length(E_mag_FF_True_norm_dB)
    fprintf(fid,'%f,\t\t\t\t%f\n',E_mag_FF_True_norm_dB(i),E_mag_FF_SRM_norm_dB(i));
end
fprintf(fid,'\n');
fprintf(fid,'\n');


fclose(fid);




