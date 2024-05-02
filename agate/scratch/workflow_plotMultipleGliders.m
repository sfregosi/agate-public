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

%% Glider 1 - SG639

% add original targets
targetsFile = fullfile(CONFIG.path.mission, 'basestationFiles', 'targets');
[targets, ~] = readTargetsFile(CONFIG, targetsFile);

h(1) = plotm(targets.lat, targets.lon, 'Marker', 's', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_pt, 'Color', col_pt, ...
	'HandleVisibility', 'off');
% textm(targets.lat, targets.lon, targets.name, 'FontSize', 10)

% plot realized track
% load surface positions
load(fullfile(CONFIG.path.mission, 'profiles', 'sg639_MHI_Apr2022_gpsSurfaceTable.mat'));
h(2) = plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, ...
	'Color', col_rt, 'LineWidth', 1.5, 'HandleVisibility', 'off');

% acoustic events
tl = readtable('C:\Users\Selene.Fregosi\Documents\GitHub\glider-MHI\analysis\fkw_classification\sg639_MHI_Apr2022_PcOnlyForTempMapping.csv');

% load previously created locCalcT
load(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.gmStr '_locCalcT.mat']));
% find calculated location for midpoint of event
tl.midTime = tl.start + (tl.stop - tl.start)/2;
for f = 1:height(tl)
	[~, mIdx] = min(abs(locCalcT.dateTime - tl.midTime(f)));
	tl.lat(f) = locCalcT.latitude(mIdx);
	tl.lon(f) = locCalcT.longitude(mIdx);
end

% plot acoustic events
h(3) = scatterm(tl.lat, tl.lon, 80, 'Marker', 'o', ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_ce, ...
	'DisplayName', 'acoustic event (SG639)');

%% (4) Add second glider to plot

col_ce_g2 = [1 0.4 0];     % cetacean events - orange

% targets
targetsFile_g2 = 'T:\glider_MHI_spring_2022\sg680_MHI_Apr2022\piloting\basestationFiles\targets';
[targets_g2 ,~] = readTargetsFile(CONFIG, targetsFile_g2);

h(4) = plotm(targets_g2.lat, targets_g2.lon, 'Marker', 's', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_pt, 'Color', col_pt, ...
	'HandleVisibility', 'off');

% realized track
gpsSurfT_g2 = load(fullfile('T:\glider_MHI_spring_2022\sg680_MHI_Apr2022\piloting\profiles\sg680_MHI_Apr2022_gpsSurfaceTable.mat'));
gpsSurfT_g2 = gpsSurfT_g2.gpsSurfT;
h(5) = plotm(gpsSurfT_g2.startLatitude, gpsSurfT_g2.startLongitude, ...
	'Color', col_rt, 'LineWidth', 1.5, 'HandleVisibility', 'off');

% plot acoustic events
tl_g2 = readtable('C:\Users\Selene.Fregosi\Documents\GitHub\glider-MHI\analysis\fkw_classification\sg680_MHI_Apr2022_PcOnlyForTempMapping.csv');

% load previously created locCalcT
locCalcT_g2 = load(fullfile('T:\glider_MHI_spring_2022\sg680_MHI_Apr2022\piloting\profiles\sg680_MHI_Apr2022_locCalcT.mat'));
locCalcT_g2 = locCalcT_g2.locCalcT;
% find calculated location for midpoint of event
tl_g2.midTime = tl_g2.start + (tl_g2.stop - tl_g2.start)/2;
for f = 1:height(tl_g2)
	[~, mIdx] = min(abs(locCalcT_g2.dateTime - tl_g2.midTime(f)));
	tl_g2.lat(f) = locCalcT_g2.latitude(mIdx);
	tl_g2.lon(f) = locCalcT_g2.longitude(mIdx);
end

h(6) = scatterm(tl_g2.lat, tl_g2.lon, 80, 'Marker', 'o', ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', col_ce_g2, ...
	'DisplayName', 'acoustic event (SG680)');


% add legend
legend(h([3,6]),  'Location', 'eastoutside', 'FontSize', 14)

% add title
title('False killer whale detections - Spring 2022', 'Interpreter', 'none')

