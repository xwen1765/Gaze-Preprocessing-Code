function dout = smoothDistance(d,fsample,filtFreq)
% dout = smoothDistance(d,fsample)
% dout = smoothDistance(d,fsample,filtFreq)
%
% Lows-pass filter for distance sampled at fsample. Low-pass frequency is
% "filtFreq" (default=1)

%checks
dorig = d;

if nargin < 3
    filtFreq = 1; %1 second
end

%nan the bad segments
d = dorig;
d(d==0) = nan;
nans = isnan(d);

%interpolate so filtering will work
d(nans) = interp1(find(~nans),d(~nans),find(nans));
if isnan(d(1)) %double check the edges arent nans still
    igood = find(~isnan(d),1);
    d(1:igood) = d(igood);
end
if isnan(d(end))
    igood = find(~isnan(d),1,'last');
    d(igood:end) = d(igood);
end

%lowpass filter
filt_ord = 4;
fc = filtFreq ./ (fsample/2);
[b,a] = butter(filt_ord,fc,'low');
mu = nanmean(d);
ds = filtfilt(b,a,d-mu);
ds = ds + mu;

%prepare output, but re-set nans
dout = ds;
dout(nans) = nan;



%{
% %set all bad points to nan
% d(d==0) = NaN;
% 
% diffD = diff(d);
% zd = (diffD - nanmean(diffD)) ./ nanstd(diffD);


%find start and end points where distance changed suddenly
% - start is where abs(zd)>5, end is where abs(zd)>5 and has opssoite
% direction as start
dorig = d; 
d(d==0) = NaN;
diffD = [0;diff(d)];
zd = NaN(size(diffD,1),1);
zd(~isnan(diffD)) = zscore(diffD(~isnan(diffD)));
% zd = zscore([0;diff(d)]); 


thresh = 5;
onsets = [];
offsets = [];
st = [];
for n=1:numel(zd)

    %val = sign(zd(n))*double(abs(zd(n))<5);
    if isempty(st) && abs(zd(n))>thresh
        val = sign(zd(n));
        onsets(size(onsets,1)+1,1) = n;
        st = n;
    end

    if ~isempty(st) && abs(zd(n))>thresh && sign(zd(n))~=val
        offsets(size(offsets,1)+1,1) = n-1; 
        st = [];
    end
end

%deal with edge cases
if onsets(1) > offsets(1)
    d(1:offsets(1)) = d(offsets(1)+1);
    offsets(1) = [];
end
if offsets(end) < onsets(end)
    d(onsets(end):end) = d(onsets(end)-1);
    onsets(end) = [];
end

% find spots where we only got N good samples in a sea of bad ones
minbad = 2;
tooShort = find( onsets(2:end) - offsets(1:end-1) <= minbad+1 ); %have to add one
onsets(tooShort+1) = [];
offsets(tooShort) = [];

%get rid of the bad samples and smooth
selbad = false(size(d));
for n=1:numel(onsets)
    selbad(onsets(n):offsets(n)) = 1;
end

dout = d;
dout(selbad) = interp1(find(~selbad),d(~selbad),find(selbad));
dout = medfilt1(dout,5);
%figure; plot(d); hold all; plot(dout)
foo=1;

%{
%find start and end points where distance changed suddenly
zd = zscore(diff(d)); 
st = find(zd < -5)+1;
fn = find(zd > 5);

%deal with edge cases
if st(1) > fn(1)
    d(1:fn(1)) = d(fn(1)+1);
    fn(1) = [];
end
if fn(end) < st(end)
    d(st(end):end) = d(st(end)-1);
    st(end) = [];
end
%}

%}


