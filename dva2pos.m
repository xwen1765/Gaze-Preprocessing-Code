function x = dva2pos(v,d)
% x = visualangle2pos(v,d)

if isrow(d) && ~isrow(v); v = v'; end

%v = rad2deg( 2 * atan( xest./ (2*d) ) );
x = 2 .* d .* tan(v./2);