function [varargout] = ana_extractEyeEvents_Wotan(varargin)
% [SacStructOut, processedGaze] = ana_extractEyeEvents_new(eyeIn,epath,gazeArgs)
% [SacStructOut, processedGaze] = ana_extractEyeEvents_new(...,trialStartIndices)
% [SacStructOut, processedGaze, cfg_gaze] = ana_extractEyeEvents_new(...)


%% settings

%script settings
filtType = 'sg'; %but,sg
interpolate = 1;

timeWindow = 0.04;
%maxNanTime = 0.02;
maxNanTime = timeWindow * 0.25;

    
doUpsample = 0;
resamplefs = 1000;
upsample_method = 'pchip';

doAnimation = 0;
plotFig = 0;
saveProcessedEyetrackerFile = 1;
saveFixationAna = 1;


%inputs
eyeIn_path = varargin{1};
eyeIn = load([eyeIn_path '/GazeData']);
eyeIn = eyeIn.gazeData;
%epath = varargin{2};
epath = [eyeIn_path];
gazeArg = varargin{3};

% figure out which monitor/eyetracker was used
[screenX,screenY,fsample] = get_experiment_parameters(gazeArg);

% should we classify on trials, or whole data?
nsmp = size(eyeIn,1);
mN = 1;
N = nsmp;
% N = floor(nsmp/2);
trialStartIndices = mN:1:N;
trialEndIndices = trialStartIndices(2:end) - 1;
trialEndIndices(end+1) = N;
% if nargin>3
%     offset = ceil(fsample*0.2);
%     trialStartIndices = varargin{4}; %trial start = iti start
%     trialEndIndices = trialStartIndices(2:end) - 1;
%     trialEndIndices(end+1) = nsmp;
% else
%     trialStartIndices = 1;
%     trialEndIndices = nsmp;
% end

%% pre-processing
% Assuming 'gazeData' is the new data structure replacing 'eyeIn'


eyestr = {'left_','right_'};
for ieye=1:2
    eye = eyestr{ieye}; % loops through Left, then loops through Right

	max_length = min(N, length(eyeIn.([eye 'UCS_validity'])));
    % Adjusting for UCS_validity instead of GazePointValidity
	t = eyeIn.device_time_stamp(mN:max_length);
	t = t * 10^-6; % Convert to seconds
	Veye = eyeIn.([eye 'ADCS_validity'])(mN:max_length)';
    eyeZ = eyeIn.([eye 'origin_UCS_z'])(mN:max_length)';
    xorig = eyeIn.([eye 'ADCS_x'])(mN:max_length)';
    yorig = eyeIn.([eye 'ADCS_y'])(mN:max_length)';
    dilat = eyeIn.([eye 'pupil_diameter'])(mN:max_length)';

    % Smooth distance calculation (assuming smoothDistance function can handle vectors directly)
    deye = smoothDistance(eyeZ, fsample, 1);
    dilat(dilat <= 0) = NaN;

    if ieye==1
        fprintf('\n\tLEFT EYE ARTIFACT REMOVAL');
        [xleft, yleft, disturbLeft] = RemoveArtifacts(xorig, yorig, deye, Veye, screenX, screenY, fsample, t, maxNanTime, timeWindow);
        dilat(disturbLeft(:,3) == 3) = NaN;
        dilatLeft = dilat;
        dleft = deye;
    else
        fprintf('\n\tRIGHT EYE ARTIFACT REMOVAL');
        [xright, yright, disturbRight] = RemoveArtifacts(xorig, yorig, deye, Veye, screenX, screenY, fsample, t, maxNanTime, timeWindow);
        dilat(disturbRight(:,3) == 3) = NaN;
        dilatRight = dilat;
        dright = deye;
    end
end

dilatRaw = nanmean([dilatLeft', dilatRight'], 2);

