function agate(missionCnf)
%AGATE	Initialize a new session of agate
%
%   Syntax:
%       AGATE missionCnf
%
%   Description:
%       Initialization step for agate toolbox. Reads in a specified
%       configuration file, or if none is specified, prompts user to select
%       configuration file. Sets paths and completes some checks.
%
%   Inputs:
%      missionCnf   Optional argument to specific configuration file for a
%                   particular mission e.g., 'sg639_MHI_Apr2023.cnf'
%
%   Outputs:
%      No workspace outputs. Generates a global CONFIG variable
%
%   Examples:
%       agate agate_sgXXX_Location_MonYear_config.cnf
%
%   See also   SETCONFIG, CHECKPATH
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   06 April 2023
%   Updated:        09 March 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear global CONFIG;  % clear out old globals
warning off % this is turned off for plotting messages

global CONFIG
% CONFIG = struct;

CONFIG.ver = '0.1.20240309   https://github.com/sfregosi/agate-public';
fprintf('      agate   version %s\n\n', CONFIG.ver)

if nargin < 1
	CONFIG.missionCnf = [];
else
	CONFIG.missionCnf = missionCnf;
end

% get matlab version for differences and backwards compatibility
CONFIG.mver = version;

checkPath;

setCONFIG(CONFIG.missionCnf);

end


function checkPath
%CHECKPATH	Check the necessasry folders are there and on the path
%
%   Syntax:
%       CHECKPATH
%
%   Description:
%       Called from the agate initialization. Sets up the necessary paths
%       in the CONFIG variable, while checking that all needed subfolders
%       are present and on the path. If not, it makes them.
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
%   Updated:        04 March 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global CONFIG

% root directory
CONFIG.path.agate = fileparts(which('agate'));
addpath(CONFIG.path.agate); % no subdirs

% make sure utils is on path
CONFIG.path.utils = fullfile(CONFIG.path.agate, 'utils');
addpath(genpath(CONFIG.path.utils)); % with subdirs

% make sure convertAcoustics is on path
CONFIG.path.convertAcoustics = fullfile(CONFIG.path.agate, 'convertAcoustics');
addpath(genpath(CONFIG.path.convertAcoustics)); % with subdirs

% check/create settings folder
CONFIG.path.settings = fullfile(CONFIG.path.agate,'settings');
if ~exist(CONFIG.path.settings, 'dir')
	disp(' ')
	disp('Settings directory is missing, creating it ...')
	mkdir(CONFIG.path.settings);
end
addpath(genpath(CONFIG.path.settings)); % with subdirs

end
