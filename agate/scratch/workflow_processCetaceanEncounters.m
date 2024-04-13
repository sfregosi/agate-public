% WORKFLOW_PROCESSCETACEANENCOUNTERS
%	Workflow for creating summary plots and tables for cetacean encounters
%
%	Description:
%		This script takes inputs of glider positional data and cetacean
%		acoustic encounter data (identified by automated or manual methods)
%		and pairs them up to summarize cetacean events/encounters and 
%       create maps of glider locations at the time of cetacean acoustic 
%       encounters
%
%       Sections:
%       (1) Cleanup event logs (either collapse Triton logs, or combine
%           ERMA detection logs
%       (2) Create encounter map
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	09 March 2024
%	Updated:        14 March 2024
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate - either specify a .cnf or leave blank to browse/select
agate agate_mission_config.cnf
global CONFIG

%% (1) Clean up acoustic event logs

% Triton logs - manual event picks for any acoustic system
% can specify filename, or set logFile to [] to prompt to select file
logFile = fullfile(CONFIG.path.analysis, 'triton', 'logFile.xls');
% define acceptable gap between events. Events within this time (in
% minutes) will be collapsed to a single event (encounter)
eventGap = 15;
% collapse logs - tl is original, tlm is merged
[tl, tlm] = collapseTritonLog(logFile, eventGap);
% save as .mat and/or .csv
save(fullfile(CONFIG.path.analysis, 'triton', 'log_merged.mat'), 'tl', 'tlm');
writetable(tlm, fullfile(CONFIG.path.analysis, 'triton', 'log_merged.csv'));

% ERMA detection logs
% ERMA detection logs are created per dive, so need to combine them all
% this does not do any merging based on an allowable time between events
ermaDets = combineErmaLogs(CONFIG.path.bsLocal, []);
% save as .mat and/or .csv
save(fullfile(CONFIG.path.analysis, ...
	[CONFIG.gmStr '_ERMA_encounters_combined.mat']), 'ermaDets');
writetable(ermaDets, fullfile(CONFIG.path.analysis, ...
	[CONFIG.gmStr '_ERMA_encounters_combined.csv']));


%% (1) Plot encounter on map

