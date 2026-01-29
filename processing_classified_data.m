function [classifiedData] = processing_classified_data(processedGaze)
    classifiedData = processedGaze(209000:212000, :); % Specifies which data section to be included in the figure

    % Subtract the first timestamp value from all timestamp values
    classifiedData.EyetrackerTimestamp = classifiedData.EyetrackerTimestamp - classifiedData.EyetrackerTimestamp(1);

    figure; % Create new figure
    
    % Define class labels
    classLabels = {'Saccade', 'PSO', 'Fixation', 'Smooth Pursuit', 'Unclassified'};
    
    subplot(2, 1, 1); % 2 rows, 1 column, 1st subplot
    hold on; % Hold the plot

    for class = 1:5
        tempx = classifiedData.XSmooth;
        tempx(classifiedData.Classification ~= class) = NaN;
        plot(classifiedData.EyetrackerTimestamp, tempx, 'LineWidth', 3);
    end
    
    plot(classifiedData.EyetrackerTimestamp); % Plot XMean as dotted gray line

    ylim([0 1]); % Set y-axis limits

    xticks(0:1e5:max(classifiedData.EyetrackerTimestamp)); % Separated by 1*10^5
    xticklabels(0:100:max(classifiedData.EyetrackerTimestamp)/1e3); % Set the x-axis labels

    % Apply the changes to line width and tick direction
    set(gca, 'tickdir', 'out');

    % Get the y limits for the subplot
    y_limits = ylim;

    %% FIRST TOUCH
%       timestamp_start_touch1 = 143332; % Determined from Frame Data
%       timestamp_end_touch1 = 436669; % Determined from Frame Data
%       overlay_touch(timestamp_start_touch1, timestamp_end_touch1, y_limits);
% 
%     %% SECOND TOUCH
%       timestamp_start_touch2 = 1003344; % Determined from Frame Data
%       timestamp_end_touch2 = 1335013; % Determined from Frame Data
%       overlay_touch(timestamp_start_touch2, timestamp_end_touch2, y_limits);


    %% THIRD TOUCH
    % timestamp_start_touch3 = ;
    % timestamp_end_touch3 = ;
    % overlay_touch(timestamp_start_touch3, timestamp_end_touch3, y_limits);

    xlabel('Milliseconds'); % Label for the x-axis
    ylabel('Screen Proportion'); % Label for the y-axis
    title('X Smooth'); % Add title to the plot
    hold off; % Release the plot

    subplot(2, 1, 2); % 2 rows, 1 column, 2nd subplot
    hold on; % Hold the plot

    for class = 1:5
        tempy = classifiedData.YSmooth;
        tempy(classifiedData.Classification ~= class) = NaN;
        plot(classifiedData.EyetrackerTimestamp, tempy, 'LineWidth', 3);
    end

    plot(classifiedData.EyetrackerTimestamp); % Plot XMean as dotted gray line

	ylim([0 1]); % Set y-axis limits

    xticks(0:1e5:max(classifiedData.EyetrackerTimestamp)); % Separated by 1*10^5
    xticklabels(0:100:max(classifiedData.EyetrackerTimestamp)/1e3); % Set the x-axis labels

    % Apply the changes to line width and tick direction
    set(gca, 'tickdir', 'out');

    % Recalculate the y limits for the second subplot
    y_limits = ylim;

%      overlay_touch(timestamp_start_touch1, timestamp_end_touch1, y_limits);
%      overlay_touch(timestamp_start_touch2, timestamp_end_touch2, y_limits);
    % overlay_touch(timestamp_start_touch3, timestamp_end_touch3, y_limits);

    xlabel('Milliseconds'); % Label for the x-axis
    ylabel('Screen Proportion'); % Label for the y-axis
    title('Y Smooth'); % Add title to the plot
    legend(classLabels, 'Location', 'best');
    hold off; % Release the plot
end

function overlay_touch(start_timestamp, end_timestamp, y_limits)
    % Add the transparent box
    patch('XData', [start_timestamp end_timestamp end_timestamp start_timestamp], ...
          'YData', [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
          'FaceColor', [0.5 0.5 0.5], 'FaceAlpha', 0.05, 'EdgeColor', 'none');

    % Add vertical lines
    line([start_timestamp, start_timestamp], y_limits, 'Color', 'r');
    line([end_timestamp, end_timestamp], y_limits, 'Color', 'b');
end
