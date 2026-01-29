function [SacStructOut] = HcTask_SaccadeProcessing_mg4(eyeData, fsample, doPlot,PreSmoothed,trialIndices,Vel,Acc)
%A structure with the eye-position data is input, and a structure with all of
%the saccades extracted is output. 
%
%to plot the example, go to calcEndPoints.m, and change p to 1
%
% SacStructInput = [xdegrees,ydegrees,time]

%checks
if nargin < 3
    doPlot = 0;
end
if nargin < 4
    PreSmoothed = 0;
end
if nargin <5
    trialIndices = [1,size(eyeData,1)];
end
if nargin > 5 && ~isempty(Vel) && ~isempty(Acc)
    calcVelAcc = 0;
else
    calcVelAcc = 1;
end

ignorePSO = fsample~=120;

fprintf('\n\n\tCLASSIFYING GAZE DATA\n')

saccade =  zeros(length(eyeData),1);
pso = zeros(length(eyeData),1);
fixation = zeros(length(eyeData),1);
smoothPursuit = zeros(length(eyeData),1);

%number of samples to exceed to count as a saccade (10ms)
%durationThresh = 4;
lambdaAcc = 6; %paper and ben used 6
tMinInterSac = ceil(0.02*fsample); % Ben used 20points at 500 Hz??? ie 40ms
durationThresh = ceil(0.01*fsample); %Ben used 4 poins at 500 Hz==8ms ms, paper said 6 ms
sacPadEnd = max(8,ceil(0.03*fsample)); %i think hes padding saccades to calculate PSOs?
%sacPadStart = ceil(0.006*fsample); 
sacPadStart = max(8,ceil(0.03*fsample)); %cant have only 1-2 samples, calcEndpoint tends to fail


%the window for smoothing
% if 0 && fsample<250; wind = 10*[ -1 -1 0 1 1];
% else wind = 20*[-1 -1 -1 -1 0 1 1 1 1];
% end

%wind = 20*[-1 -1 -1 -1 0 1 1 1 1];
wind = (fsample/6)*[-1 -1 0 1 1]; %Engbert et al 2006, 2003
%wind = (fsample/10)*[-1 -1 -1 -1 0 1 1 1 1];
%wind = 1/(10/fsample) * [-1 -1 -1 -1 0 1 1 1 1];
%wind = [-1 0 1]/2;

wind = fliplr(wind); %prepare for convolution

%Tsac keeps track of the total saccades
Tsac = 0;
saccadesExist = 1;
EyeDataCopy = eyeData;

t = eyeData(:,3);

% % %added dilation data, so delete it here to work with the rest of the script
% % if size(eyeData,2)==4
% %     dil = eyeData(:,4);
% %     eyeData(:,4) = [];
% % else
% %     dil = nan(size(eyeData(:,4)));
% % end


while saccadesExist ==1
    %% Calculate the velocity Threshold
    %the position has already been smoothed, so just calculate the velocity
    %by the difference of the two vectors
    
    %Calculate the Velocity and the Acceleration for the trial
    if calcVelAcc
        if PreSmoothed
            Vel = [0 0; diff(eyeData(:,1:2))] ./...
                [0 0; diff(eyeData (:,3)), diff(eyeData(:,3)) ];
        else
            %Vel = abs( [conv(eyeData(:,1),wind,'same'),conv(eyeData(:,2),wind,'same')] );
            Vel = [conv(eyeData(:,1),wind,'same'),conv(eyeData(:,2),wind,'same')];
        end
        Acc = abs([conv(Vel(:,1),wind,'same'),conv(Vel(:,2),wind,'same')]);
        %Acc = [conv(Vel(:,1),wind,'same'),conv(Vel(:,2),wind,'same')];
    end
   
    fprintf('\n\tSaccade Detection...')

    %Calculate the threshold iteratively, taken from Larsson, L., Nystrom,
    %     M., & Stridh, M. (2013). Detection of saccades and postsaccadic
    %     oscillations in the presence of smooth pursuit. IEEE Transactions on
    %     Biomedical Engineering, 60(9), 2484?2493.
    %     http://doi.org/10.1109/TBME.2013.2258918
    
    %make sure we take absolute
    %Acc = abs(Acc);
    %Vel = abs(Vel);
    
