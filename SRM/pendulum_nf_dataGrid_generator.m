function [ grid,Tpendulum, maxDis, thetaAUT ] = pendulum_nf_dataGrid_generator( l,dt,theta0,omegaAUT,freq)
% l is the length of the arm [m]
% dt is measurement time interval [sec]
% theta0 is pendulum swing angle [deg]
% onegaAUT is the angular velocity of the AUT [deg/sec]

% grid contains x, y, tan angle, norm angle
% Tpendulum period of pendulum
% maxDis is the max distance between two measurement points [lamda]
%% constant
c = 299792458;
g = 9.81;
lamda = c/freq;
omegaAUT = omegaAUT*pi/180;
T = 2*pi/omegaAUT; % period of AUT
numPoints = ceil(T/dt); % number of measurement points

%% initial value
theta0 = theta0*pi/180; % pendulum initial angle
thetaAUT0 = 0*pi/180; % AUT initial angle
omega0 = 0; % pendulum initial angular velocity [rad/sec]

%% solving pendulum equation
time = zeros(numPoints,1); % time stamp vector
theta = zeros(length(time),1); % pendulum angle vector 
omega = zeros(length(time),1); % pendulum angluar velocity vector
tanAng = zeros(length(time),1); % angle of tangent to the arc
norAng = zeros(length(time),1); % angle of normal  to the arc

time(1) = 0;
theta(1) = theta0;
omega(1) = omega0;
tanAng(1) = theta0;
norAng(1) = theta0+pi/2;

% pendulum equation
for n = 1:numPoints
    time(n+1) = time(n)+dt;
    theta(n+1) = theta(n)+dt*omega(n);
    omega(n+1) = omega(n)-dt*(g/l*sin(theta(n+1)));
    tanAng(n+1) = theta(n+1);
    norAng(n+1) = theta(n+1)+pi/2;
end

%find freq and period of the pendulum
freqSample = 1/dt;
NFFT=1024^2;	 	 
Xff=fftshift(fft(theta,NFFT));	 	 
fVals=freqSample*(-NFFT/2:NFFT/2-1)/NFFT;
freqTheta = abs(Xff);
[maxfft,maxid] = max(freqTheta);
freqPendulum = abs(fVals(maxid));
Tpendulum = 1/freqPendulum;

%% coordinate transformation
%normal pendulum coordinate 
x = sin(theta).*l;
y = -cos(theta).*l;
%pendulum highest point at (0,0)
xp = x+l*sin(theta0);
yp = y+l*cos(theta0);
% AUT is moving at constant anguar velocity omegaAUT
dthetaAUT = omegaAUT * dt;
thetaAUT = (thetaAUT0:dthetaAUT:dthetaAUT*(length(time)-1)+thetaAUT0)'; % angle of the AUT in a vector
% Rotation Mat around z axis
Rot = zeros(3,3,length(time));
Rot(1,1,:) = cos(thetaAUT);
Rot(1,2,:) = -sin(thetaAUT);
Rot(2,1,:) = sin(thetaAUT);
Rot(2,2,:) = cos(thetaAUT);
Rot(3,3,:) = 1;
% AUT coordinate
for n=1:length(time)
    P(:,:,n) = Rot(:,:,n)*[xp(n);yp(n);0];
end
x_aut = squeeze(P(1,1,:));
y_aut = squeeze(P(2,1,:));
tan_aut = tanAng+thetaAUT;
nor_aut = norAng+thetaAUT;
% tan_aut = tanAng+thetaAUT+pi/4;
% nor_aut = norAng+thetaAUT+pi/4;

grid = [x_aut,y_aut,tan_aut,nor_aut];

% plots
figure;
quiver(x_aut/lamda,y_aut/lamda,cos(tan_aut),sin(tan_aut));
hold;
quiver(x_aut/lamda,y_aut/lamda,cos(nor_aut),sin(nor_aut));
axis('equal');
hold;
figure;
plot(x_aut/lamda,y_aut/lamda,'o');
axis('equal');

%% find max distance between two measurement point
% max adjacent measurement point distance determined by dt
% max outer egde point distance determined by omegaAUT
disAdj = zeros(length(time)-1,1);
for i=1:length(disAdj)
    disAdj(i) = sqrt((x_aut(i+1)-x_aut(i))^2+(y_aut(i+1)-y_aut(i))^2);
end
maxDisAdj = max(disAdj);
dis2Center = zeros(length(time),1);
for i=1:length(dis2Center)
    dis2Center(i) = sqrt(x_aut(i)^2+y_aut(i)^2);
end
[maxDis2Cen,maxDis2CenId] = max(dis2Center);
nextEdgePointId = mod((ceil(Tpendulum/dt)+maxDis2CenId),length(time));
maxDisEdg = sqrt((x_aut(nextEdgePointId)-x_aut(maxDis2CenId))^2+(y_aut(nextEdgePointId)-y_aut(maxDis2CenId))^2);
maxDis = max(maxDisEdg,maxDisAdj)/lamda;
end

