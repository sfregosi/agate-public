function ermaDets = combineErmaLogs(path_logs, verbose)
% COMBINEERMALOGS	One-line description here, please
%
%   Syntax:
%       ERMADETS = COMBINEERMALOGS(CONFIG, PATH_LOGS, VERBOSE)
%
%   Description:
%       Detailed description here, please
%   Inputs:
%       path_logs [string] fullfile path to the log files to be combined.
%                 Within agate system, typically CONFIG.path.bsLocal
%       verbose   [logical] optional argument to print progress in Command
%                 Window. Default 'false', set to 'true' or '1' to print.
%
%	Outputs:
%       ermaDets  [table] start and end time and number of clicks of each
%                 ERMA detection (encounter)
%
%   Examples:
%
%   See also READERMAREPORT, COLLAPSETRITONLOG
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   13 March 2024
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FOR TESTING %%%%%

% path_logs = 'D:\sg679_MHI_May2023\piloting\basestationFiles';
% verbose = true;

%%%%%%%%%%%%%%%%%%%

% check args
if nargin < 2 || isempty(verbose)
	verbose = false;
end

if nargin < 1
	path_logs = [];
end

% agate CONFIG is not required, but if it is present, it will be used in
% file search path if needed
if ismember('CONFIG', who('global'))
	global CONFIG
	searchPath = CONFIG.path.mission;
else
	searchPath = cd;
end
% check folder exists and if not prompt to select
if ~exist(path_logs, 'dir')
	path_logs = uigetdir(fullfile(searchPath), ...
		'Select folder containing ERMA detection logs');
end

% get a list of all logs for this mission
logFiles = dir(fullfile(path_logs, 'ws*z'));
if verbose == true
	fprintf(1, 'Combining %i ERMA log files from %s\n', length(logFiles), path_logs);
end

% create output variable
ermaDets = array2table(nan(0, 6), 'VariableNames', ...
	{'eventNum', 'start', 'stop', 'nClicks', 'startDatenum', 'stopDatenum'});
ec = 1; % encounter counter (for filling in the table)

% loop through all log files
for l = 1:length(logFiles)
	detFile = fullfile(logFiles(l).folder, logFiles(l).name);
	s = readErmaReport(detFile);

	% if s has some data - pull out start/end time of each encounter
	if ~isempty(s.enc)
		for e = 1:length(s.enc)
		    ermaDets.eventNum(ec)     = ec;
			ermaDets.startDatenum(ec) = s.enc(e).encT0_D; 
			ermaDets.stopDatenum(ec)  = s.enc(e).encT1_D;
			ermaDets.nClicks(ec)      = s.enc(e).nClicks;
			ec = ec + 1;
		end
		if verbose == true
			fprintf(1, '%s: %i encounters parsed\n', logFiles(l).name, length(s.enc));
		end
	elseif isempty(s.enc) && verbose == true
		fprintf(1, '%s: no encounters\n', logFiles(l).name);
	end
end

% get datetime for readability
ermaDets.start = datetime(ermaDets.startDatenum, 'ConvertFrom', 'datenum');
ermaDets.stop = datetime(ermaDets.stopDatenum, 'ConvertFrom', 'datenum');

end