% %loop over both eyes // RIGHT GAZE POINT VALIDITY && LEFT GAZE POINT
% eyestr = {'Left','Right'};
% for ieye=1:2
%     eye = eyestr{ieye};
% 
%     if any(strcmp('RightGazePointValidity',eyeIn.Properties.VariableNames))
%         Veye = eyeIn.([eye 'GazePointValidity']);%%% JUST THIS
%     else
%         Veye = eyeIn.([eye '_ADCS_validity']);
%     end
%     if any(strcmp('RightGazePointInUserCoordinateSystem',eyeIn.Properties.VariableNames))
%         eyeZ = eyeIn.([eye 'RightGazePointInUserCoordinateSystem'])(:,3);
%     else
%         eyeZ = eyeIn.([eye '_origin_UCS_z']);
%     end
% 
%     deye = smoothDistance(eyeZ,fsample,1); 
% 
%     if any(strcmp('right_gaze_origin_in_user_coordinate_system',eyeIn.Properties.VariableNames))
%         xorig = eyeIn.([eye '_gaze_point_on_display_area'])(:,1);
%         yorig = eyeIn.([eye '_gaze_point_on_display_area'])(:,2);
%     else
%         xorig = eyeIn.([eye '_ADCS_x']);
%         yorig = eyeIn.([eye '_ADCS_y']);
%     end
% 
%     dilat = eyeIn.([eye '_pupil_diameter']);
%     dilat (dilat <= 0) = NaN;
%     if ieye==1
%         fprintf('\n\tLEFT EYE ARTIFACT REMOVAL');
%         [xleft,yleft,disturbLeft] = RemoveArtifacts(xorig,yorig,deye,Veye,screenX,screenY,fsample,t,maxNanTime,timeWindow);
%         dilat (disturbLeft(:,3) == 3) = NaN;
%         dilatLeft = dilat;
%         dleft = deye;
%     else
%         fprintf('\n\tRIGHT EYE ARTIFACT REMOVAL');
%         [xright,yright,disturbRight] = RemoveArtifacts(xorig,yorig,deye,Veye,screenX,screenY,fsample,t,maxNanTime,timeWindow);
%         dilat (disturbRight(:,3) == 3) = NaN;
%         dilatRight = dilat;
%         dright = deye;
%     end
% end

% mark periods where the estimation from both eyes is too different
% -BV: this seems to be a problem only in the x-dimension. unknown reason
% as of feb 13 2018

xthresh = 0.1;
disagree = abs(xleft - xright) > xthresh;
xleft(disagree) = nan;
xright(disagree) = nan;
yleft(disagree) = nan;
yright(disagree) = nan;
dleft(disagree) = nan;
dright(disagree) = nan;

