function [x2,y2] = acds2screen(x,y,screenx,screeny)

x2 = x * screenx - screenx/2;
y2 = screeny - y * screeny - screeny/2; %flip
