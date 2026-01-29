
%% Preprocessing
% trialData = map_stimuli_positions(trialData);
% frameData = map_frame_data();
% gazeData = mapTrialNumber(frameData, gazeData);
% gazeData = mapGazeTarget(frameData, gazeData);'
% gazeData = mapBlockAndTrialInBlock(trialData, gazeData);

%% Plotting 
% plotGazeTimeForBlock(trialData, gazeData, 1)

function plotGazeTimeForBlock(trialData, gazeData, chosenBlock)
    % Filter data for the chosen block
	filteredData = trialData(strcmp(trialData.PositiveFbObtained, 'True') & trialData.Block == chosenBlock, :);
	rewardObject = cell2mat(unique(filteredData.SelectedObjectID));
    blockData = gazeData(gazeData.Block == chosenBlock, :);
    
    % Get the unique trial numbers within this block
    trials = unique(blockData.TrialInBlock);
    
    % Initialize gaze time counters for each object
    gazeTimesRel1 = zeros(size(trials));
    gazeTimesRel2 = zeros(size(trials));
    gazeTimesRel3 = zeros(size(trials));
    
    % Calculate gaze times for each trial
    for i = 1:length(trials)
        trialData = blockData(blockData.TrialInBlock == trials(i), :);
        for j = 2:height(trialData)
            timeDifference = trialData.device_time_stamp(j) - trialData.device_time_stamp(j-1);
            if strcmp(trialData.SimpleGazeTarget(j-1), 'rel1')
                gazeTimesRel1(i) = gazeTimesRel1(i) + timeDifference;
            elseif strcmp(trialData.SimpleGazeTarget(j-1), 'rel2')
                gazeTimesRel2(i) = gazeTimesRel2(i) + timeDifference;
            elseif strcmp(trialData.SimpleGazeTarget(j-1), 'rel3')
                gazeTimesRel3(i) = gazeTimesRel3(i) + timeDifference;
            end
        end
    end
    
	% Calculate the total gaze time for each trial
    totalGazeTimePerTrial = gazeTimesRel1 + gazeTimesRel2 + gazeTimesRel3;
    
    % Plot the data
%     subplot(2,1,1);
%     hold on;
%     plot(trials, gazeTimesRel1./totalGazeTimePerTrial, '-', 'DisplayName', 'rel1');
%     plot(trials, gazeTimesRel2./totalGazeTimePerTrial, '-', 'DisplayName', 'rel2');
%     plot(trials, gazeTimesRel3./totalGazeTimePerTrial, '-', 'DisplayName', 'rel3');
%     xlabel('Trial Number in Block', 'FontSize', 14);
%     ylabel('Proportion of Gaze Time', 'FontSize', 14);
% 	hold off;
%     subplot(2,1,2);
	figure();
	hold on;

	plot(trials, gazeTimesRel1, '-', 'DisplayName', 'rel1', 'Color',[215,25,28,60]/255);hold on;
	[fitobject, gof] = fit(trials, gazeTimesRel1, 'poly2');
	h = plot(fitobject); 
    set(h,'Color',[215,25,28,255]/255, 'DisplayName', 'rel1 fit', 'LineWidth', 2);
	hold on;

    plot(trials, gazeTimesRel2, '-', 'DisplayName', 'rel2', 'Color',[171,221,164,60]/255);hold on;
	[fitobject, gof] = fit(trials, gazeTimesRel2, 'poly2');
	h2 = plot(fitobject); 
    set(h2,'Color',[171,221,164,255]/255, 'DisplayName', 'rel2 fit', 'LineWidth', 2);
	hold on;

    plot(trials, gazeTimesRel3, '-', 'DisplayName', 'rel3', 'Color',[43,131,186,60]/255);hold on;
	[fitobject, gof] = fit(trials, gazeTimesRel3, 'poly2');
	h3 = plot(fitobject); 
    set(h3,'Color',[43,131,186,255]/255,'DisplayName', 'rel3 fit' , 'LineWidth', 2);
	hold on;

% 	plot(trials, totalGazeTimePerTrial, '-', 'DisplayName', 'Total Gaze Time', 'LineWidth', 2);
    % Set the plot title and labels
    sgtitle(['Gaze Times for Block ' num2str(chosenBlock) '  Reward Object: ' rewardObject], 'FontSize', 18);
    xlabel('Trial Number in Block', 'FontSize', 14);
    ylabel('Total Gaze Time', 'FontSize', 14);
    legend('show', 'FontSize', 14, 'Location', 'northeast');
	hold off;
end


function gazeData = mapBlockAndTrialInBlock(trialData, gazeData)
    % Create new columns in gazeData initialized to NaN
    gazeData.Block = NaN(height(gazeData), 1);
    gazeData.TrialInBlock = NaN(height(gazeData), 1);
    
    % Loop through each trial in trialData
    for i = 1:height(trialData)
        % Extract the TrialInExperiment, Block, and TrialInBlock for the current trial
        currentTrialInExperiment = trialData.TrialInExperiment(i);
        currentBlock = trialData.Block(i);
        currentTrialInBlock = trialData.TrialInBlock(i);
        
        % Find rows in gazeData with a matching TrialNumber
        rowsToUpdate = gazeData.TrialNumber == currentTrialInExperiment;
        
        % Update the Block and TrialInBlock columns in gazeData for those rows
        gazeData.Block(rowsToUpdate) = currentBlock;
        gazeData.TrialInBlock(rowsToUpdate) = currentTrialInBlock;
    end
