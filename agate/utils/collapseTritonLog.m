function [tl, tlm] = collapseTritonLog(logFile, eventGap)
%COLLAPSETRITONLOG	Collapse a Triton log to have one entry per event
%
%   Syntax:
%       TL = COLLAPSETRITONLOG(FULLFILENAME)
%
%   Description:
%       Collapse/clean up a Triton log so there is just a single line/entry
%       per odontocete event. It merges duplicate lines where multiple
%       sound types are noted (e.g., clicks and whistles in a single UO
%       event) but they are from a single dated 'EventNumber'. Optional
%       argument to combine any events that occur within 'eventGap' mins
%       of one another. This merging by time is an optional argument by
%       setting 'eventGap' to 0 or leave out.
%
%   Inputs:
%       logFile    [string] fullpath filename to log to be processed. If no
%                  file is specified (no arguments) or is empty, or is
%                  incorrect, will prompt to select
%       eventGap   [integer] optional argument to combine events with the
%                  same species ID code that are separated by less than the
%                  integer specified by eventGap
%
%   Outputs:
%       tl         table as a compressed triton log
%
%   Examples:
%       tl = collapseTritonLog('E:\sg639_MHI_log_mw.xlsx', 15);
%
%   See also
%
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion:   15 February 2023
%	Updated:        13 March 2024
%
%	Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
	eventGap = 0;
end

if nargin < 1
	logFile = [];
end

% agate CONFIG is not required, but if it is present, it will be used in
% file search path if needed
if ismember('CONFIG', who('global'))
	global CONFIG
	searchPath = CONFIG.path.mission;
else
	searchPath = cd;
end
% check file exists and if not prompt to select
if ~exist(logFile, 'file')
	[file, path] = uigetfile(fullfile(searchPath, '*.xlsx;*.xls'), ...
		'Select Triton log file');
	logFile = fullfile(path, file);
end

% read in raw triton log xls
t = readtable(logFile);
% make sure sorted by start time
t = sortrows(t, 'StartTime');

% clean up EventNumber dates (these can vary depending on how the xls was
% saved/opened/viewed during the logging process)
t.EventNumber = dateshift(t.EventNumber, 'start', 'second');
% this can still end up with single events listed as 1 sec apart
for f = 1:height(t)-1
	diff = t.EventNumber(f+1) - t.EventNumber(f);
	if diff <= seconds(1) && diff > seconds(0)
		t.EventNumber(f+1) = t.EventNumber(f);
	end
end

% get unique species codes
uSp = unique(t.SpeciesCode);
% unique call types
uCall = unique(t.Call);
% unique combo of both
spCallOnly = t(:,3:4);
uSpCall = unique(t(:,3:4), 'rows');

% simple collapse based on unique datetime values in EventNumber
[uEN, uIdx, ic] = unique(t.EventNumber, 'stable');
tl = table;
tl.eventNum = [1:length(uEN)]';
tl.start = t.StartTime(uIdx);
tl.stop = t.EndTime(uIdx);
tl.species = t.SpeciesCode(uIdx);
tl.call = cell(height(tl),1);
tl.eventDT = uEN;

for f = 1:height(tl)
	tl.call{f} = t.Call(ic == f);
end

fprintf(1, ['Before event merging: %i unique species, %i unique call types,' ...
	' %i unique events\n'], length(uSp), length(uCall), height(tl))