%     %calculate both acceleration and velocity threshold
%     AccThresh = nan(size(eyeData,1),2);
%     VelThresh = AccThresh;
%     for it=1:size(trialIndices,1)
%         st = trialIndices(it,1);
%         fn = trialIndices(it,2);
%         
%         for ii=1:2
%             %acceleration threshold
%             tmpa = abs(Acc(st:fn,ii));
%             AccThresh(st:fn,ii) = iterativeThreshold(tmpa,10000,1,lambdaAcc);
%             
%             %velocity
%             tmpv = Vel(st:fn,ii);
%             VelThresh(st:fn,ii) = iterativeThreshold(tmpv,1000,1,lambdaAcc);
%         end
%     end
%     isSac = abs(Vel) > VelThresh;    
%     isSac = any(isSac,2); %combine estimation for x and y

%     v = abs(complex(Vel(:,1),Vel(:,2)));
%     VelThresh = nan(size(eyeData,1),1);
%     for it=1:size(trialIndices,1)
%         st = trialIndices(it,1);
%         fn = trialIndices(it,2);
%         tmpv = v(st:fn);
%         th = iterativeThreshold(tmpv,1000,1,lambdaAcc);
%         VelThresh(st:fn) = min(th,100);
%     end
%     isSac = v > VelThresh;
% 
%     %estimated saccade start and end
%     if ~any(isSac); continue; end
%     [SacStart,SacEnd] = find_borders(isSac);

    if 1
        % get angular accelration
        v = abs(complex(Vel(:,1),Vel(:,2)));
        a = conv(v,wind,'same');

        %using gaussian
%         AccThresh = nan(size(eyeData,1),2);
%         for it=1:size(trialIndices,1)
%             disp(it)
%             st = trialIndices(it,1);
%             fn = trialIndices(it,2);
%             tmpa = a(st:fn); 
% 
%             th = iterativeThreshold_gaussEstimation(tmpa,max(abs(tmpa)),1,0.0001);
%             AccThresh(st:fn,1:2) = [th,-th];
%         end
        
        AccThresh = nan(size(eyeData,1),2);
		%% Edit: change min indices checking 
		trialIndices = trialIndices';
		minIndices = min(trialIndices) - 1;
% 		for it=1:size(trialIndices, 1)
        for it=1:length(trialIndices)-1
            %disp(it)
            st = trialIndices(it) - minIndices;
            fn = trialIndices(it+1) - minIndices;
            tmpa = a(st:fn); 

            th = iterativeThreshold(tmpa,[],1,lambdaAcc,[],1);
            AccThresh(st:fn,1) = th;
            AccThresh(st:fn,2) = -th;
        end

        %look for increases and decreases in acceleration as the offset and
        %onsets
        ainc = a > AccThresh(:,1);
        adec = a < AccThresh(:,2);
        
        % estimated start and end are moments of peak acceleration
        startEst = [];
        endEst = [];
        [st,fn] = find_borders(ainc);
        for ii=1:numel(st)
            [~,startEst(ii)] = max(a(st(ii):fn(ii)));
            startEst(ii) = startEst(ii)  + st(ii) - 1;
        end
        [st,fn] = find_borders(adec);
        for ii=1:numel(st)
            [~,endEst(ii)] = min(a(st(ii):fn(ii)));
            endEst(ii) = endEst(ii)  + st(ii) - 1;
        end


        %now match
        SacStart = [];
        SacEnd = [];
        ii = 0;
        for isac=1:numel(startEst)
           st = startEst(isac);
           fn = endEst( find(endEst>st,1) );

           %makre sure that the proposed end is before another proposed start
           if ~isempty(fn) && (isac==numel(startEst) || fn < startEst(isac+1))
               ii = ii+1;
               SacStart(ii,1) = st;
               SacEnd(ii,1) = fn;
           end
        end

    end
    

    

    % delete saccades at edges
    if SacStart(1)==1
        SacStart(1) = [];
        SacEnd(1) = [];
    end
    if SacEnd(end)==size(eyeData,1)
        SacStart(end) = [];
        SacEnd(end) = [];
    end
    
    %combine saccades that are too close together
    d1 = diff([SacEnd(1:end-1), SacStart(2:end)],[],2);
    tooClose = find(d1 < tMinInterSac);
    SacStart(tooClose+1) = [];
    SacEnd(tooClose) = [];
    if isempty(SacStart) || isempty(SacEnd); continue; end
    
    %delete Saccades that are too short
    d2 = diff([SacStart, SacEnd],[],2);
    tooShort = find( d2 <= durationThresh );
    SacStart(tooShort) = [];
    SacEnd(tooShort) = [];
    if isempty(SacStart) || isempty(SacEnd); continue; end   
    
    %add padding to feed into calcEndpoints
    SacStart = SacStart - sacPadStart;
    SacEnd = SacEnd + sacPadEnd;
        
    
     %check what we found
    if 0
        for is=1:size(SacStart,1)
            ind=SacStart(is):SacEnd(is);
            toi = []; %[t(ind(1)), t(ind(end))];
            hax = plot_gaze_derivatives(t(ind)-t(ind(1)),eyeData(ind,1:2),abs(Vel(ind,:)),abs(Acc(ind,:)),toi-t(ind(1)),{'x','y'});
            for ii=1:2
                plotcueline(hax(2,ii),'y',VelThresh(ind(2),ii));
                plotcueline(hax(3,ii),'y',AccThresh(ind(2),ii));
            end
            set_bigfig(gcf,[0.7 0.7])
            pause
            close gcf
        end
    end
    
    %double check that we didnt accidently overlow
    if SacStart(1)<1
        SacStart(1) = [];
        SacEnd(1) = [];
    end
    if SacEnd(end)>size(eyeData,1)
        SacStart(end) = [];
        SacEnd(end) = [];
    end
    
    fred=1;
    
    %dont conisder any saccades that have nans
    bad = false(size(SacStart));
  
    for is=1:numel(bad)
        if any( sum(isnan( eyeData(SacStart(is):SacEnd(is),1:3) )) )
            bad(is) = 1;
        end
    end
    SacStart(bad) = [];
    SacEnd(bad) = [];
    

    %check some strange periods
