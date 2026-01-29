% Define the desired CurrentTrialStates
% desiredStates = ["ChooseTile", "TileFlashFeedback", "SelectionFeedback"];

% Get all rows where TaskName is 'MazeGame' and CurrentTrialState is in the desiredStates
% trialGazeData = gazeData(strcmp(gazeData.TaskName, 'MazeGame') & ismember(gazeData.CurrentTrialState, desiredStates), :);
% Assuming you have trialData defined somewhere

trial_number = 1;

trialGazeData = gazeData(gazeData.TrialNumber == trial_number,:);
selectedObject = trialData.SelectedObjectID{trialData.TrialInExperiment == trial_number};
relevantStims = trialData.RelevantStims{trialData.TrialInExperiment == trial_number};

% Extract the x and y positions of the three objects
objectPositions = zeros(3, 2); % Preallocate for [x, y] of three objects
objectIDs = cell(3, 1); % To store the object IDs

for i = 1:3
    objectPositions(i, :) = [relevantStims(i).StimScreenLocation.x, relevantStims(i).StimScreenLocation.y];
    objectIDs{i} = relevantStims(i).StimID;
end

x_left = trialGazeData.left_ADCS_x;
y_left =  trialGazeData.left_ADCS_y;
x_right = trialGazeData.right_ADCS_x;
y_right =  trialGazeData.right_ADCS_y;

x = [x_left; x_right] * 1920;
y = [1-y_left;1-y_right] * 1080;

finiteIndices = isfinite(x) & isfinite(y);

xEdges = linspace(0, 1920, 350);
yEdges = linspace(0, 1080, 350);


[heatmap, xCenters, yCenters] = histcounts2(x(finiteIndices), y(finiteIndices), xEdges, yEdges);
heatmap(heatmap == 0) = NaN;

% Define sigma and size of Gaussian kernel
sigma = 8;  % was 8, increased to 16
sz = 4*sigma+1; % was 4*sigma+1, increased to 6*sigma+1

% Create a Gaussian kernel
[x, y] = meshgrid(-sz/2:sz/2);
GaussianKernel = exp(-(x.^2 + y.^2)/(2*sigma^2));
GaussianKernel = GaussianKernel/sum(GaussianKernel(:)); % normalize

% Create a mask that is '0' for NaNs in the heatmap and '1' otherwise
nanMask = ~isnan(heatmap');

% Replace NaNs in the heatmap with '0' so they don't affect convolution
heatmapNaNsReplaced = heatmap';
heatmapNaNsReplaced(isnan(heatmapNaNsReplaced)) = 0;

% Convolve the heatmap with the Gaussian kernel
smoothedHeatmapTemp = conv2(heatmapNaNsReplaced, GaussianKernel, 'same');

% Apply the mask to the smoothed heatmap so that '0' replaces positions where there were NaNs
smoothedHeatmap = smoothedHeatmapTemp .* nanMask;

% Convert smoothed heatmap to an image
hImage = imagesc(xCenters, yCenters, smoothedHeatmap);
colormap(turbo); % using jet colormap
colorbar;

% Plot the squares centered on the objects' positions
hold on;
for i = 1:3
    if strcmp(objectIDs{i}, selectedObject) % If the object is the selected object
        rectangle('Position', [objectPositions(i, 1) - 20,  objectPositions(i, 2) - 20, 40, 40], 'EdgeColor', 'red', 'LineWidth', 2);
    else
        rectangle('Position', [objectPositions(i, 1) - 20,  objectPositions(i, 2) - 20, 40, 40], 'EdgeColor', 'blue', 'LineWidth', 2);
    end
end
hold off;


% Create an alpha map where NaN and zero values are transparent
alphaMap = smoothedHeatmap > 0;
set(hImage, 'AlphaData', alphaMap);

% Correct the y-axis direction if it's flipped
set(gca, 'YDir', 'normal', 'tickdir','out');

axis image;

xlabel('X positions');
ylabel('Y positions');



%title('Smoothed Heatmap of X and Y positions over 20 Trials');

%exportgraphics(gcf,'myfigure.png')