% merge by eventGap if non-zero
tlt = tl; % make a copy to modify in the below loop
tlm = table;
tlmIdx = 1;
if eventGap > 0
	while tlmIdx <= height(tlt)
		% set up extended event start and stop times
		startPlus = tlt.start(tlmIdx) - minutes(eventGap);
		stopPlus = tlt.stop(tlmIdx) + minutes(eventGap);
		% check if any rows overlap with this extended event time
		startYes = find(isbetween(tlt.start, startPlus, stopPlus));
		startYes = startYes(startYes ~= tlmIdx); % ignore actual event
		stopYes = find(isbetween(tlt.stop, startPlus, stopPlus));
		stopYes = stopYes(stopYes ~= tlmIdx); % ignore actual event


		% do stuff depending on outcome

		% classify overlap type for processing below

		% simple - no matches
		if isempty(startYes) && isempty(stopYes)
			% check that its not completly within a
			type = 'simple';

			% some matches to deal with
		elseif ~isempty(startYes) || ~isempty(stopYes)

			if ~isempty(startYes) && isempty(stopYes)
				type = 'startOverlap';
				% just first one (in case multiple matches)
				yesIdx = startYes(1);

			elseif isempty(startYes) && ~isempty(stopYes)
				type = 'stopOverlap';
				% just first one (in case multiple matches)
				yesIdx = stopYes(1);

				% both contain overlaps
			elseif ~isempty(startYes) && ~isempty(stopYes)
				% find the smallest overlap comparison
				startMin = min(startYes);
				stopMin = min(stopYes);

				% see if any are completely within the test event by
				% any start and stop pairs
				% 				if any(find(startYes == stopYes))
				if (startMin == stopMin)
					type = 'within';
					yesIdx = startMin;
					% 					% find the tlt index of the 'within' event
					% 					fIdx = find(startYes == stopYes, 1, 'first');
					% 					if length(fIdx) > 1
					% 						fprintf('New situation. See eventNums %i. Will pause\n', ...
					% 							tlt.eventNum(fIdx));
					% 						pause;
					% 					end
					% get the yesIdx from whichever is longer
					% 					if length(startYes) >= length(stopYes)
					% 						yesIdx = startYes(fIdx);
					% 					elseif length(stopYes) > length(startYes)
					% 						yesIdx = stopYes(fIdx);
					% 					end

				else % no identical matches
					type = 'bothOverlap';
					% 					% find the smallest overlap comparison
					% 					startMin = min(startYes);
					% 					stopMin = min(stopYes);
					% 					if length(startYes) == 1 && length(stopYes) == 1
					% find which is smaller and start with that one
					if startMin < stopMin
						type = 'startOverlap';
						yesIdx = min(startYes);
					elseif stopMin < startMin
						type = 'stopOverlap';
						yesIdx = min(stopYes);
					end
					fprintf(1, 'Multiple overlaps, starting with earlier one, %i, %s\n', ...
						min([startYes; stopYes]), type);
					% 					else
					% 						fprintf(1, 'New situation. See eventNums %i. Will pause\n', ...
					% 							unique([startYes; stopYes]));
					% 						pause;
					% 					end
				end % bothOverlap, check for 'within'
			end
		end % end simple vs some matches check


		% operate on the type
		if strcmp(type, 'simple')
			% just copy this entry to output
			tlm(tlmIdx,:) = tlt(tlmIdx, :);
			advance = true;

		elseif strcmp(type, 'startOverlap')
			% start stuff
			% copy this entry to tlm
			tlm(tlmIdx,:) = tlt(tlmIdx, :);
			% check where the overlap happens
			if tlt.start(yesIdx) > tlm.stop(tlmIdx)
				% next entry starts before end of this entry
				% so replace end time with end time of next entry
				tlm.stop(tlmIdx) = tlt.stop(yesIdx);
				tlm.call{tlmIdx} = unique([tlt.call{tlmIdx}(:);
					tlt.call{yesIdx}(:)]);
			end
			% remove the overlapping entry
			tlt(yesIdx,:) = [];
			% update tlt to match tlm
			tlt(tlmIdx,:) = tlm(tlmIdx,:);
			% 			advance = true; % advance, unless multi match below

		elseif strcmp(type, 'stopOverlap')
			% stop stuff
			% don't need to recopy the test entry, going to modify existing

			if yesIdx < tlmIdx && tlm.stop(yesIdx) < tlt.stop(tlmIdx)
				% match is previous entry AND previous entry ends before
				% start or within buffer so update previous stop time
				tlm.stop(yesIdx) = tlt.stop(tlmIdx);
				tlm.call{yesIdx} = unique([tlt.call{yesIdx}(:);
					tlt.call{tlmIdx}(:)]);
			elseif yesIdx < tlmIdx && tlm.stop(yesIdx) >= tlt.stop(tlmIdx)
				% match is previous entry AND previous entry ends AFTER so
				% this becomes 'within' and just update call type
				tlm.call{yesIdx} = unique([tlt.call{yesIdx}(:);
					tlt.call{tlmIdx}(:)]);
			else
				fprintf('New situation. See eventNum %i. Will pause\n', ...
					tlt.eventNum(yesIdx));
				pause;
			end
			tlt(tlmIdx,:) = [];
			tlt(yesIdx,:) = tlm(yesIdx,:);
			advance = false; % never advance


		elseif strcmp(type, 'within')
			% copy the test entry to tlm
			tlm(tlmIdx,:) = tlt(tlmIdx, :);
			% double check that 'within'doesn't start or end within
			% buffer (rather than actual entry). If it does, update
			if tlt.start(yesIdx) < tlm.start(tlmIdx)
				tlm.start(tlmIdx) = tlt.start(yesIdx);
			end
			if tlt.stop(yesIdx) > tlm.stop(tlmIdx)
				tlm.stop(tlmIdx) = tlt.stop(yesIdx);
			end
			% update call types if needed
			tlm.call{tlmIdx} = unique([tlt.call{tlmIdx}(:);
				tlt.call{yesIdx}(:)]);
			% remove the nested entry
			tlt(yesIdx,:) = [];
			% update tlt to match tlm
			tlt(tlmIdx,:) = tlm(tlmIdx,:);
			% 			advance = true; % advance, unless multi match below

		elseif strcmp(type, 'bothOverlap')
			fprintf('Type: bothOverlap...need to resolve. Will pause\n');
			pause;

		end % process depending on type

		% if length > 1, change advance to false
		if length(startYes) > 1 || length(stopYes) > 1
			advance = false;
		end
		if length(unique([startYes; stopYes])) > 1
			advance = false;
		end

		if advance == true
			tlmIdx = tlmIdx + 1;
		elseif advance == false
			fprintf(1, 'reassessing eventNum %i...\n', tlmIdx);
		end

	end % while event rows exist

end % if eventGap > 0


fprintf(1, ['Events merged within %i minutes: %i unique species, ' ...
	'%i unique call types, %i unique events\n'], ...
	eventGap, length(uSp), length(uCall), height(tlm))

end % function end



