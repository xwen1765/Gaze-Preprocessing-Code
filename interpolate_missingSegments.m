function xout = interpolate_missingSegments(x,maxConsecutiveBadSamples,interpType)
% xout = interpolate_missingSegments(x)
% xout = interpolate_missingSegments(x,maxConsecutiveBadSamples)
% xout = interpolate_missingSegments(x,maxConsecutiveBadSamples,interpType)

%settings
xout = x;

if nargin < 2
    maxConsecutiveBadSamples = 1;
end
if nargin < 3
    interpType = 'pchip';
end
if ~isrow(xout); xout = xout'; doTranspose = 1; 
else doTranspose = 0;
end 

 
%loop over the max allowbale number of consecutive bad samples
for im=1:maxConsecutiveBadSamples
     
    %define the target template that we'll be looking for
    target = [0,ones(1,im),0];

    %find the bad segments
    bad = isnan(xout);
    itarget = strfind(bad,target)';
    
    if ~isempty(itarget)
        %add an offset to account for the indexing

        offset = repmat(find(target),numel(itarget),1) - 1;
        itarget = bsxfun(@plus,offset,itarget);
        itarget = itarget(:);
        n = numel(itarget);
        itarget = unique(itarget);
        if numel(itarget) < n
            warning ('interpolating over some good, observed data')
        end

        %interpolate
        xout(itarget) = interp1(find(~bad),xout(~bad),itarget,interpType);
    end
end
 
%finalize
if doTranspose
    xout = xout';
end
    