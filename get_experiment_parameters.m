function [screenX,screenY,fsample] = get_experiment_parameters(str)
% [screenX,screenY,fsample] = get_experiment_parameters(str)

if strcmpi(str,'acer120')
    screenX = 47.2 * 10;
    screenY = 26.5 * 10;
    fsample = 120;
elseif strcmpi(str,'tx300')
    screenX = 50.8*10; %mm
    screenY = 28.7*10; %mm
    fsample = 300; %Hz
elseif strcmpi(str,'elo_desktop')
    screenX = 47.8*10; %mm
    screenY = 27.3*10; %mm
    fsample = 300; %Hz
elseif strcmpi(str,'spectrum')
    screenX = 43.5*10; %mm
    screenY = 24.0*10; %mm
    fsample = 600; %Hz
else
    error('unrecognized setup');
end
    