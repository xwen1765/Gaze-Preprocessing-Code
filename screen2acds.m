function [x2,y2] = screen2acds(x,y,screenx,screeny)

%x2 = x * screenx - screenx/2;
%y2 = screeny - y * screeny - screeny/2; %flip
x2 = (x+screenx/2)/screenx;
y2 = (screeny/2-y)/screeny; %flip back
%asd=1;
