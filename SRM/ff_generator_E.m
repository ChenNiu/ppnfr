function [ ff ] = ff_generator_E( Jmat, ff, freq )
% Jmat is [x,y,Jx,Jy], each var is a vector
% ff.theta is a vector of theta in degreees
% ff.phi is a a vertor of phi in degrees
% ff.r is a NUMBER r in meters
% default ff.r = 100*lamda
% output:
% ff.x
% ff.y
% ff.z
% ff.Ex
% ff.Ey
% ff.Ez

%% Constants
c = 299792458;
eta = 120*pi;
lambda = c/freq;
k = 2*pi/lambda;
%%
% outer product theta is vec, phi is roll
ff.x = ff.r*sind(ff.theta)*cosd(ff.phi)';
ff.y = ff.r*sind(ff.theta)*sind(ff.phi)';
ff.z = ff.r*cosd(ff.theta)*ones(1,length(ff.phi));
% unroll the matrix
ff.x = reshape(ff.x,[],1);
ff.y = reshape(ff.y,[],1);
ff.z = reshape(ff.z,[],1);
% initialize
ff.Ex = zeros(length(ff.x),1);
ff.Ey = zeros(length(ff.x),1);
ff.Ez = zeros(length(ff.x),1);


%%
% rotation matrix 
Ay = [1,0,0;0,cosd(90),-sind(90);0,sind(90),cosd(90)]; % rotate around x -90deg
Ax = [cosd(-90),0,sind(-90);0,1,0;-sind(-90),0,cosd(-90)]; % rotate around y 90deg
% iterative of ff points
for n=1:length(ff.x)
    % before rotation 
    rp_c = [(ff.x(n)-Jmat(:,1))';(ff.y(n)-Jmat(:,2))';ff.z(n)*ones(1,size(Jmat,1))];
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
    
    ff.Ex(n) = E_Jx(1)+E_Jy(1);
    ff.Ey(n) = E_Jx(2)+E_Jy(2);
    ff.Ez(n) = E_Jx(3)+E_Jy(3);

end


end
