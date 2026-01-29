function varargout = iterativeThreshold(x,initThresh,err,lambda,stopAtLowestThreshold,useMad)
% thresh = iterativeThreshold(x)
% thresh = iterativeThreshold(x,initThresh)
% thresh = iterativeThreshold(x,initThresh,err)
% thresh = iterativeThreshold(x,initThresh,err,lambda)
% thresh = iterativeThreshold(x,initThresh,err,lambda,stopAtLowestThreshold,useMad)
% [thresh,threshHist] = iterativeThreshold(...)
%
% iterative threshold determination. Finds a symmetric threshold, but
% return only upper threshold
% - 02/14/2018: added condition to gurantee convergence to lower bound
% - 02/19/2018: estimate SD using MAD (robust to outliers)
%
% Reference:
% Nystrom and Holmqvist 2010,  "An adaptive algorithm for fixation,
% saccade, and glissade detection in eyetracking data", Behav. Research.
% Method.
%
% Ben Voloh, 2018

%check inputs
if nargin <2 || isempty(initThresh)
    initThresh = max(abs(x));
end
if nargin <3 || isempty(err)
    %sd = nanstd(x)*6;
    prc = prctile(x,[0.0005, 0.0005]);
    err = max(abs(prc));
end
if nargin <4 || isempty(lambda)
    lambda = 6;
end
if nargin < 5 || isempty(stopAtLowestThreshold)
    stopAtLowestThreshold = 0;
end
if nargin<6 || isempty(useMad)
    useMad = 0;
end
if nargout > 1
    storeThreshHist = 1;
    threshHist = [];
else
    storeThreshHist = 0;
end

%iterative thresh detection
thresh = initThresh;
currErr = err*2;
icount=0;
while currErr > err
    if storeThreshHist
        threshHist(numel(threshHist)+1,1) = thresh;
    end
    
    %calculate new threshold
    tmp = x( abs(x) < thresh );
    if useMad
        mu = nanmedian(tmp);
        sd = 1.4826 * mad(tmp,1) * lambda; 
    else
        mu = nanmean(tmp);
        sd = nanstd(tmp)*lambda;
    end
    newThresh = mu + sd;
    
    %only allow error to go down (DANGEROUS)
    if stopAtLowestThreshold && newThresh > thresh
        newThresh = thresh;
    end
    
    %add this so it doesnt hang when the error doesnt change, but still
    %higher than acceptable
    newErr = abs(newThresh - thresh);
    if newErr==currErr
        if currErr > err
            warning('could not converge to %.3g error, exiting with error of %.3g',err,newErr)
        end
        currErr = 0;
    else
        currErr = newErr;
    end
    thresh = newThresh;
    
    icount=icount+1;
    if icount > 200
        foo=1;
    end
end

%output
varargout{1} = thresh;
if nargout>1
    varargout{2} = threshHist;
end