function [ nf ] = nf_generator_E( Jmat, nfGrid, z, freq, option )
% Jmat is [x,y,Jx,Jy], each var is a vector
% nfGrid mat [x, y, tan, nor]
% z distance of nf plane
% output:
% nf.x
% nf.y
% nf.z
% nf.theta
% nf.Ex
% nf.Ey
% nf.Ez
% nf.Etheta
%% Constants
c = 299792458;
eta = 120*pi;
lambda = c/freq;
k = 2*pi/lambda;
%%
if option == 1
    nf.x = [nfGrid(:,1);nfGrid(:,1)];
    nf.y = [nfGrid(:,2);nfGrid(:,2)];
    nf.z = [ones(length(nfGrid),1)*z;ones(length(nfGrid),1)*z];
    nf.theta = [nfGrid(:,3);nfGrid(:,4)];
    
elseif option == 2
    nf.x = nfGrid(:,1);
    nf.y = nfGrid(:,2);
    nf.z = ones(length(nf.x),1)*z;
    nf.theta = zeros(length(nf.x),1);
    for t = 1:length(nf.x)
        if mod(t,2) == 1
            nf.theta(t) = nfGrid(t,3);
        else
            nf.theta(t) = nfGrid(t,4);
        end
    end
else
    nf.x = nfGrid(:,1);
    nf.y = nfGrid(:,2);
    nf.z = ones(length(nf.x),1)*z;
    nf.theta = nfGrid(:,3);
end

nf.Ex = zeros(length(nf.x),1);
nf.Ey = zeros(length(nf.x),1);
nf.Ez = zeros(length(nf.x),1);
nf.Etheta = zeros(length(nf.x),1);



