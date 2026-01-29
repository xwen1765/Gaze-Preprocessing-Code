function [xdeg,ydeg] = acds2dva(x,y,d,screenX,screenY)
% [xdeg,ydeg] = acds2dva(x,y,d,screenX,screenY)

[x2,y2] = acds2screen(x,y,screenX,screenY);
xdeg = pos2dva(x2,d);
ydeg = pos2dva(y2,d);