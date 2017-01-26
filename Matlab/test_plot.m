clc;
clear all;
close all;

c = 3e8;
f = 10e9;
lamda = c/f;
l = 0.924;
mat = csvread('testing.txt');
x = mat(:,2);
y = mat(:,3);
% penAng = mat(:,3);
% motorAng = mat(:,4);
phase_angle = mat(:,6);
isNormal = mat(:,end);
factor = 4;
xn = [];
yn = [];
xt = [];
yt = [];
for i = 1:length(x)
    if isNormal(i)
        xn = [xn;x(i)];
        yn = [yn;y(i)];
    else
        xt = [xt;x(i)];
        yt = [yt;y(i)];
    end
end



figure;
plot(xn./lamda,yn./lamda,'o');
% plot(x(1:end/factor)./lamda,y(1:end/factor)./lamda,'o');
axis('equal');

figure;
plot(xt./lamda,yt./lamda,'o');
% plot(x(1:end/factor)./lamda,y(1:end/factor)./lamda,'o');
axis('equal');

figure;
quiver(x/lamda,y/lamda,cosd(phase_angle),sind(phase_angle));
axis('equal');

% figure;
% plot(motorAng,penAng,'o');
% plot(motorAng(1:end/factor),penAng(1:end/factor),'o');

% penAng = mat(:,2);
% time = mat(:,1);
% figure;
% plot(time,penAng,'o');
% 
% dis = zeros(length(penAng)-1,1);
% count = 0;
% for i = 1:length(dis)
%     dis(i) = (abs(penAng(i+1)-penAng(i))*pi/180)*l/lamda;
%     if dis(i)>0.5
%         count = count+1;
%     end
% end
% figure;
% plot(dis,'o')
% max(dis)
% mean(dis)
% count/length(penAng)*100

% time = mat(:,1);
% figure;
% plot(time,'o');