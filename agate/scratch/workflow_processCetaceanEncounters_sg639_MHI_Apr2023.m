% WORKFLOW_PROCESSCETACEANENCOUNTERS_SG639_MHI_APR2023
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

% initialize agate - either specify a .cnf or leave blank to browse/select
agate secret/agate_config_sg639_MHI_Apr2023.cnf
global CONFIG

%% (1) Cleanup encounter logs
% Triton manual pick logs
logFileName = [CONFIG.gmStr '_MW_recheck.xls'];
logFile = fullfile(CONFIG.path.analysis, 'triton', 'wood', ...
	[CONFIG.gmStr '_recheck_mw'], logFileName);
eventGap = 15;
[tl, tlm] = collapseTritonLog(logFile, eventGap);
% save as .mat and .csv
save(fullfile(CONFIG.path.analysis, 'triton', 'wood', ...
	[CONFIG.gmStr '_log_merged.mat']), 'tl', 'tlm');
writetable(tlm, fullfile(CONFIG.path.analysis, 'triton', 'wood', ...
	[CONFIG.gmStr '_log_merged.csv']));



%% (1) Plot encounter on map

% generate the basemap with bathymetry as figure 82, don't save .fig file
[baseFig] = createBasemap(CONFIG, 1, 82); 
