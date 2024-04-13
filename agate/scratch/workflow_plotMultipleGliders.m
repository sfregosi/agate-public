% WORKFLOW_PLOTMULTIPLEGLIDERS.M
%	One-line description here, please
%
%	Description:
%		Detailed description here, please
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	14 March 2024
%	Updated:
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (3) Create encounter map

% set some colors
col_pt = [1 1 1];       % planned track
col_rt = [0 0 0];       % realized track
% col_ce = [1 0.4 0];     % cetacean events - orange
col_ce = [1 1 0.2];     % cetacean events - yellow

% generate the basemap with bathymetry as figure 82, don't save .fig file
[baseFig] = createBasemap(CONFIG, 1, 82); 
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
load(fullfile(CONFIG.path.mission, 'profiles', 'sg679_MHI_May2023_gpsSurfaceTable.mat'));
h(2) = plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, ...
	'Color', col_rt, 'LineWidth', 1.5, 'DisplayName', 'realized track');

% plot acoustic events
h(3) = scatterm(tlm.lat, tlm.lon, 30, 'Marker', 'o', ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_ce, ...
	'DisplayName', 'cetacean event');

% add legend
legend(h,  'Location', 'eastoutside', 'FontSize', 14)

% add title
title('SG679 MHI May 2023', 'Interpreter', 'none')

%% (4) Add second glider to plot

col_ce_sg639 = [1 0.4 0];     % cetacean events - orange

% targets
targetsFile_sg639 = 'D:\sg639_MHI_Apr2023\piloting\basestationFiles\targets';
[targets_sg639 ,~] = readTargetsFile(CONFIG, targetsFile_sg639); 

h(4) = plotm(targets_sg639.lat, targets_sg639.lon, 'Marker', 's', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_pt, 'Color', col_pt, ...
	'HandleVisibility', 'off');

% realized track
loadTmp = load(fullfile('D:\sg639_MHI_Apr2023\piloting\profiles\sg639_MHI_Apr2023_gpsSurfaceTable.mat'));
gpsSurfT_sg639 = loadTmp.gpsSurfT;
h(5) = plotm(gpsSurfT_sg639.startLatitude, gpsSurfT_sg639.startLongitude, ...
	'Color', col_rt, 'LineWidth', 1.5, 'DisplayName', 'realized track');

% plot acoustic events
h(6) = scatterm(tlm.lat, tlm.lon, 30, 'Marker', 'o', ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_ce, ...
	'DisplayName', 'cetacean event');


% add legend
legend(h,  'Location', 'eastoutside', 'FontSize', 14)

% add title
title('SG679 MHI May 2023', 'Interpreter', 'none')