%     1.497383342128957   1.497383342412245
%    1.497383423219547   1.497383423329533
%    1.497383432414669   1.497383432764713
%    1.497383464939551   1.497383465086199

    flag = 0;

    toi_all=1.0e+09 * [     1.498592426092918   1.498592426109479
                       1.498592491825848   1.498592491842406
                       1.498592505610233   1.498592505627012
                       1.498592552169504   1.498592552186287
                       1.498592555345788   1.498592555362334
                       1.498592556465604   1.498592556485593];
   
    for ii=1:size(toi_all,1)
        toi=toi_all(ii,:);
        %toi = 1.0e+09 * [1.498592685341752   1.498592685431825];
        %toi = 1.0e+09 * [1.498592685385162   1.498592685471678];
        pad = 0.2;
        itoi = [nearestCustom(t,toi(1) - pad), nearestCustom(t,toi(2) + pad)];

        %flag = any(t>toi(1) & t< toi(2));
        if flag
            %recalculate accelerationa and velcoity
            %Calculate the Velocity and the Acceleration for the trial
            if 0
                v = [0 0; diff(eyeData(:,1:2))] ./...
                        [0 0; diff(eyeData (:,3)), diff(eyeData(:,3)) ];
                v2 = [conv(eyeData(:,1),wind,'same'),conv(eyeData(:,2),wind,'same')];
                    %Vel2 = [conv(eyeData(:,1),wind,'same'),conv(eyeData(:,2),wind,'same')];
                a = abs( [0 0; diff(v(:,1:2))] ./ [0 0; diff(eyeData(:,3)), diff(eyeData(:,3)) ] );
                a2 = abs([conv(v2(:,1),wind,'same'),conv(v2(:,2),wind,'same')]);
            else
                v = abs(Vel);
                v2 = abs(Vel);
                a = Acc;
                a2 = Acc;
            end

            ind = itoi(1):itoi(2);
            figure; nr = 3; nc = 2; mk = 10; arg = {'.-','markersize',mk}; strs = {'x','y'};
            ipk = find(t >= toi(1), 1);
            for ii=1:2
                tt = t(ind) - t(ind(1));
                ns = ii;
                subplot(nr,nc,ns); 
                plot(tt,a(ind,ii),arg{:}); hold all; plot(tt,a2(ind,ii),arg{:});  title('acc')
                %plotcueline('yaxis',PeakThresh(ii))
                %plotcueline('yaxis',AccThresh(ipk,ii))
                legend({'num diff','diff smooth'});

                subplot(nr,nc,ns+nc); 
                plot(tt,v(ind,ii),arg{:}); hold all; plot(tt,v2(ind,ii),arg{:}); title('v')
                %plotcueline('yaxis',VelThresh(ipk,ii))
                subplot(nr,nc,ns+2*nc); plot(tt,eyeData(ind,ii),arg{:}); title(strs{ii})
                plotcueline([],'xaxis',toi-t(ind(1)))
            end
        end
        
        foo=1;
    end
    
    
  
    

    %% initialize variables
    StartPoint = NaN(length(SacStart),1);
    EndPoint = NaN(length(SacStart),1);
    Peak = NaN(length(SacStart),1);
    PeakTime =  NaN(length(SacStart),1);

    plotFlag = 0;
    for stamp = 1:length(SacStart);
        [StartPoint(stamp),EndPoint(stamp),Peak(stamp),PeakTime(stamp)] = ...
            calcEndPoints_mg( eyeData(SacStart(stamp):SacEnd(stamp),:), fsample, plotFlag, sacPadStart, sacPadEnd );
    end
    
    %remove some of the saccades if (1) nans, or (2) overlap > min
    %inter-sac interval
    % - dont want to remove saccades if one of them is bad anyways
    toremove = (isnan(StartPoint)|isnan(EndPoint)|isnan(Peak));
    d = (StartPoint(2:end) - EndPoint(1:end-1)) * fsample;
    overlap = find( d < tMinInterSac & ~toremove(1:end-1) & ~toremove(2:end));
    toremove(overlap) = 1;
    toremove(overlap+1) = 1;
    
    RemovedStart = StartPoint(toremove);
    RemovedEndPoint = EndPoint(toremove);
    StartPoint(toremove) = [];
    EndPoint(toremove) = [];
    Peak(toremove) = [];
    PeakTime(toremove) = [];
    
    
    %saccade charcterisization
    %the cells to hold the processed data before putting it into the array
    nsac = numel(StartPoint);
    TotalStartTime = NaN(nsac,1);
    TotalEndTime = NaN(nsac,1);
    TotalPeakTime = NaN(nsac,1);
    TotalPeakVelocity = NaN(nsac,1);
    StartPointX  = NaN(nsac,1);
    StartPointY = NaN(nsac,1);
    EndPointX  = NaN(nsac,1);
    EndPointY  = NaN(nsac,1);
    Amplitude  = NaN(nsac,1);
    Duration  = NaN(nsac,1);
    Direction  = NaN(nsac,1);
    PSOEndTotal = NaN(nsac,1);

    for sac = 1:length(StartPoint)
        %print percentage of processing
        TotalStartTime(sac) = StartPoint(sac);
        TotalEndTime(sac) = EndPoint(sac);
        TotalPeakTime(sac) = PeakTime(sac);
        TotalPeakVelocity(sac) = Peak(sac);
        StartPointX(sac) = eyeData(eyeData(:,3)==StartPoint(sac),1);
        StartPointY(sac) = eyeData(eyeData(:,3)==StartPoint(sac),2);
        EndPointX(sac) = eyeData(eyeData(:,3)==EndPoint(sac),1);
        EndPointY(sac) = eyeData(eyeData(:,3)==EndPoint(sac),2);
        Amplitude(sac) = sqrt((StartPointX(sac)-EndPointX(sac)).^2 + ...
            (StartPointY(sac)-EndPointY(sac)).^2);
        Duration(sac) = EndPoint(sac)-StartPoint(sac);
        Direction(sac) = atan2d((EndPointY(sac)-StartPointY(sac)),...
            (EndPointX(sac)-StartPointX(sac)));
        
        %store
        %define points where the signal is a saccade
        saccade(eyeData(:,3)>=StartPoint(sac)&eyeData(:,3)<=EndPoint(sac)) = 1;

        
    end
    
    
    %% Cycle through Saccades
    if ignorePSO
        reverseStr = '';
        PSOEndTotal = NaN(length(StartPoint),1);
        for sac = 1:length(StartPoint)
            %print percentage of processing
            percentDone = 100 * sac / length(StartPoint);
            msg = sprintf('\tFinding PSOs, %3.1f percent finished.', percentDone); 
            fprintf([reverseStr, msg]);
            reverseStr = repmat(sprintf('\b'), 1, length(msg));

            %test for PSO's
            %CheckX
            % if the saccade is the last saccade, see if you need to use the
            % end of the trial as then end of this calculation
            pso_offset = ceil(38/500*fsample); % what Ben used at 500hz rate
            if sac+1>length(StartPoint)
                calcLength = min(find(eyeData(:,3)==EndPoint(sac))+pso_offset,length(eyeData));
            else
                calcLength = min([find(eyeData(:,3)==EndPoint(sac))+pso_offset,...
                    find(eyeData(:,3)==StartPoint(sac+1))-1]);
            end

            min_offset = ceil(10/500*fsample);
            if calcLength >min_offset && [calcLength - find(eyeData(:,3)==EndPoint(sac))]>min_offset
                PPSOX = eyeData(find(eyeData(:,3)==EndPoint(sac)):...
                    calcLength,1:2:3);

                [PSOEndX,Rend] = PSOCalc_mg(PPSOX,fsample);
                %CheckY
                PPSOY = eyeData(find(eyeData(:,3)==EndPoint(sac)):...
                    calcLength,2:3);

                [PSOEndY, REnd] = PSOCalc_mg(PPSOY,fsample);
                PSOEndTotal(sac) = max(PSOEndX,PSOEndY);

                %define points where the signal is a PSO. add some time to makesure
                % saccade end isnt included in the PSO
                pso(eyeData(:,3)>=(EndPoint(sac)+1/fsample*0.5)&eyeData(:,3)<=PSOEndTotal(sac)) = 1;
            end
        end
    else
        pso = false(size(saccade));
    end


    % nan all the defined points so that only the foveations are left
    % for further processing
    eyeData(saccade | pso,1:2) = NaN;

    saccadesExist = 2;
