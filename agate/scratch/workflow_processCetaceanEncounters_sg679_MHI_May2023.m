% WORKFLOW_PROCESSCETACEANENCOUNTERS_SG679_MHI_MAY2023
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
%       (1) Cleanup event/encounter logs (either collapse Triton logs, or
%           combine ERMA detection logs
%       (2) Get locations of each event
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
agate secret/agate_config_sg679_MHI_May2023.cnf
global CONFIG

%% (1) Cleanup event/encounter logs

% %%% TRITON %%%
% Triton manual pick logs
logFileName = [CONFIG.gmStr '_MW.xls'];
logFile = fullfile(CONFIG.path.analysis, 'triton', 'wood', ...
	[CONFIG.gmStr '_log_mw'], logFileName);
eventGap = 15;
[tl, tlm] = collapseTritonLog(logFile, eventGap);
% save as .mat and .csv
save(fullfile(CONFIG.path.analysis, 'cetaceanEvents', ...
	[CONFIG.gmStr '_log_merged.mat']), 'tl', 'tlm');
writetable(tlm, fullfile(CONFIG.path.analysis, 'cetaceanEvents', ...
	[CONFIG.gmStr '_log_merged.csv']));

% %%% ERMA %%%
% ERMA detection logs
ermaDets = combineErmaLogs(CONFIG.path.bsLocal, []);
% ignoring last event (Dive 173) because shore dive right before recovery
ermaDets(665,:) = [];
% save as .mat and .csv
save(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined.mat']), 'ermaDets');
writetable(ermaDets, fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined.csv']));

% ERMA log was manually checked for false positives
ermaDetsChecked = readtable(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined_trueChecked.csv']));
% ignoring last event (Dive 173) because shore dive right before recovery
ermaDetsChecked(665,:) = [];
% save as .mat and .csv
save(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined_trueChecked.mat']), 'ermaDetsChecked');
writetable(ermaDetsChecked, fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined_trueChecked.csv']));


% pull only true detections
trueIdx = find(strcmp(ermaDetsChecked.truePm, 'Y'));
ermaDetsTrue = ermaDetsChecked(trueIdx,:);
% save as .mat and .csv
save(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_truePmOnly.mat']), 'ermaDetsTrue');
writetable(ermaDetsTrue, fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_truePmOnly.csv']));

% collapse true sperm whale detections into 'encounters' following 15 min 
% gap rule like Triton logs
ermaDetsTrueEnc = ermaDetsTrue(1,:);
counter = 2;
for f = 2:height(ermaDetsTrue)
	if ermaDetsTrue.start(f) - minutes(15) < ermaDetsTrueEnc.stop(counter-1)
		within = true;
		ermaDetsTrueEnc.stop(counter-1,:) = ermaDetsTrue.stop(f);
	else % no collapsing
		ermaDetsTrueEnc(counter,:) = ermaDetsTrue(f,:);
		counter = counter + 1;
	end
end

% remove the cols that no longer apply
ermaDetsTrueEnc.nClicks = [];
ermaDetsTrueEnc.startDatenum = [];
ermaDetsTrueEnc.stopDatenum = [];
ermaDetsTrueEnc.truePm = [];
ermaDetsTrueEnc.diveEncounter = [];

% calculate duration
ermaDetsTrueEnc.duration_min = minutes(ermaDetsTrueEnc.stop - ermaDetsTrueEnc.start);

% save as .mat and .csv
save(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_truePmOnly_merged.mat']), 'ermaDetsTrueEnc');
writetable(ermaDetsTrueEnc, fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_truePmOnly_merged.csv']));

%% (1b) OR load previously processed logs

% unchecked Triton events
load(fullfile(CONFIG.path.analysis, 'cetaceanEvents', ...
	[CONFIG.gmStr '_log_merged.mat']));

% unchecked ERMA events
load(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined.mat']));
% checked ERMA events
ermaDetsChecked = readtable(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_events_combined_trueChecked.csv']));

% true ERMA sperm whale events merged into encounters
load(fullfile(CONFIG.path.analysis, 'erma', ...
	[CONFIG.gmStr '_ERMA_truePmOnly_merged.mat']));


%% (2) Summarize some counts

% %%% ERMA Detections
fprintf(1, ['%i total ERMA detections:\n %i true Pm detections\n', ...
	' %i false positives\n %i duplicates\n %i unknowns\n'], height(ermaDets), ...
length(find(strcmp(ermaDetsChecked.truePm, 'Y'))), ...
length(find(strcmp(ermaDetsChecked.truePm, 'N'))), ...
length(find(strcmp(ermaDetsChecked.truePm, 'dup'))), ...
length(find(strcmp(ermaDetsChecked.truePm, '?'))));

fprintf(1, ['%i true Pm detections as encounters. ', ...
	'Median (IQR) duration: %.2f (%.2f) minutes\n'], ...
	height(ermaDetsTrueEnc), median(ermaDetsTrueEnc.duration_min), ...
	iqr(ermaDetsTrueEnc.duration_min));



%% (2) Get locations of each event

% load previously created locCalcT
load(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.gmStr '_locCalcT.mat']));
% find calculated location for midpoint of event
	tlm.midTime = tlm.start + (tlm.stop - tlm.start)/2;
for f = 1:height(tlm)
	[~, mIdx] = min(abs(locCalcT.dateTime - tlm.midTime(f)));
	tlm.lat(f) = locCalcT.latitude(mIdx);
	tlm.lon(f) = locCalcT.longitude(mIdx); 
end
% save this 
save(fullfile(CONFIG.path.analysis, 'cetaceanEvents', ...
	[CONFIG.gmStr '_log_merged_wLocations.mat']), 'tlm');

% OR load if previously processed
load(fullfile(CONFIG.path.analysis, 'cetaceanEvents', ...
	[CONFIG.gmStr '_log_merged_wLocations.mat']));

%% (3) Create encounter map

% set some colors
col_pt = [1 1 1];       % planned track
col_rt = [0 0 0];       % realized track
% col_ce = [1 0.4 0];     % cetacean events - orange
col_ce = [1 1 0.2];     % cetacean events - yellow

% generate the basemap with bathymetry as figure 82, don't save .fig file
[baseFig] = createBasemap(CONFIG, 1, 82); % with bathymetry
[baseFig] = createBasemap(CONFIG, false, 82);

baseFig.Position = [20    80    1200    700];

% add original targets
targetsFile = fullfile(CONFIG.path.mission, 'basestationFiles', 'targets');
[targets, ~] = readTargetsFile(CONFIG, targetsFile); 

h(1) = plotm(targets.lat, targets.lon, 'Marker', 's', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_pt, 'Color', col_pt, ...
	'DisplayName', 'planned track');
% textm(targets.lat, targets.lon, targets.name, 'FontSize', 10)

% plot realized track
% load surface positions
load(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.gmStr '_gpsSurfaceTable.mat']));
h(2) = plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, ...
	'Color', col_rt, 'LineWidth', 1.5, 'DisplayName', 'realized track');

% plot acoustic events
h(3) = scatterm(tlm.lat, tlm.lon, 30, 'Marker', 'o', ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_ce, ...
	'DisplayName', 'cetacean event');

% add legend
legend(h,  'Location', 'eastoutside', 'FontSize', 14)

% add title
title(sprintf('%s %s', upper(CONFIG.glider), CONFIG.mission), ...
	'Interpreter', 'none');

% save 
saveName = fullfile(CONFIG.path.analysis, 'cetaceanEvents', ...
	['map_tritonEvents_' CONFIG.gmStr]);
set(baseFig,'renderer','Painters');
exportgraphics(baseFig, [saveName,'.jpg'], 'Resolution', 300);
exportgraphics(baseFig, [saveName, '.pdf'])
% with export_fig from FEX, can export as vector (with lower res bathy)
% export_fig([saveName '_ef_painters.pdf'], '-pdf', '-painters');
