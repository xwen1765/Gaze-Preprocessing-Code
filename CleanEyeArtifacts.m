function [xout,yout,disturbance] = CleanEyeArtifacts(xorig,yorig,d,V,screenX,screenY,fsample,t)

%extract artifacts according to Larsson et al 2013, IEEE transactions
disp('------------------------------------------------------------')
disp('Extract from eye artifacts...')

%% settings
plotFigs = 0;
cleanOneSampleSpike = 0;

if nargin < 8 && cleanOneSampleSpike
    error('give time variable')
end

Amin = 0.3;
minTinstability = ceil(0.1*fsample);
maxInstabilityInterInterval = ceil(0.1*fsample);

x = xorig;
y = yorig;

lgnd = {'bad est','offscreen','blink', 'one sample spike'};
disturbance_all = cell(numel(lgnd),1);
[disturbance_all{:}] = deal( false(size(V)) );


%% bad estimate
%bad validity
bad = V >= 2;

%long stretch of bad  
if 0
    badDataInd = find(x==-1 & y==-1);
    badDataInterval = diff(badDataInd);
    tooLong = find( [false;badDataInterval > maxInstabilityInterInterval] );
    instability = false(size(bad));

    t2 = t-t(1);
    for n=1:numel(tooLong)-1
        st = badDataInd(1);
        fn = badDataInd( tooLong(1)-1 );
        %[t2(st),t2(fn)]
        if fn-st >= minTinstability
            instability(st:fn) = 1;
        end

        badDataInd(1:tooLong(1)-1) = [];
        tooLong = tooLong - tooLong(1) + 1;
        tooLong(1) = [];
    end
else
    instability = false(size(bad));
end

%figure; plotyy(t2,instability,t2,x)        
disturbance_all{1}(bad | instability) = 1;

%% offscreen
[x2,y2] = acds2screen(x,y,screenX,screenY);
xdeg = degreeVisualAngle(x2,d);
ydeg = degreeVisualAngle(y2,d);
xthresh = degreeVisualAngle(screenX/2,nanmean(d)) + 1.5;
ythresh = degreeVisualAngle(screenY/2,nanmean(d)) + 1.5;

offscreen = abs(xdeg) > xthresh | abs(ydeg) > ythresh;
disturbance_all{2}(offscreen) = 1;


%% blink
maxBlinkSamples = 213; %(700 ms)
minBlinkSamples = 15; %this is the minimum number of samples necessary in order to be considered a blink. 
%should really be in ms, as should everything else in these scripts, but we
%can deal with this for the time being...
%15 samples at 300hz = 50ms, so anything less than 50 ms is not a blink.

blinkest = diff(y == -1);

if any(blinkest)
    startEst = find(blinkest==1);
    endEst = find(blinkest==-1);
    [~,iminy] = findpeaks(1-y);

    %if the start/end of the data has bad data, then we dont have an estimate
    %for the start/end of the blink. blink starts/ends at start/end of recording
    if endEst(1) < startEst(1) 
        %disturbance_all{3}(endEst(1)) = 1;
        startEst = [1;startEst];
    end

    if endEst(end) < startEst(end) 
        %disturbance_all{3}(endEst(end)) = 1;
        endEst = [endEst;numel(blinkest)];
    end
    
    %cut short and long blinks
    dur = endEst - startEst;
    shortDur = find(dur < minBlinkSamples);
    longDur = find (dur > maxBlinkSamples);
    
    for i = 1:length(shortDur)
        disturbance_all{3}(startEst(shortDur(i)):endEst(shortDur(i))) = 2;
    end
    for i = 1:length(longDur)
        disturbance_all{3}(startEst(longDur(i)):endEst(longDur(i))) = 3;
    end
    startEst([shortDur; longDur]) = [];
    endEst([shortDur; longDur]) = [];

    %find minima closest to the etsimated blink start and end times
    for n=1:min(numel(startEst), numel(endEst));
        [~,ist] = min( startEst(n) - iminy( iminy < startEst(n) ) );
        [~,ifn] = min( iminy( iminy > endEst(n) ) - endEst(n) );
        st = iminy(ist);
        fn = iminy( ifn + sum(iminy <= endEst(n)) );
        disturbance_all{3}(st:fn) = 1;
    end
end


%% one sample spike
if cleanOneSampleSpike
    for iax=1:2
        if iax==1 
            tmpdeg = xdeg;
            tmp = x;
        else
            tmpdeg = ydeg;
            tmp = y;
        end

        %thresholds for filter activation
        tmpa = diff(tmpdeg);
        tmpv = diff(tmpdeg) ./ diff(t);

        athresh = abs(tmpa) > Amin;
        athresh = [false;athresh];

        vthresh = diff(abs(tmpv)) > 0;
        vthresh = [false;false;vthresh];

        %loop through all potential OSS
        sel = find( athresh & vthresh );
        for ii=1:numel(sel)
           st = max(1,sel(ii)-1);
           fn = min(numel(tmp),sel(ii)+1);
           
           oss = tmp(st:fn);
           ossd = sign(diff(oss));
           
           if ossd(1)~=ossd(2)
               tmp(ii) = nanmedian(oss);
               
               disturbance_all{4}(st:fn) = 1;
           end
        end

        if iax==1; x = tmp;
        else y = tmp;
        end
    end
end



%% output
N = numel(x);

disturbance = false(size(disturbance_all{1}));
for ii=1:numel(disturbance_all)
    disturbance = disturbance | disturbance_all{ii};
    
    n = sum(disturbance_all{ii});
    p = n./N;
    fprintf('# %s samples: %g of %g, %.3g\n',lgnd{ii},n,N,p);
end
tot = sum(disturbance~=0);
fprintf('total # bad samples: %g of %g, %.3g\n',tot,N,tot/N);

xout = x;
yout = y;
xout(disturbance~=0) = nan;
yout(disturbance~=0) = nan;

%% sanity checks
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
        sel = disturbance_all{n}; %==n;

        subplot(2,1,1)
        xx = nan(size(xorig));
        xx(sel) = xorig(sel);

        plot(time,xx,'linewidth',3)
        
        subplot(2,1,2)
        yy = nan(size(yorig));
        yy(sel) = yorig(sel);

        plot(time,yy,'linewidth',3)
    end
    legend([{'raw'}, lgnd])
end

disp('done')
    
    
    
    