%%
% rotation matrix 
Ay = [1,0,0;0,cosd(90),-sind(90);0,sind(90),cosd(90)]; % rotate around x -90deg
Ax = [cosd(-90),0,sind(-90);0,1,0;-sind(-90),0,cosd(-90)]; % rotate around y 90deg
% iterative of nf points
for n=1:length(nf.x)
    % before rotation 
    rp_c = [(nf.x(n)-Jmat(:,1))';(nf.y(n)-Jmat(:,2))';nf.z(n)*ones(1,size(Jmat,1))];
    % rotation for x directed current
    rp_cp_Jx = Ax*rp_c;
    % car to sph coordinate
    rp_Jx = sqrt(rp_cp_Jx(1,:).^2+rp_cp_Jx(2,:).^2+rp_cp_Jx(3,:).^2);
    thetap_Jx = acos(rp_cp_Jx(3,:)./rp_Jx);
    phip_Jx = atan2(rp_cp_Jx(2,:),rp_cp_Jx(1,:));
    % Compute E_prime at the near-field locations due to all x directed current
    % dipoles
    Ep_rp_Jx = ((eta*Jmat(:,3).'.*cos(thetap_Jx))./(2*pi.*rp_Jx.^2)).*(1+1./(1i*k.*rp_Jx)).*exp(-1i*k.*rp_Jx);
    Ep_thetap_Jx = (1i*eta*k*Jmat(:,3).'.*sin(thetap_Jx)./(4*pi*rp_Jx)).*(1+1./(1i*k*rp_Jx)-1./(k^2*rp_Jx.^2)).*exp(-1i*k.*rp_Jx);
    Ep_phip_Jx = zeros(1,length(Ep_rp_Jx));
    % spi to car mat
    %Build the spherical to cartesian "matrix" (Each element is
    %actually a vector)
    sph2cart11 = sin(thetap_Jx).*cos(phip_Jx);
    sph2cart12 = cos(thetap_Jx).*cos(phip_Jx);
    sph2cart13 = -sin(phip_Jx);
    sph2cart21 = sin(thetap_Jx).*sin(phip_Jx);
    sph2cart22 = cos(thetap_Jx).*sin(phip_Jx);
    sph2cart23 = cos(phip_Jx);
    sph2cart31 = cos(thetap_Jx);
    sph2cart32 = -sin(thetap_Jx);
    sph2cart33 = 0*thetap_Jx;
    Ex_p_Jx = sph2cart11.*Ep_rp_Jx + sph2cart12.*Ep_thetap_Jx + sph2cart13.*Ep_phip_Jx;
    Ey_p_Jx = sph2cart21.*Ep_rp_Jx + sph2cart22.*Ep_thetap_Jx + sph2cart23.*Ep_phip_Jx;
    Ez_p_Jx = sph2cart31.*Ep_rp_Jx + sph2cart32.*Ep_thetap_Jx + sph2cart33.*Ep_phip_Jx;
    %Convert E_prime to E (the global coordinate system)
    E_Jx = sum(Ax'*[Ex_p_Jx;Ey_p_Jx;Ez_p_Jx],2);
    
    % for y directed diople
    % rotation for x directed current
    rp_cp_Jy = Ay*rp_c;
    % car to sph coordinate
    rp_Jy = sqrt(rp_cp_Jy(1,:).^2+rp_cp_Jy(2,:).^2+rp_cp_Jy(3,:).^2);
    thetap_Jy = acos(rp_cp_Jy(3,:)./rp_Jy);
    phip_Jy = atan2(rp_cp_Jy(2,:),rp_cp_Jy(1,:));
    % Compute E_prime at the near-field locations due to all y directed current
    % dipoles
    Ep_rp_Jy = ((eta*Jmat(:,4).'.*cos(thetap_Jy))./(2*pi.*rp_Jy.^2)).*(1+1./(1i*k.*rp_Jy)).*exp(-1i*k.*rp_Jy);
    Ep_thetap_Jy = (1i*eta*k*Jmat(:,4).'.*sin(thetap_Jy)./(4*pi*rp_Jy)).*(1+1./(1i*k*rp_Jy)-1./(k^2*rp_Jy.^2)).*exp(-1i*k.*rp_Jy);
    Ep_phip_Jy = zeros(1,length(Ep_rp_Jy));
    
    % spi to car mat
    %Build the spherical to cartesian "matrix" (Each element is
    %actually a vector)
    sph2cart11 = sin(thetap_Jy).*cos(phip_Jy);
    sph2cart12 = cos(thetap_Jy).*cos(phip_Jy);
    sph2cart13 = -sin(phip_Jy);
    sph2cart21 = sin(thetap_Jy).*sin(phip_Jy);
    sph2cart22 = cos(thetap_Jy).*sin(phip_Jy);
    sph2cart23 = cos(phip_Jy);
    sph2cart31 = cos(thetap_Jy);
    sph2cart32 = -sin(thetap_Jy);
    sph2cart33 = 0*thetap_Jy;
    Ex_p_Jy = sph2cart11.*Ep_rp_Jy + sph2cart12.*Ep_thetap_Jy + sph2cart13.*Ep_phip_Jy;
    Ey_p_Jy = sph2cart21.*Ep_rp_Jy + sph2cart22.*Ep_thetap_Jy + sph2cart23.*Ep_phip_Jy;
    Ez_p_Jy = sph2cart31.*Ep_rp_Jy + sph2cart32.*Ep_thetap_Jy + sph2cart33.*Ep_phip_Jy;
    %Convert E_prime to E (the global coordinate system)
    E_Jy = sum(Ay'*[Ex_p_Jy;Ey_p_Jy;Ez_p_Jy],2);
    
    nf.Ex(n) = E_Jx(1)+E_Jy(1);
    nf.Ey(n) = E_Jx(2)+E_Jy(2);
    nf.Ez(n) = E_Jx(3)+E_Jy(3);
%     if abs(nf.Ex(n))>0.001
%         pause;
%     end
    nf.Etheta(n) = nf.Ex(n)*cos(nf.theta(n))+nf.Ey(n)*sin(nf.theta(n));
end




end

