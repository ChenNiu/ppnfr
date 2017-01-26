function [ A ] = nf_operatorMat_generator( recon, nf, freq )
% recon.step is the recon plane grid spacing
% recon.dist is the distance from recon plane to antenna
% recon.xSize is the size of the recon plane is x dimension
% recon.ySize is the size of the recon plane is y dimension
% recon.x is the vector x
% recon.y is the vector y
% recon.z is the vector z

% nf.x is the vector x
% nf.y is the vector y
% nf.z is the vector z
% nf.theta is vector of the angle of E respect to x direction
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
% initialize matrix A
A = zeros(length(nf.x),2*length(recon.x));
% rotation matrix
Ay = [1,0,0;0,cosd(90),-sind(90);0,sind(90),cosd(90)]; % rotate around x -90deg
Ax = [cosd(-90),0,sind(-90);0,1,0;-sind(-90),0,cosd(-90)]; % rotate around y 90deg

% iterative of nf points, row of mat A
for n=1:length(nf.x)
    % left side of the mat due to Mx
    % before rotation
    rp_c = [(nf.x(n)-recon.x)';(nf.y(n)-recon.y)';(nf.z(n)-recon.z)'];
    % rotation for x directed current
    rp_cp_Mx = Ax*rp_c;
    %Convert the cartesian primed coordinates to spherical primed coords.
    rp_Mx = sqrt(rp_cp_Mx(1,:).^2+rp_cp_Mx(2,:).^2+rp_cp_Mx(3,:).^2);
    thetap_Mx = acos(rp_cp_Mx(3,:)./rp_Mx);
    phip_Mx = atan2(rp_cp_Mx(2,:),rp_cp_Mx(1,:));
    % Compute E_prime at the near-field locations due to all x directed current
    % dipoles Mx
    Ep_rp_Mx = 0*rp_Mx;
    Ep_phip_Mx =  -1i*k.*exp(-1i*k.*rp_Mx).*sin(thetap_Mx)./(4*pi.*rp_Mx).*(1 + 1./(1i*k.*rp_Mx));
    Ep_thetap_Mx = 0*rp_Mx;
    %Build the spherical to cartesian "matrix" (Each element is
    %actually a vector)
    sph2cart11 = sin(thetap_Mx).*cos(phip_Mx);
    sph2cart12 = cos(thetap_Mx).*cos(phip_Mx);
    sph2cart13 = -sin(phip_Mx);
    sph2cart21 = sin(thetap_Mx).*sin(phip_Mx);
    sph2cart22 = cos(thetap_Mx).*sin(phip_Mx);
    sph2cart23 = cos(phip_Mx);
    sph2cart31 = cos(thetap_Mx);
    sph2cart32 = -sin(thetap_Mx);
    sph2cart33 = 0*thetap_Mx;
    Ex_p_Mx = sph2cart11.*Ep_rp_Mx + sph2cart12.*Ep_thetap_Mx + sph2cart13.*Ep_phip_Mx;
    Ey_p_Mx = sph2cart21.*Ep_rp_Mx + sph2cart22.*Ep_thetap_Mx + sph2cart23.*Ep_phip_Mx;
    Ez_p_Mx = sph2cart31.*Ep_rp_Mx + sph2cart32.*Ep_thetap_Mx + sph2cart33.*Ep_phip_Mx;
    % E due to Mx
    E_Mx = Ax'*[Ex_p_Mx;Ey_p_Mx;Ez_p_Mx];
    % prejection to theta direction
    E_theta_Mx = E_Mx(1,:)*cos(nf.theta(n))+E_Mx(2,:)*sin(nf.theta(n));
    
    
    % right side mat due to My
    % rotation for x directed current
    rp_cp_My = Ay*rp_c;
    %Convert the cartesian primed coordinates to spherical primed coords.
    rp_My = sqrt(rp_cp_My(1,:).^2+rp_cp_My(2,:).^2+rp_cp_My(3,:).^2);
    thetap_My = acos(rp_cp_My(3,:)./rp_My);
    phip_My = atan2(rp_cp_My(2,:),rp_cp_My(1,:));
    % Compute E_prime at the near-field locations due to all y directed current
    % dipoles My
    Ep_rp_My = 0*rp_My;
    Ep_phip_My =  -1i*k.*exp(-1i*k.*rp_My).*sin(thetap_My)./(4*pi.*rp_My).*(1 + 1./(1i*k.*rp_My));
    Ep_thetap_My = 0*rp_My;
    %Build the spherical to cartesian "matrix" (Each element is
    %actually a vector)
    sph2cart11 = sin(thetap_My).*cos(phip_My);
    sph2cart12 = cos(thetap_My).*cos(phip_My);
    sph2cart13 = -sin(phip_My);
    sph2cart21 = sin(thetap_My).*sin(phip_My);
    sph2cart22 = cos(thetap_My).*sin(phip_My);
    sph2cart23 = cos(phip_My);
    sph2cart31 = cos(thetap_My);
    sph2cart32 = -sin(thetap_My);
    sph2cart33 = 0*thetap_My;
    Ex_p_My = sph2cart11.*Ep_rp_My + sph2cart12.*Ep_thetap_My + sph2cart13.*Ep_phip_My;
    Ey_p_My = sph2cart21.*Ep_rp_My + sph2cart22.*Ep_thetap_My + sph2cart23.*Ep_phip_My;
    Ez_p_My = sph2cart31.*Ep_rp_My + sph2cart32.*Ep_thetap_My + sph2cart33.*Ep_phip_My;
    % E due to My
    E_My = Ay'*[Ex_p_My;Ey_p_My;Ez_p_My];
    % prejection to theta direction
    E_theta_My = E_My(1,:)*cos(nf.theta(n))+E_My(2,:)*sin(nf.theta(n));
    
    A(n,:) = [E_theta_Mx,E_theta_My];
    %A(n,:) = [E_theta_My,E_theta_Mx];
end
%The factor of 2 is because we are applying image theory and only
%considering M
%A = A*2;
end

