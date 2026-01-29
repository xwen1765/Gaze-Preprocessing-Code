function varargout = movemean(x,winlen,includeCurrentPoint,omitNan)
% mu = movemean(x,winlen)
% mu = movemean(x,[nr,nf])
% mu = movemean(x,[nr,nf],includeCurrentPoint)
% mu = movemean(x,[nr,nf],includeCurrentPoint,omitNan)
% [mu,n] = movemean(x,[nr,nf],includeCurrentPoint,omitNan)
%
% calculates the moving average in input signal x over a window of length
% w. Can specify number of leading or lagging samples with [nr,nf]
%
% % Ben Voloh, 2018

if nargin < 3
    includeCurrentPoint = 1;
end
if nargin < 4
    omitNan = 0;
end

%create the window
if numel(winlen)==1 
   win = ones(1,winlen) ./ winlen;
else %defined lead and lag
    st = ones(1,winlen(1));
    fn = ones(1,winlen(2));
    
    if includeCurrentPoint
        c = 1;
    else
        c = 0;
    end
    
    %pad if windows arent symmetrical
    % - nb: convolution requirs flipping
    d = diff(winlen);
    if d < 0 %left flank is greater
        win = [zeros(1,abs(d)),fn,c,st];
    elseif d > 0 %right flank is greater
        win = [fn,c,st,zeros(1,abs(d))];
    end
end

N = length(x);              % length of the signal

%prepare for nan consideration
x2 = x;
if omitNan
    nans = isnan(x);
    nanVec = zeros(size(x));
    bad = max(x)*2;
    nanVec(nans) = bad;
    x2(nans) = bad;
end

%sum and number of elements
s = conv(x2,win,'same');
n = conv(ones(size(x2)), win, 'same');

if omitNan
    sc = conv(nanVec,win,'same');
    s = s - sc;
    
    nc = conv(double(nans),win,'same');
    n = n - nc;
end

%mean
mu = s ./ n;

varargout{1} = mu;
if nargout>1
    varargout{2} = n;
end
