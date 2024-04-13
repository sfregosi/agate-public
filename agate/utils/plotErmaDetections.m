function plotErmaDetections(CONFIG, path_bsLocal, divenum)
%plotErmaDetections	plot the WISPR detections from a Seaglider dive
%
%   Syntax:
%       plotErmaDetections(CONFIG, path_bsLocal, divenum)
%
%   Description:
%       Read in the ws****az file from a given dive and plot the data from it so
%       a person can look to see if the detections look like sperm whale clicks.
%       If divenum is NaN, plots data from known sperm whale encounters to you
%       can compare it to the data from another dive.
%
%       Assumes that the detection report for this dive is in the path_bsLocal
%       directory. NOTE: This ignores the ws****bz detection report because we
%       don't have that uploading correctly yet.
%
%   Inputs:
%       CONFIG         [struct] Mission/agate global configuration variable
%       path_bsLocal   [string] Directory where basestation files have been 
%                      downloaded to
%       divenum        [scalar] Dive number (or NaN) to plot click info for
%
%   Outputs: none (but creates/updates a figure)
%
%   Examples:
%       plotErmaDetections(CONFIG, path_bsLocal, 17)
%
%   See also readErmaReport.m
%
%   Authors:
%       D. Mellinger <David.Mellinger@oregonstate.edu> <https://github.com/DMellinger>
%
%   First Version:   09 May 2023
%   Updated:	     22 May 2023
%
%   Created with MATLAB ver. 9.13.0.2049777 (R2022b)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get CONFIG name incase it isn't exactly 'CONFIG'
cfgName = inputname(1);

% Check that this glider has WISPR, and has it enabled.
if (~isfield(CONFIG,'ws') || ~isfield(CONFIG.ws,'loggers') || ...
    CONFIG.ws.loggers == 0)
  return
end

% Read the ERMA detection report. First figure out the file name from the dive
% number, or if the number is NaN, a fixed filename in the utils directory.
if (~isnan(divenum))
  % Usual case: construct detection report file name from dive number.
  fname = sprintf('ws%04daz', divenum);
  ermaReportPath = fullfile(path_bsLocal, fname);
  plotTitle = sprintf('Dive %d (file %s)', divenum, fname);
  figTitle = 'ERMA click detection data';
  figureIndex = 8;
else
  % Special case: Use a fixed filename with known sperm whale detections.
  %ermaReportPath = 'c:/Dave/matlab_repo/ERMA_SpermWhale/exampleEncounters.csv';
  ermaReportPath = fullfile(CONFIG.path.utils, 'exampleSpermWhaleData.csv');
  plotTitle = 'Sperm whale click data: group (top) and solitary (bottom) animals';
  figTitle = 'Example sperm whale data for comparison';
  figureIndex = 9;
end
if (~exist(ermaReportPath, 'file'))
  msg = sprintf('There is no ERMA detection report for dive #%d', divenum);
  msgbox(msg, 'Last dive?', 'modal');
  return
end
dets = readErmaReport(ermaReportPath);

% Make a figure with ICIs on the left and histograms on the right. If the figure
% is new, make it sufficiently wide; if it already exists, leave as is.
preexisting = (any(get(0, 'Children') == CONFIG.plots.figNumList(figureIndex)));
figure(CONFIG.plots.figNumList(figureIndex))	% might create new figure
clf						% whether new or not, clear it
if (~preexisting)
  % If it's a newly-created figure, make it 800 pixels wide. Also, make the
  % comparison window sit 30 pixels offset from the existing one.
  posn = get(gcf, 'Position');			% units are pixels for new figs
  set(gcf, 'Position', [posn(1:2)+[30 -30]*isnan(divenum) 800 posn(4)]);
end

makeErmaPlots(dets, plotTitle, figTitle, divenum, cfgName)


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makeErmaPlots(dets, titl, figtitle, divenum, cfgName)
% Draw the ICI plots and histograms for this dive. 'divenum' may be NaN or
% omitted, in which case the buttons at the bottom aren't made.

nEnc = length(dets.enc);		% number of encounters
if (nEnc == 0)
  text(0.5, 0.5, ['No encounters found for dive ' num2str(divenum)], ...
    'Units', 'norm', 'Horiz', 'center', 'Vert', 'middle');
  set(gca, 'vis', 'off')
else
  % Plot each encounter.
  for i = 1 : nEnc
    % Get inter-click interval (ICI) data for this encounter.
    tS = dets.enc(i).t_D * (24*60*60);		% times of clicks in seconds
    ici = tS(2:end) - tS(1 : end-1);		% ICIs in seconds

    % Plot inter-click intervals.
    subplot(nEnc, 2, i*2 - 1)
    plot(tS(2:end) - tS(1), ici, '-', tS(2:end) - tS(1), ici, 'o');
    set(gca, 'YLim', [0 10]);
    if (i == ceil(nEnc/2)), ylabel('inter-click interval'); end
    if (i == 1), title(titl, 'Interp', 'none'); end
    if (i == nEnc), xlabel('time, s'); end

    % Plot histogram of inter-click intervals. ICIs less than 1 s are subdivided
    % into 0.1-s bins; the counts for these are multiplied by 10 to make them
    % comparable to ICIs greater than 1 s.
    subplot(nEnc, 2, i * 2)
    [N,edges] = histcounts(ici, [0:0.1:1 2:10]);
    histogram('BinEdges', edges, 'BinCounts', [N(1:10)*10  N(11:end)]);
    if (i == ceil(nEnc/2)), ylabel('normalized count'); end
    if (i == nEnc), xlabel('inter-click interval, s'); end
  end
end

set(gcf, 'NumberTitle', 'off', 'Name', figtitle)     % figure name in header bar

% Make Prev, Compare, and Next buttons.
if (nargin >= 3 && ~isnan(divenum))
  makeButton('← Prev',  divenum-1, -1.5, 'Show previous dive', cfgName);
  makeButton('Compare', NaN,       -0.5, 'Show comparison data from known whale encounters', cfgName);
  makeButton('Next →',  divenum+1, +0.5, 'Show next dive', cfgName);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Utility to add a button at the bottom of the plot.
function makeButton(str, divenumOrNan, hPosOffset, tip, cfgName)
w = 60;					% width of each button, pixels
set(gcf, 'units', 'pixel');
posn = get(gcf, 'Pos');
callback = sprintf('%s(%s, path_bsLocal, %d)', mfilename, cfgName, divenumOrNan);
uicontrol('Style', 'pushb', 'String', str, 'Tooltip', tip, ...
  'Position', [(posn(3)/2 + w*hPosOffset) 0 w 22], 'Callback', callback);
