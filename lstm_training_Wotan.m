% Example data generation
numTrials = 100;
% assuming each trial has 50 time points
% it has to be fixed (normalized to a fixed range)
numTimePoints = 50; 

numFeatures = 8;
rawData = rand(numTrials, numFeatures, numTimePoints); % random gaze data
gazeData = cell(numTrials, 1);
% Process each trial
for i = 1:numTrials
    % Extract the gaze data for each trial
    % This example assumes that the rawData contains trials of equal length and uses all time points
    % You will need to adjust this part to extract the actual length of each trial from your rawData
    trialData = squeeze(rawData(i, :, :));
    % Store in the cell array
    gazeData{i} = trialData;
end

featureChoice = randi([0, 1], numTrials, numFeatures); % random binary labels

% Define LSTM network architecture
layers = [
    sequenceInputLayer(numFeatures)
    lstmLayer(3, 'OutputMode', 'last')
    fullyConnectedLayer(numFeatures)
    sigmoidLayer
    regressionLayer];

% Training options
options = trainingOptions('adam', ...
    'MaxEpochs',100, ...
    'MiniBatchSize', 10, ...
    'InitialLearnRate', 0.01, ...
    'GradientThreshold', 1, ...
    'Shuffle', 'every-epoch', ...
    'Verbose', 0, ...
    'Plots', 'training-progress');

% Train the network
net = trainNetwork(gazeData, featureChoice, layers, options);


numTestTrials = 5; % Number of test trials
% Initialize the cell array for testGazeData
testGazeData = cell(numTestTrials, 1);

% Generate random test data
for i = 1:numTestTrials
    
    % Generate random gaze data for this trial
    trialData = rand(numFeatures, numTimePoints);
    
    % Store in the cell array
    testGazeData{i} = trialData;
end

% Predict using the trained LSTM network
predictedFeatureChoices = predict(net, testGazeData);

threshold = 0.5;
binaryPredictions = predictedFeatureChoices > threshold;