end


function gazeData = mapGazeTarget(frameData, gazeData)
    % Create a new column in gazeData initialized to NaN
     gazeData.SimpleGazeTarget = cell(height(gazeData), 1);
    
	prevTimestamp = -Inf;
    % Loop through each trial in frameData
    for trial = 1:length(frameData)
		disp(trial);
        % Get the data for the current trial
        currentTrialData = frameData{trial};
        
        % Extract the EyetrackerTimeStamps and SimpleGazeTargets for the current trial
        currentTimestamps = currentTrialData.EyetrackerTimeStamp;
        currentGazeTargets = currentTrialData.SimpleGazeTarget;

        % Loop through each timestamp in the current trial
        for i = 1:length(currentTimestamps)
            % Find rows in gazeData with timestamps greater than the previous timestamp and less than or equal to the current timestamp
            rowsToLabel = gazeData.device_time_stamp > prevTimestamp & gazeData.device_time_stamp <= currentTimestamps(i);
            
            % Update the SimpleGazeTarget column in gazeData for those rows
            gazeData.SimpleGazeTarget(rowsToLabel) = currentGazeTargets(i);
            
            % Update the previous timestamp
            prevTimestamp = currentTimestamps(i);
        end
    end
end


function gazeData = mapTrialNumber(frameData, gazeData)
    % Create a new column in gazeData initialized to NaN
    gazeData.TrialNumber = NaN(height(gazeData), 1);
    
    % Loop through each trial in frameData
    for trial = 1:length(frameData)
        % Extract the EyetrackerTimeStamp for the current trial
        currentTimestamps = frameData{trial}.EyetrackerTimeStamp;
        
        % Find the start and end timestamps for the current trial
        startTime = min(currentTimestamps);
        endTime = max(currentTimestamps);
        
        % Find rows in gazeData with timestamps between startTime and endTime
        rowsToLabel = gazeData.device_time_stamp >= startTime & gazeData.device_time_stamp <= endTime;
        
        % Update the TrialNumber column in gazeData for those rows
		TrialInExperiment = max(unique(frameData{trial}.TrialInExperiment));
        gazeData.TrialNumber(rowsToLabel) = TrialInExperiment;
    end
end


function frameData = map_frame_data()
	% Path to the directory containing the JSON files
	folderPath = '/Volumes/Womelsdorf Lab/++transfer++/for Xuan/Wo_VU595_15_2023-06-089_A_BHV/RuntimeData/frameData/';
	
	% Create the filename pattern
	filePattern = fullfile(folderPath, '*Trial_*.txt');
	files = dir(filePattern);

	% Get the filenames
	fileNames = {files.name};
	
	% Extract trial numbers from the filenames
	trialNumbers = cellfun(@(x) str2double(regexp(x, '(?<=_Trial_)\d+', 'match')), fileNames);
	
	% Sort the trial numbers and get the indices of the sorted order
	[~, sortedIndices] = sort(trialNumbers);
	
	% Reorder the files array based on the sorted indices
	files = files(sortedIndices);

	
	% Initialize a cell array to store the RelevantStims data from each JSON file
	frameData = {};
	
	% Loop through the files
	for i = 1:length(files)
    	filename = fullfile(folderPath, files(i).name);
    	
    	
    	% Convert the JSON string to a MATLAB structure
    	data = readtable(filename, 'Delimiter', '\t');
    	frameData{end+1,1} = data;
	end

% 	trialData.RelevantStims = allRelevantStims;
end


function trialData = map_stimuli_positions(trialData)
	% Path to the directory containing the JSON files
	folderPath = '/Volumes/Womelsdorf Lab/++transfer++/for Xuan/Wo_VU595_15_2023-06-089_A_BHV/RuntimeData/TrialData/';
	
	% Create the filename pattern
	filePattern = fullfile(folderPath, '*trial_*.json');
	files = dir(filePattern);

	% Get the filenames
	fileNames = {files.name};
	
	% Extract trial numbers from the filenames
	trialNumbers = cellfun(@(x) str2double(regexp(x, '(?<=_trial_)\d+', 'match')), fileNames);
	
	% Sort the trial numbers and get the indices of the sorted order
	[~, sortedIndices] = sort(trialNumbers);
	
	% Reorder the files array based on the sorted indices
	files = files(sortedIndices);
	
	% Initialize a cell array to store the RelevantStims data from each JSON file
	allRelevantStims = {};
	
	% Loop through the files
	for i = 1:length(files)
    	filename = fullfile(folderPath, files(i).name);
    	
    	% Open the file for reading
    	fid = fopen(filename, 'r');
    	
    	% Read the file data into a string
    	rawData = fread(fid, inf);
    	str = char(rawData');
    	
    	% Close the file
    	fclose(fid);
    	
    	% Convert the JSON string to a MATLAB structure
    	data = jsondecode(str);
    	
    	% Check if the RelevantStims field exists in the data
    	if isfield(data, 'RelevantStims')
        	% Store the RelevantStims data in the cell array
        	allRelevantStims{end+1,1} = data.RelevantStims;
    	end
	end

	trialData.RelevantStims = allRelevantStims;
end

% allRelevantStims now contains the RelevantStims data from all the loaded JSON files
