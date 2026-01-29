function [xout, yout, disturbance_all] = RemoveArtifacts(xorig,yorig,d,V,screenX,screenY,fsample,t,maxNanTime, timeWindow)
% [xout, yout, disturbance_all] = RemoveArtifacts(xorig,yorig,d,V,screenX,screenY,fsample,t,maxNanTime, timeWindow)

%% settings
plotFigs = 0;
plotIndividualDisturbance = 0;

cleanOneSampleSpike = 1;
cleanHighNoise = 0;

lgnd = {'bad est','offscreen','blink','one sample spike','unstable'};

x = xorig;
y = yorig;
nsmp = numel(V);

disturbance_all = zeros(nsmp,6);

%% bad validity
if strcmp(V, 'Invalid') == 0
	badValidity = V == 0;
else
	badValidity = strcmp(V, 'Invalid');
end

%figure; plotyy(t2,instability,t2,x)        
disturbance_all(badValidity,1) = 1;



%% offscreen
[xdeg,ydeg] = acds2dva(x,y,d,screenX,screenY);
xthresh = pos2dva(screenX/2,nanmean(d)) + 1.5;
ythresh = pos2dva(screenY/2,nanmean(d)) + 1.5;

offscreen = abs(xdeg) > xthresh | abs(ydeg) > ythresh;
disturbance_all(offscreen,2) = 1;


%% missing data
maxBlinkDuration = 0.7;
minBlinkDuration = 0.05;

maxBlinkSamples = ceil(maxBlinkDuration * fsample);
minBlinkSamples = ceil(minBlinkDuration * fsample);

missingDataBorders = y == -1 | isnan(d) | d==0;

if any(missingDataBorders)
    [startEst,endEst] = find_borders(missingDataBorders);
    
    %mark periods of missing data too short or long to qualify as blinks
    dur = endEst - startEst;
    shortDur = find(dur < minBlinkSamples);
    longDur = find (dur > maxBlinkSamples);
    
    fprintf('\n');
    reverseStr = '';
    for i = 1:length(shortDur)
        %print percentage of processing
        percentDone = 100 * i / length(shortDur);
        msg = sprintf('\tMarking short periods (<%g ms) of missing data, %3.1f percent finished.', minBlinkDuration * 1000, percentDone); 
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        
        disturbance_all(startEst(shortDur(i)):endEst(shortDur(i)),3) = 1;
    end
    
    
    fprintf('\n');
    reverseStr = '';
    for i = 1:length(longDur)
        %print percentage of processing
        percentDone = 100 * i / length(longDur);
        msg = sprintf('\tMarking long periods (>%g ms) of missing data, %3.1f percent finished.', maxBlinkDuration * 1000, percentDone); 
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        disturbance_all(startEst(longDur(i)):endEst(longDur(i)),3) = 2;
    end
    
    
    startEst([shortDur, longDur]) = [];
    endEst([shortDur, longDur]) = [];

    [~,iminy] = findpeaks(1-y);
    
    fprintf('\n');
    reverseStr = '';
    %find minima closest to the etsimated blink start and end times
    for i=1:numel(startEst);
        if i==numel(startEst);
            fred=1;
        end
        %print percentage of processing
        percentDone = 100 * i / min(numel(startEst), numel(endEst));
        msg = sprintf('\tMarking medium periods of missing data (probable blinks), %3.1f percent finished.', percentDone); 
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        
        [~,ist] = min( startEst(i) - iminy( iminy <= startEst(i) ) );
        [~,ifn] = min( iminy( iminy >= endEst(i) ) - endEst(i) );
        st = iminy(ist);
        fn = iminy( ifn + sum(iminy <= endEst(i)) );
        if isempty(st); st = 1; end
        if isempty(fn); fn = size(disturbance_all,1); end
        disturbance_all(st:fn,3) = 3;
    end
end
    
%% preemptivel clean the data, so we dont pick up on artifactual deviations
anyDisturbance = sum(disturbance_all,2) > 0;
x(anyDisturbance) = nan;
y(anyDisturbance) = nan;
    
[xdeg2,ydeg2] = acds2dva(x,y,d,screenX,screenY);

