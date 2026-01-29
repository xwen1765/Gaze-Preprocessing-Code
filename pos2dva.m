function v = pos2dva(xest,d)
% v = pos2dva(xest,d)
%
% xest and pos ahve to be in the same units (meters, or millimeters etc)
if isempty(xest) || isempty(d); v = []; return; end
if isrow(xest) ~= isrow(d); d = d'; end

v = (180/pi)*( 2 * atan( xest./ (2*d) ) );