end
fprintf('\n');
TotalStartTime(isnan(TotalStartTime)) = [];
TotalEndTime(isnan(TotalEndTime)) = [];
TotalPeakTime(isnan(TotalPeakTime)) = [];
TotalPeakVelocity(isnan(TotalPeakVelocity)) = [];
StartPointX(isnan(StartPointX)) = [];
StartPointY(isnan(StartPointY)) = [];
EndPointX(isnan(EndPointX)) = [];
EndPointY(isnan(EndPointY)) = [];
Amplitude(isnan(Amplitude)) = [];
Duration(isnan(Duration)) = [];
Direction(isnan(Direction)) = [];
PSOEndTotal(isnan(PSOEndTotal)) = [];
StartGazeRow = find(ismember(eyeData(:,3),TotalStartTime));
EndGazeRow = find(ismember(eyeData(:,3),TotalEndTime));

%store saccade info
saccadeInfo = struct('StartTime',TotalStartTime,'EndTime',TotalEndTime,...
    'StartGazeRow',StartGazeRow,'EndGazeRow',EndGazeRow,...
    'PeakTime',TotalPeakTime,'PeakVelocity',TotalPeakVelocity,'Duration',...
    Duration,'Amplitude',Amplitude,'StartPointX',StartPointX,'EndPointX',...
    EndPointX,'StartPointY',StartPointY,'EndPointY',EndPointY,...
    'Direction',Direction,'PostSaccadicOscillationEnd',PSOEndTotal);