%% one sample spike
if cleanOneSampleSpike    
    %settings
    lambdaA = 6;
    winlen = ceil(fsample*0.01);
    
    ibad = 307295;
    %loop over y or x independently
    for iax=1:2
        if iax==1; 
            tmpdeg = xdeg2;
            tmp = x;
        else
            tmpdeg = ydeg2;
            tmp = y;
        end

        %thresholds for filter activation
        % - add a zero to account for taking difference
        
        tmpa = diff(tmpdeg); % change in degrees
        Amin = nanstd(tmpa) * lambdaA;
        dec = tmpa < -Amin;
        inc = tmpa > Amin;
        tmpthresh = zeros(size(tmpa));
        tmpthresh(dec) = -1;
        tmpthresh(inc) = 1;
        oneSS = [strfind(tmpthresh,[-1 1]), strfind(tmpthresh,[1 -1])] + 1;
        twoSS = [strfind(tmpthresh,[-1 0 1]), strfind(tmpthresh,[1 0 -1])] + 1;
        twoSS = [twoSS, twoSS+1];
        %overlap = sum(ismember(oneSS,twoSS));
        sel = sort([oneSS,twoSS]);
        athresh = false(size(tmpthresh));
        athresh(sel) = 1;

        % current velocity should be less than the preceeding X ms
        vcurr = diff(tmpdeg) ./ diff(t');
        vprev = vcurr;
        vprev = movemean(vprev,[winlen,0],0,1);
        vprev(1:winlen) = nan; %ignore edges
        %tmpv(end-winlen:end) = nan;
        vthresh = vcurr > vprev;
        %vthresh = [false;vthresh];

        %loop through all potential OSS
        sel = find( athresh & vthresh );
        %sel = find(athresh);
        for ii=1:numel(sel)
            ii2 = sel(ii);
            if ismember(ii2,oneSS)
                st = max(1,ii2-1);
                fn = min(numel(tmp),ii2+1);
            elseif ismember(ii2,twoSS)
                st = max(1,ii2-1);
                fn = min(numel(tmp),ii2+2);
                ii2 = [ii2, ii2+1];
            else
                error('huh?')
            end
            
            if 0
                pad = 15;
                ind = st-pad:fn+pad;
                pg = plot_gaze_trace(ind,xdeg2(ind),ydeg2(ind),[st,fn]);
                plotcueline([pg.hy,pg,hx,pg.hv],'x',ii2,'r-')
                pause
                close(gcf)
            end

            tmp(ii2) = nanmedian(tmp(st:fn));
            tmp(ii2) = interp1([st,fn],tmp([st,fn]),ii2);
            
            disturbance_all(ii2,4) = 1;
        end

         if iax==1; xout = tmp;
         else yout = tmp;
         end
    end
end

%% noisy segments
 
%settings
if cleanHighNoise
    lambdaA = 6;
    winlen = ceil(0.1*fsample);
    
    %loop over y or x independently
    for iax=1:2
        if iax==1; 
            tmpdeg = xdeg2;
        else
            tmpdeg = ydeg2;
        end

        tmpa = diff(tmpdeg); % change in degrees
        tmpa = movestd(tmpdeg,winlen,[],1);

        selbad = tmpa > aprev;

    %     %combine segments that are too close
    %     [st,fn] = find_borders(selbad);
    %     tooClose = find( (fn(1:end-1) - st(2:end)) <= ceil(fsample*maxNanTime) );
    %     fn(tooClose) = [];
    %     st(tooClose+1) = [];

        unstable = detect_unstable_period(selbad,timeWindow,maxNanTime,fsample);
        disturbance_all(unstable,5) = 1;
    end
end


%% finally, mark whole periods that are sampled too sparsely, for whatever
%reason
tmp_disturbance = sum(disturbance_all(:,1:5),2) > 0;
ignore = disturbance_all(:,3)==3 | disturbance_all(:,5); 
tmp_disturbance(ignore) = 0;
unstablePeriods = detect_unstable_period(tmp_disturbance,timeWindow,maxNanTime,fsample);

disturbance_all(unstablePeriods,6) = 1;

%% prepare output
anyDisturbance = sum(disturbance_all,2) > 0;

xout = x;
yout = y;
xout(anyDisturbance) = nan;
yout(anyDisturbance) = nan;


% results
fprintf('\n\t%g of %g samples with bad validity (%.3g).\n', sum(badValidity), nsmp, sum(badValidity)/nsmp);
fprintf('\t%g of %g samples offscreen (%.3g).\n', sum(offscreen), nsmp, sum(offscreen)/nsmp);
% fprintf('\t%g short periods identified, %g of %g samples (%.3g).\n', ...
%     length(shortDur), sum(disturbance_all(:,3) == 1), nsmp, sum(disturbance_all(:,3) == 1)/nsmp);
% fprintf('\t%g long periods identified, %g of %g samples (%.3g).\n', ...
%     length(longDur), sum(disturbance_all(:,3) == 2), nsmp, sum(disturbance_all(:,3) == 2)/nsmp);
% fprintf('\t%g blinks identified, %g of %g samples (%.3g).\n', ...
%         min(numel(startEst), numel(endEst)), sum(disturbance_all(:,3) == 3), nsmp, sum(disturbance_all(:,3) == 3)/nsmp);
if cleanOneSampleSpike;
    fprintf('\t%g of %g samples (%.3g) samples with one or two sample spikes (%.3g/%.3g sec bad), .\n', ...
        sum(disturbance_all(:,4)), nsmp, sum(disturbance_all(:,4))/nsmp, maxNanTime,timeWindow);
end
if cleanHighNoise
    fprintf('\t%g of %g samples (%.3g) samples with noisy periods (%.3g/%.3g sec bad), .\n', ...
        sum(disturbance_all(:,5)), nsmp, sum(disturbance_all(:,5))/nsmp, maxNanTime,timeWindow);
end
fprintf('\t%g of %g samples (%.3g) samples with over-all unstable periods (%.3g/%.3g sec bad), .\n', ...
    sum(disturbance_all(:,6)), nsmp, sum(disturbance_all(:,6))/nsmp, maxNanTime,timeWindow);
fprintf('\t%g of %g gaze samples have some form of disturbance (%.3g).\n', sum(anyDisturbance), nsmp, sum(anyDisturbance) / nsmp);


%% plot

if plotIndividualDisturbance
    idist = 6;
    sel = logical(disturbance_all(:,idist));
    
    [st,fn] = find_borders(sel);
    pad = 10;
    
    % slect some specific ones we'ev previously flagged
    soi = [9118, 9207]; soi = [soi, [1.4205,1.8355, 2.1, 2.1747,2.1777]*10^4];
    
    iseg = [];
    for is=1:numel(soi)
        iseg(numel(iseg)+1,1) = nearest(st,soi(is));
    end
    st = st(iseg);
    fn = fn(iseg);
    
    for ist=1:numel(st)
        ind = max(1,st(ist)-pad):min(fn(ist)+pad,numel(xout));
        offset = ind(1)-1;
        ind2 = ind - offset;
        tmp1 = [xorig(ind), yorig(ind)];
        tmp2 = [xout(ind), yout(ind)];
        
        tmpd = disturbance_all(ind,:);
        
        figure
        nr = 2; nc=1;
        str = {'xraw','yraw'};
        for ii=1:2
            subplot(nr,nc,ii)
            plot(ind2,tmp1(:,ii),'k')
            hold all
            plot(ind2,tmp1(:,ii),'ko')
            plot(ind2,tmp2(:,ii),'ro')
            title([str{ii}, 'st=' num2str(st(ist))])
            plotcueline('xaxis',[st(ist),fn(ist)] - offset)

        end
        set_bigfig(gcf,[0.7, 0.7])
        pause
        close(gcf)
    end
    
    fred=1;
    
end

if plotFigs
    figure

    time = (t-t(1));
    
    subplot(2,1,1)
    plot(time,xorig)
    hold all
    title('raw X')
    xlabel('time (ms)')
    
    subplot(2,1,2)
    plot(time,yorig)
    hold all
    title('raw Y')
    xlabel('time(ms)')
    
    for n=1:numel(lgnd)
        try
            sel = disturbance_all(:,n)~=0; %==n;

            subplot(2,1,1)
            xx = nan(size(xorig));
            xx(sel) = xorig(sel);

            plot(time,xx,'linewidth',3)

            subplot(2,1,2)
            yy = nan(size(yorig));
            yy(sel) = yorig(sel);

            plot(time,yy,'linewidth',3)
        end
    end
    legend([{'raw'}, lgnd])
end

xxx=1;


%% ------- MISC
function unstablePeriods = detect_unstable_period(selbad,timeWindow,maxBadTime,fsample)

thresh = maxBadTime ./ timeWindow;
pad = floor(fsample*timeWindow/2);

%find unstable periods
selbad = double(selbad);
winlen = ceil(timeWindow*fsample);
if mod(winlen,2)==0; winlen=winlen+1; end
wind = ones(1,winlen);
N = conv(ones(size(selbad)),wind,'same');
bad = conv(selbad,wind,'same');
bad = bad ./ N;

%unstablePeriods = bad >= thresh;
unstablePeriods = false(size(bad));
[stBord,endBord] = find_borders(bad >= thresh);
stBord = stBord - pad;
stBord(stBord<1) = 1;
endBord = endBord + pad;
endBord(endBord>numel(bad)) = numel(bad);

for ist=1:numel(stBord)
    unstablePeriods(stBord(ist):endBord(ist)) = 1;
end

%combine periods that are too close together
ind = find(unstablePeriods);
d = diff(ind);
tooClose = find(d <= pad & d>1 );
addBad = [];
for ic=1:numel(tooClose)
    st = ind(tooClose(ic));
    fn = ind(tooClose(ic)+1);
    addBad = [addBad,st+1:fn-1];
end
unstablePeriods(addBad) = 1;

fred=1;