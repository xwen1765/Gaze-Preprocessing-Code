function info = get_fixation_smoothPursuit_info(SacStructInput,sel, fsample)
% info = get_fixation_smoothPursuit_info(SacStructInput,sel)


if isrow(sel); sel = sel'; end

st = find(diff(sel)==1)+1;
fn = find(diff(sel)==-1);
if numel(st)>0
    if fn(1) < st(1); st = [1;st]; end
    if fn(end) < st(end); fn = [fn;numel(sel)]; end
else
    st = 0;
    fn = 0;
end

tmp = nan(numel(st),1);
startTime = tmp;
endTime = tmp;
startRow = tmp;
endRow = tmp;
meanVel = tmp;
duration = tmp;
amplitude = tmp;
meanDir = tmp;
startPointX = tmp;
endPointX = tmp;
startPointY = tmp;
endPointY = tmp;
meanPointX = tmp;
meanPointY = tmp;
maxAmplitude = [tmp,tmp];
dispersion = tmp;

% dilationPre = cell(numel(st),1);
% dilationDuring = cell(numel(st),1);
% dilationPost = cell(numel(st),1);

x = SacStructInput(:,1);
y = SacStructInput(:,2);
t = SacStructInput(:,3);
% dil = SacStructInput(:,4);

if st~=0
    for ievent=1:numel(st)
        ist = st(ievent);
        ifn = fn(ievent);
        startTime(ievent) = t(ist);
        endTime(ievent) = t(ifn);
        startRow(ievent) = ist;
        endRow(ievent) = ifn;
        duration(ievent) = t(ifn) - t(ist);
        meanVel(ievent) = nanmean( abs( complex( diff(x(ist:ifn)), diff(y(ist:ifn))) ) ./ diff(t(ist:ifn)) );
        amplitude(ievent) = abs( complex( x(ifn) - x(ist), y(ifn) - y(ist) ) );
        maxAmplitude(ievent,:) = [ max(x(ist:ifn)) - min(x(ist:ifn)), max(y(ist:ifn)) - min(y(ist:ifn)) ];
        startPointX(ievent) = x(ist);
        endPointX(ievent) = x(ifn);
        startPointY(ievent) = y(ist);
        endPointY(ievent) = y(ifn);
        meanPointX(ievent) = nanmean(x(ist:ifn));
        meanPointY(ievent) = nanmean(x(ist:ifn));
        meanDir(ievent) = angle( sum( complex( diff(x(ist:ifn)), diff(y(ist:ifn)) ) ) );        
    %     dilationPre{ievent} = dil(max(1, ist -200 / (1000/fsample)):ist-1);
    %     dilationDuring{ievent} = dil(ist : ifn);
    %     dilationPost{ievent} = dil(min([ifn+1,end]):min(ifn+200/(1000/fsample):end));
    end
end

info = struct('StartTime',startTime,'EndTime',endTime, 'StartGazeRow', startRow, 'EndGazeRow', endRow,'Duration',duration,'MeanVelocity',meanVel,...
    'Amplitude',amplitude,'MaxAmplitude',maxAmplitude,'StartPointX',startPointX,'EndPointX',endPointX,...
    'StartPointY',startPointY,'EndPointY',endPointY,'MeanDirection',meanDir, 'MeanPointX', meanPointX, 'MeanPointY', meanPointY);
% info.DilationPre = dilationPre;
% info.DilationDuring = dilationDuring;
% info.DilationPost = dilationPost;

