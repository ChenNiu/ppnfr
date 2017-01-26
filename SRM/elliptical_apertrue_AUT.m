function output = elliptical_apertrue_AUT( major, minor, sep, theta_x, phi_x, theta_y, phi_y, freq)
% sep is the speration of two dipole
% this function will return a 2d matrix every roll will be [x,y] 
% major is the major axis of the ellipse in terms of lamda
% minor is the minor axis of the ellipse in terms of lamda
% sep is the step size of each current diople ellipse in terms of lamda
% theta_x,phi_x,theta_y,phi_y phase tapering in degs
% freq is frequency is Hz
% the output mat is [x,y,Jx,Jy], each var is a vector
%% 
c = 299792458;
lamda = c/freq;
I0 = 1;
t=0:pi/10:2*pi;
%%
major = major*lamda;
minor = minor*lamda;
sep = sep*lamda;
theta_x = theta_x*pi/180;
phi_x = phi_x*pi/180;
theta_y = theta_y*pi/180;
phi_y = phi_y*pi/180;

%%

x=(major/2)*cos(t);
y=(minor/2)*sin(t);
%points to be checked
output = null(4);
% if a point is inside the ellipse Jx and Jy will be calculated and
% appended along with the location x and y
for xq=-major/2:sep:major/2
    for yq=-minor/2:sep:minor/2
        if(inpolygon(xq,yq,x,y))
            Jx = I0*exp(1i*(-2*pi*xq*sin(theta_x)*cos(phi_x)/lamda-2*pi*yq*sin(theta_x)*sin(phi_x)/lamda));
            Jy = I0*exp(1i*(-2*pi*xq*sin(theta_y)*cos(phi_y)/lamda-2*pi*yq*sin(theta_y)*sin(phi_y)/lamda));
            output = [output;[xq,yq,Jx,Jy]];
        end
    end
end

figure,
quiver(output(:,1)/lamda,output(:,2)/lamda,abs(output(:,3)),abs(output(:,4)),0.15);
axis equal;
xlabel('x-axis[\lambda]');
ylabel('y-axis[\lambda]');
savefig('elliptical_current_distribution');

end

