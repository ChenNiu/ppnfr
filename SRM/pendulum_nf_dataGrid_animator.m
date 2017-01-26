clc;
clear all;
close all;
%% contents
freq = 10e9;
c = 299792458;
lamda = c/freq;

%% Near-field Measurement Plane

% length of the pendulum arm
l = 20*lamda;
% dt is measurement time interval [sec]
dt = 0.05;
omegaAUT = 10; %x deg per sec
theta0 = 30;

[ nfGrid,Tpendulum, maxDis, thetaAUT ] = pendulum_nf_dataGrid_generator( l,dt,theta0,omegaAUT,freq);


%%

option = 1;
if option == 1
    nf.x = [nfGrid(:,1);nfGrid(:,1)];
    nf.y = [nfGrid(:,2);nfGrid(:,2)];
    nf.theta = [nfGrid(:,3);nfGrid(:,4)];
    
elseif option == 2
    nf.x = nfGrid(:,1);
    nf.y = nfGrid(:,2);
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
    nf.theta = nfGrid(:,3);
end


%% Coordinate transformation
% Rotation Mat around z axis

thetaAUT = [thetaAUT;thetaAUT];
Rot = zeros(3,3,length(thetaAUT));
Rot(1,1,:) = cos(-thetaAUT);
Rot(1,2,:) = -sin(-thetaAUT);
Rot(2,1,:) = sin(-thetaAUT);
Rot(2,2,:) = cos(-thetaAUT);
Rot(3,3,:) = 1;







%% plot near-fild measurement points

scale = 0.35;
midpoint = length(nf.x)/2;
figure;
quiver(nf.x(1:2:midpoint)/lamda,nf.y(1:2:midpoint)/lamda,cos(nf.theta(1:2:midpoint)),sin(nf.theta(1:2:midpoint)),scale,'b');
axis('equal');
hold on;
quiver(nf.x(midpoint:2:end)/lamda,nf.y(midpoint:2:end)/lamda,cos(nf.theta(midpoint:2:end)),sin(nf.theta(midpoint:2:end)),scale,'r');
hold off;


% scale = 0.25;
% figure;
% quiver(nf.x(1)/lamda,nf.y(1)/lamda,cos(nf.theta(1)),sin(nf.theta(1)),scale,'b');
% axis('equal');
% axis([min(nf.x)/lamda,max(nf.x)/lamda,min(nf.y)/lamda,max(nf.y)/lamda]);
% hold on;
% for i=2:length(nf.x)
%     pause(dt);
%     quiver(nf.x(i)/lamda,nf.y(i)/lamda,cos(nf.theta(i)),sin(nf.theta(i)),scale,'b');
% end
% hold off;


dt = dt*0.5;
figure;
for i=1:length(thetaAUT)/2
    locRel2earth = Rot(:,:,i)*[nf.x';nf.y';zeros(1,length(nf.x))]; % coordinate relateive to earth
    quiver(locRel2earth(1,1:i)'/lamda,locRel2earth(2,1:i)'/lamda,cos(nf.theta(1:i)-thetaAUT(i)),sin(nf.theta(1:i)-thetaAUT(i)),scale,'b');
    axis('equal');
    axis([min(nf.x)/lamda-1,max(nf.x)/lamda+1,min(nf.y)/lamda-1,max(max(nf.y)/lamda,l/lamda*cosd(theta0))+1]);
    hold on;
    plot([locRel2earth(1,i)/lamda,l/lamda*sind(theta0)],[locRel2earth(2,i)/lamda,l/lamda*cosd(theta0)],'k','LineWidth',2);
    hold off;
    if i>10&&i<100
        figName = sprintf('animation%d',i)
        saveas(gcf,fullfile('animation_figures',figName),'jpeg');
    end
    %pause(dt);
end

for i=length(thetaAUT)/2+1:length(thetaAUT)
    locRel2earth = Rot(:,:,i)*[nf.x';nf.y';zeros(1,length(nf.x))]; % coordinate relateive to earth
    quiver(locRel2earth(1,1:length(thetaAUT)/2)'/lamda,locRel2earth(2,1:length(thetaAUT)/2)'/lamda,cos(nf.theta(1:length(thetaAUT)/2)-thetaAUT(i)),sin(nf.theta(1:length(thetaAUT)/2)-thetaAUT(i)),scale,'b');
    axis('equal');
    axis([min(nf.x)/lamda-1,max(nf.x)/lamda+1,min(nf.y)/lamda-1,max(max(nf.y)/lamda,l/lamda*cosd(theta0))+1]);
    hold on;
    quiver(locRel2earth(1,length(thetaAUT)/2+1:i)'/lamda,locRel2earth(2,length(thetaAUT)/2+1:i)'/lamda,cos(nf.theta(length(thetaAUT)/2+1:i)-thetaAUT(i)),sin(nf.theta(length(thetaAUT)/2+1:i)-thetaAUT(i)),scale,'r');
    plot([locRel2earth(1,i)/lamda,l/lamda*sind(theta0)],[locRel2earth(2,i)/lamda,l/lamda*cosd(theta0)],'k','LineWidth',2);
    hold off;
    if i>length(thetaAUT)/2+10&&i<length(thetaAUT)/2+100
        figName = sprintf('animation%d',i)
        saveas(gcf,fullfile('animation_figures',figName),'jpeg');
    end
    %pause(dt);
end






