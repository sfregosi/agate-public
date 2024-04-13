function checkPath
%CHECKPATH	Check the necessasry folders are there and on the path
%						**********************			
%                       ******DEPRECATED******
%						**********************
%
%   Syntax:
%       CHECKPATH
%
%   Description:
%       Called from the agate initialization. Sets up the necessary paths 
%       in the CONFIG variable, while checking that all needed subfolders 
%       are present and on the path. If not, it makes them. 
%
%       ****NOTE: THIS HAS BEEN MOVED TO A NESTED FUNCTION IN AGATE.M TO
%       REMOVE REQUIREMENT TO MANUALLY SET PATH IF AGATE IS FIRST
%       INITIALIZED FROM THE AGATE-PUBLIC/AGATE FOLDER****
%
%   Inputs:
%       none
%
%	Outputs:
%       none
%
%   Examples:
%       checkPath
%
%	See also
%       agate
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%       This function is based off the 'check_path' function from Triton,
%       created by S. Wiggins and available at 
%           https://github.com/MarineBioAcousticsRC/Triton/
%
%   FirstVersion:   06 April 2023
%   Updated:        09 March 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global CONFIG

% root directory
CONFIG.path.agate = fileparts(which('agate'));

% make sure utils is on path
CONFIG.path.utils = fullfile(CONFIG.path.agate, 'utils');
addpath(genpath(CONFIG.path.utils));

% make sure convertAcoustics is on path
CONFIG.path.convertAcoustics = fullfile(CONFIG.path.agate, 'convertAcoustics');
addpath(genpath(CONFIG.path.convertAcoustics));

% check/create settings folder
CONFIG.path.settings = fullfile(CONFIG.path.agate,'settings');
if ~exist(CONFIG.path.settings, 'dir')
	disp(' ')
	disp('Settings directory is missing, creating it ...')
	mkdir(CONFIG.path.settings);
end
addpath(genpath(CONFIG.path.settings)); % no genpath will not add subdirs

end