%classify fixations
fixClassifications = FixVsSPAnalysis_mg(eyeData,fsample,Vel);

% %add dilation data in here
% if size(eyeData,2)==3
%     eyeData = cat(2,eyeData,dil);
% end
    
fixation(fixClassifications==1) = 1;
smoothPursuit(fixClassifications==2) = 1;
fixInfo = get_fixation_smoothPursuit_info(eyeData,fixation==1, fsample);
smInfo = get_fixation_smoothPursuit_info(eyeData,smoothPursuit==1,fsample);
% unclassified = isnan(EyeDataCopy(:,1));
unclassified = ~(smoothPursuit | fixation| pso | saccade);

% d1 = [fixInfo.EndTime] - [fixInfo.StartTime];
% d2 = [smInfo.EndTime] - [smInfo.StartTime];
% figure; 
% subplot(1,2,1); hist(d1,100)
% subplot(1,2,2); hist(d2,100)

fprintf('\n\t%g saccades identified, %g gaze samples in total (%.3g).', length(saccadeInfo.StartTime), sum(saccade), sum(saccade)/length(EyeDataCopy));
fprintf('\n\t%g PSO gaze samples (%.3g).', sum(pso), sum(pso)/length(EyeDataCopy));
fprintf('\n\t%g fixations identified, %g gaze samples in total (%.3g).', length(fixInfo.StartTime), sum(fixation), sum(fixation)/length(EyeDataCopy));
fprintf('\n\t%g smooth pursuits identified, %g gaze samples in total (%.3g).', length(smInfo.StartTime), sum(smoothPursuit), sum(smoothPursuit)/length(EyeDataCopy));
fprintf('\n\t%g unclassifiable gaze samples (%.3g).', sum(unclassified), sum(unclassified)/length(EyeDataCopy));

