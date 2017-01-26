function [ A_FF ] = ff_operatorMat_generator( recon, ff, freq )
%ff.x
%ff.y
%ff.z
%recon.x
%recon.y
%recon.z


%% Constants
c = 299792458;
eta = 120*pi;
lambda = c/freq;
k0 = 2*pi/lambda;
% rotation matrix
Ay = [1,0,0;0,cosd(90),-sind(90);0,sind(90),cosd(90)]; % rotate around x -90deg
Ax = [cosd(-90),0,sind(-90);0,1,0;-sind(-90),0,cosd(-90)]; % rotate around y 90deg
%%
A_FF.xx = zeros(size(ff.x,1),size(recon.x,1));
A_FF.xy = zeros(size(ff.x,1),size(recon.x,1));
A_FF.yx = zeros(size(ff.x,1),size(recon.x,1));
A_FF.yy = zeros(size(ff.x,1),size(recon.x,1));
A_FF.zx = zeros(size(ff.x,1),size(recon.x,1));
A_FF.zy = zeros(size(ff.x,1),size(recon.x,1));

%Iterate over each column of the matrix
for ii = 1:size(recon.x,1)
    
    % First compute the current column of the AJ1_x matrix
    %compute the primed coordinates
    x_px1 = Ax(1,1)*(ff.x - recon.x(ii,1)) + Ax(1,2)*(ff.y - recon.y(ii,1)) + Ax(1,3)*(ff.z - recon.z(ii,1));
    y_px1 = Ax(2,1)*(ff.x - recon.x(ii,1)) + Ax(2,2)*(ff.y - recon.y(ii,1)) + Ax(2,3)*(ff.z - recon.z(ii,1));
    z_px1 = Ax(3,1)*(ff.x - recon.x(ii,1)) + Ax(3,2)*(ff.y - recon.y(ii,1)) + Ax(3,3)*(ff.z - recon.z(ii,1));
    
    %Convert the cartesian primed coordinates to spherical primed coords.
    r_px1 = sqrt(x_px1.^2 + y_px1.^2 + z_px1.^2);
    theta_px1 = acos(z_px1./r_px1);
    phi_px1 = atan2(y_px1,x_px1);
    
    %Build the spherical to cartesian "matrix" (Each element is
    %actually a vector)
    sph2cart11 = sin(theta_px1).*cos(phi_px1);
    sph2cart12 = cos(theta_px1).*cos(phi_px1);
    sph2cart13 = -sin(phi_px1);
    sph2cart21 = sin(theta_px1).*sin(phi_px1);
    sph2cart22 = cos(theta_px1).*sin(phi_px1);
    sph2cart23 = cos(phi_px1);
    sph2cart31 = cos(theta_px1);
    sph2cart32 = -sin(theta_px1);
    sph2cart33 = 0*theta_px1;
    