%updte the disturbance matrix
disturbLeft = cat(2,disturbLeft,disagree');
disturbRight = cat(2,disturbRight,disagree');

p = sum(disagree) ./ numel(disagree);
fprintf('\n\t Removed %.3g points where left and right eye show >%.3g disagreement',p,xthresh);


%select which eye we want to process
if 1
    xrawMean = nanmean( [xleft;xright], 1);
    yrawMean = nanmean( [yleft;yright], 1);
    d = nanmean([dleft;dright], 1);
    
    %correct for offset where the only one eye was sampled
    % - going to use the same procedure for x, y, and distance
    for ii=1:3
       if ii==1
            tmp = xrawMean;
            tmpl = xleft;
            tmpr = xright;
       elseif ii==2
            tmp = yrawMean;
            tmpl = yleft;
            tmpr = yright;
       else
            tmp = d;
            tmpl = dleft;
            tmpr = dright;
       end
       
       %periods where we onl samepl one eye
       offsetPad = ceil(0.02*fsample);
       tmpout = tmp;
       oneEye = isnan(tmpl) ~= isnan(tmpr);
       [startInd,endInd] = find_borders(oneEye);
       for ist=1:numel(startInd)
            st = startInd(ist);
            fn = endInd(ist);
            begind = max(1,st-offsetPad):st-1;
            endind = fn+1:min(numel(tmp),fn+offsetPad);

            offset = (tmpr - tmpl);
            offset = nanmean( offset([begind,endind]) );

            if any(isnan(tmpr(st:fn)))
                newMu = nanmean([tmpl(st:fn),tmpl(st:fn)+offset],2);
            elseif any(isnan(tmpl(st:fn)))
                newMu = nanmean([tmpr(st:fn),tmpr(st:fn)-offset],2);
            end

            tmpout(st:fn) = newMu;     

           %{
           figure; 
           ind = begind(1):endind(end);
           xx = 1:numel(ind);
           plot(xx,tmpl(ind),'r'); hold all
           plot(xx,tmpr(ind),'g');
           plot(xx,tmp(ind),'b--')
           plot(xx,tmpout(ind),'b')
           %plotcueline('y',targetMu)
           plotcueline('x',[startInd(ist), endInd(ist)] - ind(1)+1);
           legend({'left','right','orig','corr'},'location','eastoutside')
           set(gca,'xlim',[xx(1),xx(end)])
           
           foo=1;
           pause
           close gcf
           %}
       end
       
       %store
       if ii==1
            xrawMean = tmp;
       elseif ii==2
            yrawMean = tmp;
       else
            d = tmp;
       end
    end
else
    %select which eye to use as our estimate
    if sum(isnan(xleft)) < sum(isnan(xright))
        xrawMean = xleft;
        yrawMean = yleft;
        d = smoothDistance(eyeIn.('left_gaze_origin_in_user_coordinate_system')(:,3),fsample,1);
    else
        xrawMean = xright;
        yrawMean = yright;
        d = smoothDistance(eyeIn.('left_gaze_origin_in_user_coordinate_system')(:,3),fsample,1);
    end
end

[xscreen,yscreen] = acds2screen(xrawMean,yrawMean,screenX,screenY);
xdeg = pos2dva(xscreen,d);
ydeg = pos2dva(yscreen,d);

%tmpx = pos2dva(xscreen,ones(numel(xscreen),1)*nanmean(d));

if interpolate
    
    xdegOrig = xdeg;
    ydegOrig = ydeg;
    
    interpType = 'pchip';
    xdeg = interpolate_missingSegments(xdeg,2,interpType);
    ydeg = interpolate_missingSegments(ydeg,2,interpType);
end


% BV: upsample, to 1000 Hz. 
if doUpsample
    fprintf(['\n\tUpsampling to ' num2str(resamplefs)]);

    %interpolate obver new time axis
    t2 = resample_time(t,fsample,resamplefs);
    
    %dont interp over time that have a nan
    ttmp = t2;
    if ~strcmp(filtType,'but') %cuz butworth fails with nans...
        nans = diff(isnan(xdeg));
        [st,fn] = find_borders(nans);

        for ii=1:numel(st)
            toi = [t(st(ii)), t(fn(ii))];
            sel = t2 >toi(1) & t2 < toi(2);

            ttmp(sel) = nan;
        end
        bad = isnan(ttmp);
    else
        bad = false(size(ttmp));
    end
    
    ttmp(bad) = [];

    %interp
    xdeg2 = nan(size(t2));
    ydeg2 = nan(size(t2));
    d2 = nan(size(t2));

    xdeg2(~bad) = interp1(t,xdeg,ttmp,upsample_method);
    ydeg2(~bad) = interp1(t,ydeg,ttmp,upsample_method);
    d2(~bad) = interp1(t,d,ttmp,upsample_method);
else
    resamplefs = fsample;

    t2 = t;
    xdeg2 = xdeg;
    ydeg2 = ydeg;
    d2 = d;
end

%figure; plot(t,xdeg,'.-'); hold all; plot(t2,xdeg2,'.-')

% smooth
% MARCUS NYSTRÖM AND KENNETH HOLMQVIST, Behaviour research methods, 2010
if strcmp(filtType,'sg')
    if 1; %~doUpsample %what Larson recommends
        filt_ord = 2;
        filt_freq = 1/0.02;
    else %what Mack et al 2017 recommends
        filt_ord = 9;
        filt_freq = 1/0.2;
    end
    sg_len = ceil(1/filt_freq*resamplefs);
    

    if 0
        
        if mod(sg_len,2)==0; sg_len = sg_len+1; end
        if filt_ord==sg_len-1;     %filter would produce no smoothing here... so have to add two samples
            warning('**** SG filter length is too small for filter order %g... changing length from %g to %g',filt_ord,sg_len,sg_len+2)
            sg_len = sg_len + 2;
        end
    
        xdeg2 = sgolayfilt(xdeg2,filt_ord,sg_len);
        ydeg2 = sgolayfilt(ydeg2,filt_ord,sg_len);
    else
        N = 2;                 % Order of polynomial fit
        F = 2*ceil(sg_len)-1;    % Window length
        [b,g] = sgolay(N,F);   % Calculate S-G coefficients
        Nf = F;

        xdeg2 = conv(xdeg, g(:,1)', 'same');
        xdeg2(1:(Nf-1)/2) = xdeg(1:(Nf-1)/2);
        xdeg2(end-(Nf-3)/2:end) = xdeg(end-(Nf-3)/2:end);
        ydeg2 = conv(ydeg, g(:,1)', 'same');
        ydeg2(1:(Nf-1)/2) = ydeg(1:(Nf-1)/2);
        ydeg2(end-(Nf-3)/2:end) = ydeg(end-(Nf-3)/2:end);

        Vel(:,1) = conv(xdeg, -g(:,2)', 'same');
        Vel(1:(Nf-1)/2,1) = xdeg(1:(Nf-1)/2);
        Vel(end-(Nf-3)/2:end,1) = xdeg(end-(Nf-3)/2:end);
        Vel(:,2) = conv(ydeg, -g(:,2)', 'same');
        Vel(1:(Nf-1)/2,2) = ydeg(1:(Nf-1)/2);
        Vel(end-(Nf-3)/2:end,2) = ydeg(end-(Nf-3)/2:end);
        Vel = Vel * resamplefs;

        Acc(:,1) = conv(xdeg, -g(:,3)', 'same');
        Acc(1:(Nf-1)/2,1) = xdeg(1:(Nf-1)/2);
        Acc(end-(Nf-3)/2:end,1) = xdeg(end-(Nf-3)/2:end);
        Acc(:,2) = conv(ydeg, -g(:,3)', 'same');
        Acc(1:(Nf-1)/2,2) = ydeg(1:(Nf-1)/2);
        Acc(end-(Nf-3)/2:end,2) = ydeg(end-(Nf-3)/2:end);
        Acc = Acc * resamplefs^2;
    end
    
elseif strcmp(filtType,'but')

    filt_ord = 4;
    %filt_freq = 1/0.05;
    filt_freq = 100;
    fny = filt_freq./(resamplefs/2);
    [b,a] = butter(filt_ord,fny,'low');
    
    mux = nanmean(xdeg2);
    muy = nanmean(ydeg2);
    xdeg2 = filtfilt(b,a,xdeg2-mux);
    ydeg2 = filtfilt(b,a,ydeg2-muy);        
    xdeg2 = xdeg2 + mux;
    ydeg2 = ydeg2 + muy;
    
    %remove the periods that had nans, +/- N/fsample samples
    ttmp = t2;
    nans = diff(isnan(xdeg));
    [st,fn] = find_borders(nans);

    pad = 1/fsample;
    for ii=1:numel(st)
        toi = [t(st(ii))-pad, t(fn(ii))+pad];
        sel = t2 > toi(1) & t2 < toi(2);

        ttmp(sel) = nan;
    end
    bad = isnan(ttmp);
    xdeg2(bad) = nan;
    ydeg2(bad) = nan;
    d2(bad) = nan;
end

%figure; plot(xdeg); hold all; plot(xdeg2)


if 0
    pad = 0.10;
    %toi_all = [434.002716000000,434.022716000000;447.348716000000,447.367716000000;461.309716000000,461.328716000000;497.059716000000,497.077716000000;583.167716000000,583.185716000000;674.205716000000,674.223716000000;963.095716000000,963.114716000000;1105.58471600000,1105.60471600000;1129.08571600000,1129.10571600000;1205.96671600000,1205.98471600000;1230.52171600000,1230.54071600000;1305.34171600000,1305.35671600000;1395.40471600000,1395.42171600000;1570.10771600000,1570.12471600000;1573.98071600000,1573.99771600000;1578.50371600000,1578.52271600000;1581.68471600000,1581.69971600000;1582.64871600000,1582.66871600000;1675.92271600000,1675.94071600000;1748.53871600000,1748.55871600000;1840.93971600000,1840.95971600000;1934.38071600000,1934.39971600000;2123.85071600000,2123.87171600000;2156.79171600000,2156.81171600000;2168.53371600000,2168.55471600000;2185.77871600000,2185.79671600000;2189.19671600000,2189.21471600000;2195.07071600000,2195.08871600000;2195.19571600000,2195.21371600000;2195.37171600000,2195.38971600000;2197.99571600000,2198.01371600000;2199.64671600000,2199.66771600000;2355.00871600000,2355.02871600000;2390.35771600000,2390.37871600000;2402.50571600000,2402.52271600000;2412.08771600000,2412.10871600000;2425.83171600000,2425.85171600000;2425.93771600000,2425.95871600000;2427.84871600000,2427.86671600000;2427.97071600000,2427.98971600000;2428.16171600000,2428.18271600000;2430.81371600000,2430.83371600000;2435.72771600000,2435.74871600000;2446.20871600000,2446.22971600000;2446.39371600000,2446.41171600000;2446.98371600000,2447.00371600000;2468.23871600000,2468.25871600000;2552.48971600000,2552.50971600000;2554.30471600000,2554.32571600000;2554.35971600000,2554.38071600000;2584.50671600000,2584.52371600000;2776.60771600000,2776.62871600000;2822.72171600000,2822.74171600000;2830.06471600000,2830.08271600000;2830.63071600000,2830.65171600000;2831.25671600000,2831.27471600000;2831.52871600000,2831.54771600000;2938.81371600000,2938.83271600000;2986.81371600000,2986.83271600000;3003.41471600000,3003.43171600000;3035.75871600000,3035.77771600000;3063.64071600000,3063.65971600000;3084.31971600000,3084.33871600000;3086.09571600000,3086.11171600000;3093.60171600000,3093.62171600000];
    %toi_all = 1.0e+09 *[1.500477963403414   1.500477964353206];
    %toi_all = 1.0e+09 *[1.497383762722671   1.497383762729322];
    toi_all = 1.0e+09 * [1.498595508407874   1.498595508557902];


    %toi = [2.137430716000000   2.137491716000000] * 1.0e+03;
    for itoi = 1:size(toi_all,1)
        toi = toi_all(itoi,:);
        toi2 = toi + [-pad,pad];
        sel1 = find(t>=toi2(1) & t<=toi2(2))'; 
        sel2 = find(t2>=toi2(1) & t2<=toi2(2))';
%         figure
%         subplot(2,1,1); plot(t(sel1),xdeg(sel1),'*-'); hold all; plot(t2(sel2),xdeg2(sel2),'.-'); plotcueline('xaxis',toi)
%         subplot(2,1,2); plot(t(sel1),ydeg(sel1),'*-'); hold all; plot(t2(sel2),ydeg2(sel2),'.-'); plotcueline('xaxis',toi)
%         set_bigfig(gcf,[0.5,0.5])
        tt = {t(sel1)-t(sel1(1)),t2(sel2)-t2(sel2(1))};
        xx = {xdeg(sel1),xdeg2(sel2)};
        yy = {ydeg(sel1),ydeg2(sel2)};
        plot_gaze_trace(tt,xx,yy,toi-t(sel1(1)))
        %pause
        %close(gcf)
    end
    
end

%check dimension
if ~iscolumn(xdeg2); xdeg2 = xdeg2'; end
if ~iscolumn(ydeg2); ydeg2 = ydeg2'; end
if ~iscolumn(t2); t2 = t2'; end
if ~iscolumn(d2); d2 = d2'; end

%% extract saccade, PSO, fixations, smooth pursuits

trlInd = [trialStartIndices,trialEndIndices];
EyeData = [xdeg2,ydeg2,t2];
% SacStructOut = HcTask_SaccadeProcessing_mg3(EyeData,resamplefs,0,0,trlInd);
%SacStructOut = HcTask_SaccadeProcessing_mg3(EyeData,resamplefs,0,0,trlInd,Vel,Acc);
SacStructOut = HcTask_SaccadeProcessing_mg4(EyeData,resamplefs,0,0,trlInd,Vel,Acc);
%SacStructOut = HcTask_SaccadeProcessing_mg5(EyeData,resamplefs,0,0,trlInd,Vel,Acc);

%% prepare for final output

%classificaitons
classification = nan(size(SacStructOut.Saccade));
classification(SacStructOut.Saccade) = 1;
classification(SacStructOut.PSO) = 2;
classification(SacStructOut.Fixation) = 3;
classification(SacStructOut.SmoothPursuit) = 3; %4
classification(SacStructOut.Unclassified) = 5;

%update with dilation data
% BV: WARNING: apend_dilation_data script not finished, throwing errors
if 0
SacStructOut.Saccade = append_dilation_data(dilatRaw,classification==1,fsample,SacStructOut.Saccade);
SacStructOut.PSO = append_dilation_data(dilatRaw,classification==2,fsample,SacStructOut.PSO);
SacStructOut.Fixation = append_dilation_data(dilatRaw,classification==3,fsample,SacStructOut.Fixation);
SacStructOut.SmoothPursuit = append_dilation_data(dilatRaw,classification==4,fsample,SacStructOut.SmoothPursuit);
end

%figure out what flanked each event

%average x,y, convert back to unity units
%allbad = badleft & badright;
xout = xrawMean;
yout = yrawMean;
%xout(allbad) = nan;
%yout(allbad) = nan;

xtmp = dva2pos(circ_ang2rad(xdeg2),d2);
ytmp = dva2pos(circ_ang2rad(ydeg2),d2);

[xoutSmooth,youtSmooth] = screen2acds(xtmp,ytmp,screenX,screenY);
%figure; plot(xoutSmooth); hold all; plot(xraw)


%upsample the other data, just nearest neighbor interp for these guys
deviceTimeStamp = eyeIn.device_time_stamp(mN:max_length);
systemTimeStamp = eyeIn.system_time_stamp(mN:max_length);
if doUpsample
    
    method = 'nearest';
    deviceTimeStamp = interp1(t,deviceTimeStamp,t2,method);
    systemTimeStamp = interp1(t,systemTimeStamp,t2,method);
    xout = interp1(t,xout,t2,method);
    yout = interp1(t,yout,t2,method);
    dilatRaw = interp1(t,dilatRaw,t2,method);
    disturbLeft = interp1(t,disturbLeft,t2,method);
    disturbRight = interp1(t,disturbRight,t2,method);

end


%average fixation
fix = SacStructOut.Fixation==1;
st = find(diff(fix)==1)+1;
fn = find(diff(fix)==-1);

if fn(1) < st(1); st = [1;st]; end
if fn(end) < st(end); fn = [fn;numel(fix)]; end
%figure; plot(fix); hold all; plot(st,fix(st),'r*'); plot(fn,fix(fn),'b*')

fixx = nan(size(fix));
fixy = nan(size(fix));
for ff=1:numel(st)
    fixx(st(ff):fn(ff)) = nanmean(xout(st(ff):fn(ff)));
    fixy(st(ff):fn(ff)) = nanmean(yout(st(ff):fn(ff)));
end


%store

processedGaze = table(deviceTimeStamp, systemTimeStamp, t2, xout', yout',...
    xoutSmooth, youtSmooth, fixx, fixy, classification, dilatRaw, disturbLeft, disturbRight, d2,...
    'VariableNames', ...
    {'EyetrackerTimestamp', 'SystemTimestamp', 'ProcessedTime','XMean', 'YMean',...
    'XSmooth', 'YSmooth', 'XFix', 'YFix', 'Classification', 'Dilation', 'LeftDisturbance', 'RightDisturbance','Distance'});

bothEyeDisturb = sum(disturbLeft,2) > 0 & sum(disturbRight,2) >0;

fprintf('\n\t%g invalid, missing, or artifactual gaze samples (%.3g).\n', sum(bothEyeDisturb), sum(bothEyeDisturb) / length(xout));

%% compile final config file
cfg_gaze = [];
cfg_gaze.fsample = fsample;
cfg_gaze.resamplefs = resamplefs;
cfg_gaze.doUpsample = doUpsample;
cfg_gaze.filt_type = filtType;
if doUpsample; cfg_gaze.upsample_method = upsample_method; end
if ~isempty(filtType); 
    cfg_gaze.filt_ord = filt_ord; 
    try,cfg_gaze.filt_freq = filt_freq; end
end
cfg_gaze.interpolate = interpolate;

%% set output
varargout{1} = SacStructOut;
varargout{2} = processedGaze;
if nargout>2; varargout{3} = cfg_gaze; end

    %% save file for replayer
if saveProcessedEyetrackerFile
    
    
    savepath = epath;
    if ~exist(savepath); mkdir(savepath); end
	filepath = fullfile(savepath,'/processedGaze.mat');
	save(filepath, 'processedGaze');

    %split up into trials, add soem columns
%     for id=1:numel(dd)
%         savename = [savepath '/' dd(id).name(1:end-4) '_procFix.csv'];
%         disp([num2str(id) ': saving ' savename])
% 
%         trlsel = trialStartIndices(id):trialEndIndices(id);
%         
%         tmpOut = eyeIn(trlsel,:);
%         tmpOut.meanX = xout(trlsel);
%         tmpOut.meanY = yout(trlsel);
%         tmpOut.smoothX = xoutSmooth(trlsel);
%         tmpOut.smoothY = youtSmooth(trlsel);
%         tmpOut.classification = classification(trlsel);
%         tmpOut.averageFixX = fixx(trlsel);
%         tmpOut.averageFixY = fixy(trlsel);
% 
%         %save
%         writetable(tmpOut,savename,'Delimiter','\t')
%     end
end

%% save data for analysis
if 0%saveFixationAna
    savepath = [epath '/ana_fix'];
    if ~exist(savepath); mkdir(savepath); end
end

%% animation
if 0
    itrl = 2;
    if exist('trialStartIndices') 
        trlsel = trialStartIndices(itrl):trialEndIndices(itrl);
    else
        trlsel = 1:1000;
    end
    
    classification = zeros(size(SacStructOut.Saccade));
    classification(SacStructOut.Fixation) = 1;
    classification(SacStructOut.SmoothPursuit) = 2;
    classification(SacStructOut.Saccade) = 3;
    classification(SacStructOut.PSO) = 4;
    classification = classification(trlsel);
    
    xx = xscreen(trlsel);
    yy = yscreen(trlsel);
    time = EyeData(trlsel,3);
    time = time - time(1);
    
    animate_gaze(xx,yy,time,classification,1)
end

%% plot everything
if doAnimation
    figure
    hax = [];
    
    itrl = 1;
    trlsel = 1:4000; %trialStartIndices(itrl):trialEndIndices(itrl);
    x = EyeData(trlsel,1);
    y = EyeData(trlsel,2);
    time = EyeData(trlsel,3) - EyeData(1,3);
    vel = [0; abs(complex(diff(x),diff(y))) ./ diff(time)];
    unc = SacStructOut.Unclassified(trlsel);
    
    
    events = {'Saccade','PSO','Fixation','SmoothPursuit'};
    cols = 'gmrb';
    lgnd = ['raw',events,'unclassified'];
    
    subplot(3,1,1)
    plot(time,vel,'k-')
    hold all
    for n=1:numel(events)
        sel = SacStructOut.(events{n})(trlsel);
        vel2 = nan(size(vel));
        vel2(sel) = vel(sel);
        plot(time,vel2,[cols(n) '-'],'markersize',2)
    end
    uu = ones(1,numel(unc)) * max(vel)*1.1;
    plot(time(unc),uu(unc),'ko','markersize',3)
    title(['velocity, points ' mat2str([trlsel(1), trlsel(end)])])
    ylabel('vel (deg/s)')
    
    subplot(3,1,2)
    plot(time,x,'k-')
    hold all
    for n=1:numel(events)
        sel = SacStructOut.(events{n})(trlsel);
        plot(time(sel),x(sel),[cols(n) 'o'],'markersize',5)
    end
    uu = ones(1,numel(unc)) * max(x)*1.1;
    plot(time(unc),uu(unc),'ko','markersize',3)
    title('xpos')
    ylabel('xpos (deg)')
    
    h = [];
    subplot(3,1,3)
    h(1) = plot(time,y,'k-');
    hold all
    for n=1:numel(events)
        sel = SacStructOut.(events{n})(trlsel);
        h(n+1) = plot(time(sel),y(sel),[cols(n) 'o'],'markersize',5);
    end
    uu = ones(1,numel(unc)) * max(y)*1.1;
    h(end+1) = plot(time(unc),uu(unc),'ko','markersize',3);
    title('ypos')
    ylabel('ypos (deg)')
    
    legend(h,lgnd)
    
    set_bigfig(gcf,[0.8,0.8])
end

xxx=1;


