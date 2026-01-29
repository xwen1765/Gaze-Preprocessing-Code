function [startEst, endEst] = find_borders(borders)
% [startEst, endEst] = find_borders(borders)

%checks
if islogical(borders)
    borders = diff(borders);
else
   if any(~ismember(borders,[-1 0 1]))
      error('borders must either be a logical vector, or a difference of a logical vector') 
   end
end

%early exit
if ~any(borders)
    startEst = [];
    endEst = [];
    return
end

if isrow(borders); doTranspose = 1; borders = borders';
else doTranspose = 0;
end

%estimate borders
startEst = find(borders==1)+1;
endEst = find(borders==-1);

if isempty(startEst); startEst = 1; end
if isempty(endEst); endEst = numel(borders)+1; end


%if the start/end of the data has bad data, then we dont have an estimate
%for the start/end of the blink. blink starts/ends at start/end of recording
if endEst(1) < startEst(1) 
    %disturbance_all{3}(endEst(1)) = 1;
    startEst = [1;startEst];
end

if endEst(end) < startEst(end) 
    %disturbance_all{3}(endEst(end)) = 1;
    endEst = [endEst;numel(borders)+1];
end

%transpose to match input
if doTranspose
    startEst = startEst';
    endEst = endEst';
end

%Final check
if numel(startEst) ~= numel(endEst)
    error('huh?')
end