%% Output
SacStructOut = struct('SaccadeInfo',saccadeInfo,...
    'FixationInfo',fixInfo,'SmoothPursuitInfo',smInfo,...
    'Saccade',logical(saccade),'PSO',logical(pso),...
    'Fixation',logical(fixation),'SmoothPursuit',logical(smoothPursuit),...
    'Unclassified',logical(unclassified),...
    'Time',t,'TrialIndices',trialIndices);

%% figures
if doPlot
    
    EyeDataCopy(:,3) = EyeDataCopy(:,3) - EyeDataCopy(1,3);
    
    figure('Position',[0,400,1600,800])
    subplot(2,1,1)
    hold on
    bigdata = [EyeDataCopy(saccade,3),EyeDataCopy(saccade,1),ones(length(EyeDataCopy(saccade)),1);...
        EyeDataCopy(pso,3),EyeDataCopy(pso,1),ones(length(EyeDataCopy(pso)),1).*4;...
        EyeDataCopy(fixation,3),EyeDataCopy(fixation,1),ones(length(EyeDataCopy(fixation,1)),1).*2;...
        EyeDataCopy(smoothPursuit,3),EyeDataCopy(smoothPursuit,1),ones(length(EyeDataCopy(smoothPursuit)),1).*3;...
            ];
    gscatter(bigdata(:,1),bigdata(:,2),bigdata(:,3),'grbm','oooo',[5,5,5,5])
    plot(EyeDataCopy(:,3),EyeDataCopy(:,1),'k','LineWidth',1)
    hold all
    
    y = (max(EyeDataCopy(:,1)) + 5) * ones(size(EyeDataCopy(:,3)));
    y(~unclassified) = nan;
    plot(EyeDataCopy(:,3),y,'ko','markersize',5)
    
    %    
    legend({'Saccade','Fixation', 'Smooth Pusuit','Post-saccadic Osscilation'    })
    ylabel('Degrees visual angle X')
    bigfig = gca;
    trialLength = EyeDataCopy(end)-EyeDataCopy(1,3);
    quarters = round(length(EyeDataCopy(:,3))/4);
%     bigfig.XTick = [EyeDataCopy(1,3) EyeDataCopy(quarters,3) ...
%         EyeDataCopy((2*quarters),3) EyeDataCopy(3*quarters,3) EyeDataCopy(end,3)];
%     bigfig.XTickLabel= {'0', num2str(length(EyeDataCopy(:,1))/2) num2str(length(EyeDataCopy(:,1))) ...
%         num2str(length(EyeDataCopy(:,1))*1.5) num2str(length(EyeDataCopy(:,1))*2)};
    %bigfig.YLim = [-20 20];
    xlims = bigfig.XLim;
    subplot(2,1,2)
    hold on
    scatter(EyeDataCopy(saccade,3),EyeDataCopy(saccade,2),20,'go','LineWidth',2)
    scatter(EyeDataCopy(fixation,3),EyeDataCopy(fixation,2),20,'ro')
    scatter(EyeDataCopy(smoothPursuit,3),EyeDataCopy(smoothPursuit,2),20,'bo')
    scatter(EyeDataCopy(pso,3),EyeDataCopy(pso,2),20,'mo')
    plot(EyeDataCopy(:,3),EyeDataCopy(:,2),'k','LineWidth',1)
    hold all
    plot(EyeDataCopy(:,3),y,'ko','markersize',5)

    y = (max(EyeDataCopy(:,2)) + 5) * ones(size(EyeDataCopy(:,3)));
    y(~unclassified) = nan;
    plot(EyeDataCopy(:,3),y,'ko','markersize',5)
    
    % legend({'Fixation', 'Smooth Pusuit','Post-saccadic Osscilation',...
    %             'Saccade'})
    xlabel('Time (ms)')
    ylabel('Degrees visual angle Y')
    bigfig = gca;
    trialLength = EyeDataCopy(end)-EyeDataCopy(1,3);
    quarters = round(length(EyeDataCopy(:,3))/4);
%     bigfig.XTick = [EyeDataCopy(1,3) EyeDataCopy(quarters,3) ...
%         EyeDataCopy((2*quarters),3) EyeDataCopy(3*quarters,3) EyeDataCopy(end,3)];
%     bigfig.XTickLabel= {'0', num2str(length(EyeDataCopy(:,1))/2) num2str(length(EyeDataCopy(:,1))) ...
%         num2str(length(EyeDataCopy(:,1))*1.5) num2str(length(EyeDataCopy(:,1))*2)};
    %bigfig.YLim = [-15 15];
    bigfig.XLim = xlims;

end


end