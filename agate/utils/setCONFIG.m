function setCONFIG(missionCnf)
%SETCONFIG Set up global CONFIG structure for agate
%
%   Syntax:
%      CONFIG = SETCONFIG
%
%   Description:
%       Called from the agate initialization. Sets the default
%       configuration parameters and updates according to any .cnf files
%       present in the settings folder
%
%   Inputs:
%      input    none
%
%   Outputs:
%       CONFIG  Global structure containing all the user-set configurations
%               such as paths, basestation login info, etc
%
%   Examples:
%
%   See also AGATE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%       This function is based off the 'initparams' function from Triton,
%       created by S. Wiggins and available at
%           https://github.com/MarineBioAcousticsRC/Triton/
%
%   FirstVersion: 	06 April 2023
%   Updated:        11 April 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


global CONFIG

% set defaults in case no config file
% % paths
% CONFIG.path.shp = 'C:\Users\User.Name\Documents\GIS\';
% CONFIG.path.survey = 'C:\Desktop\glider_mission\';
% % basestation configuration
% CONFIG.bs.cnfFile = 'basestation.cnf';
% CONFIG.bs.host = 'url.com';
% CONFIG.bs.username = 'pilot';
% CONFIG.bs.password = 'PsWrD';


% update based on user-defined configuration file if it exists

% if none specified, prompt to locate one
if isempty(CONFIG.missionCnf)
	[name, path] = uigetfile([CONFIG.path.settings, '\*.cnf'], ...
		'Select configuration file');
	CONFIG.missionCnf = fullfile(path, name);
	fprintf(1, 'Mission configuration file:\n      %s\n', CONFIG.missionCnf);
else
	% check if full file or just parts
	[path, ~, ~] = fileparts(CONFIG.missionCnf);
	if ~isempty(path)
		CONFIG.path.cnfFid = fopen(CONFIG.missionCnf,'r');
		parseCnf(CONFIG.missionCnf);
	else % no path specified
		% default location is within agate\settings folder, so try that
		CONFIG.missionCnf = fullfile(CONFIG.path.settings, CONFIG.missionCnf);
		% otherwise prompt to select one
		if ~exist(missionCnf, 'file')
			[name, path] = uigetfile([CONFIG.path.agate, '\*.cnf'], ...
				'Select survey configuration file');
			CONFIG.missionCnf = fullfile(path, name);
		end
	end
end
CONFIG.path.cnfFid = fopen(CONFIG.missionCnf,'r');
parseCnf(CONFIG.missionCnf);
CONFIG.gmStr = [CONFIG.glider '_' CONFIG.mission];

% if basestation 'bs' configurations exist
if isfield(CONFIG, 'bs')
	% parse the basestation configuration file
	% prompt to select if none specified in mission configuration file
	if ~exist(CONFIG.bs.cnfFile, 'file')
		[name, path] = uigetfile([CONFIG.path.settings, '\*.cnf'], ...
			'Select basestation configuration file');
		CONFIG.bs.cnfFile = fullfile(path, name);
	end
	% CONFIG.bs.cnfFid = fopen(CONFIG.bs.cnfFile,'r');
	parseCnf(CONFIG.bs.cnfFile);
end

% if pm configurations exist
% parse PMAR conversion configuration file
if isfield(CONFIG, 'pm') && (CONFIG.pm.loggers == 1) && (CONFIG.pm.convert == 1)
	if ~exist(CONFIG.pm.cnfFile, 'file')
		[name, path] = uigetfile([CONFIG.path.settings, '\*.cnf'], ...
			'Select PMAR convert configuration file');
		CONFIG.pm.cnfFile = fullfile(path, name);
	end
	parseCnf(CONFIG.pm.cnfFile);
end
end

%%%%%% NESTED FUNCTIONS %%%%%%
function CONFIG = parseCnf(userCnf, CONFIG)
% parse info from .cnf text files

global CONFIG

fid = fopen(userCnf,'r');
if fid == -1
	fprintf(1, 'No file selected. Exiting.\n')
	return
end
al = textscan(fid,'%s','delimiter','\n');
nl = length(al{1});
if nl < 1
	fprintf(1, 'Error: no data in configuration file\n')
else
	frewind(fid);
	for i = 1:nl
		line = fgets(fid);
		if ~strcmp(line(1), '%')
			eval(line);
		end
	end
end
fclose(fid);

end