%     %Compute E_prime at all of the far-field locations
%     E_theta_px1 = 1i*eta0*k0*sin(theta_px1)./(4*pi*r_px1).*(ones(size(r_px1)) + 1./(1i*k0*r_px1) - 1./((k0*r_px1).^2)).*exp(-1i*k0*r_px1);
%     E_phi_px1 = 0*r_px1;
%     E_r_px1 = eta0./(2*pi*r_px1.^2).*cos(theta_px1).*(ones(size(r_px1)) + 1./(1i*k0*r_px1)).*exp(-1i*k0*r_px1);
%     

    %Compute E_prime at all of the far-field locations
    E_theta_px1 = 0*r_px1;
    E_phi_px1 = -1i*k0*exp(-1i*k0*r_px1).*sin(theta_px1)./(4*pi*r_px1).*(ones(size(r_px1)) + 1./(1i*k0*r_px1));
    E_r_px1 = 0*r_px1;
      
    %Convert E_prime from spherical to cartesian
    Ex_px1 = sph2cart11.*E_r_px1 + sph2cart12.*E_theta_px1 + sph2cart13.*E_phi_px1;
    Ey_px1 = sph2cart21.*E_r_px1 + sph2cart22.*E_theta_px1 + sph2cart23.*E_phi_px1;
    Ez_px1 = sph2cart31.*E_r_px1 + sph2cart32.*E_theta_px1 + sph2cart33.*E_phi_px1;
    
    %Store the "field" at the measurement locations as the current column
    %of the matrix
    A_FF.xx(:,ii) = Ax(1,1)*Ex_px1 + Ax(2,1)*Ey_px1 + Ax(3,1)*Ez_px1;
    A_FF.yx(:,ii) = Ax(1,2)*Ex_px1 + Ax(2,2)*Ey_px1 + Ax(3,2)*Ez_px1;
    A_FF.zx(:,ii) = Ax(1,3)*Ex_px1 + Ax(2,3)*Ey_px1 + Ax(3,3)*Ez_px1;
    
    % Secondly compute the current column of the AJ1_y matrix
    %compute the primed coordinates
    x_py1 = Ay(1,1)*(ff.x - recon.x(ii,1)) + Ay(1,2)*(ff.y - recon.y(ii,1)) + Ay(1,3)*(ff.z - recon.z(ii,1));
    y_py1 = Ay(2,1)*(ff.x - recon.x(ii,1)) + Ay(2,2)*(ff.y - recon.y(ii,1)) + Ay(2,3)*(ff.z - recon.z(ii,1));
    z_py1 = Ay(3,1)*(ff.x - recon.x(ii,1)) + Ay(3,2)*(ff.y - recon.y(ii,1)) + Ay(3,3)*(ff.z - recon.z(ii,1));
    
    %Convert the cartesian primed coordinates to spherical primed coords.
    r_py1 = sqrt(x_py1.^2 + y_py1.^2 + z_py1.^2);
    theta_py1 = acos(z_py1./r_py1);
    phi_py1 = atan2(y_py1,x_py1);
    
    %Build the spherical to cartesian "matrix" (Each element is
    %actually a vector)
    sph2cart11 = sin(theta_py1).*cos(phi_py1);
    sph2cart12 = cos(theta_py1).*cos(phi_py1);
    sph2cart13 = -sin(phi_py1);
    sph2cart21 = sin(theta_py1).*sin(phi_py1);
    sph2cart22 = cos(theta_py1).*sin(phi_py1);
    sph2cart23 = cos(phi_py1);
    sph2cart31 = cos(theta_py1);
    sph2cart32 = -sin(theta_py1);
    sph2cart33 = 0*theta_py1;
    
%     %Compute E_prime at all of the far-field locations
%     E_theta_py1 = 1i*eta0*k0*sin(theta_py1)./(4*pi*r_py1).*(ones(size(r_py1)) + 1./(1i*k0*r_py1) - 1./((k0*r_py1).^2)).*exp(-1i*k0*r_py1);
%     E_phi_py1 = 0*r_py1;
%     E_r_py1 = eta0./(2*pi*r_py1.^2).*cos(theta_py1).*(ones(size(r_py1)) + 1./(1i*k0*r_py1)).*exp(-1i*k0*r_py1);

    %Compute E_prime at all of the far-field locations
    E_theta_py1 = 0*r_py1;
    E_phi_py1 = -1i*k0*exp(-1i*k0*r_py1).*sin(theta_py1)./(4*pi*r_py1).*(ones(size(r_py1)) + 1./(1i*k0*r_py1));
    E_r_py1 = 0*r_py1;

    %Convert E_prime from spherical to cartesian
    Ex_py1 = sph2cart11.*E_r_py1 + sph2cart12.*E_theta_py1 + sph2cart13.*E_phi_py1;
    Ey_py1 = sph2cart21.*E_r_py1 + sph2cart22.*E_theta_py1 + sph2cart23.*E_phi_py1;
    Ez_py1 = sph2cart31.*E_r_py1 + sph2cart32.*E_theta_py1 + sph2cart33.*E_phi_py1;
    
    %Store the "field" at the measurement locations as the current column
    %of the matrix
    A_FF.xy(:,ii) = Ay(1,1)*Ex_py1 + Ay(2,1)*Ey_py1 + Ay(3,1)*Ez_py1;
    A_FF.yy(:,ii) = Ay(1,2)*Ex_py1 + Ay(2,2)*Ey_py1 + Ay(3,2)*Ez_py1;
    A_FF.zy(:,ii) = Ay(1,3)*Ex_py1 + Ay(2,3)*Ey_py1 + Ay(3,3)*Ez_py1;
    
    
end

%Construct the entire operator matrix. The factor of two is because we are
%applying image theory and only considering M
%A_FF.mat = 2*[A_FF.xy A_FF.xx; A_FF.yy A_FF.yx; A_FF.zy A_FF.zx];
A_FF.mat = [A_FF.xx A_FF.xy; A_FF.yx A_FF.yy; A_FF.zx A_FF.zy];


end

