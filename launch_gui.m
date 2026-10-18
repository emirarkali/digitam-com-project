%% launch_gui.m - Launches Project 7 GUI and waits for user interaction
% Prevents MATLAB -batch mode from immediately exiting upon launch.

cd(fileparts(mfilename('fullpath')));
addpath(genpath(pwd));

fig = Project7_GUI();

% Keep GUI open until the user closes the window
if isvalid(fig)
    uiwait(fig);
end
