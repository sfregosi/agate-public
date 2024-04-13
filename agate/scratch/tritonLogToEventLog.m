function tls = tritonLogToEventLog(CONFIG, tl)
% TRITONLOGTOEVENTLOG	Reformat Triton log table to a simplified event log
%
%   Syntax:
%       TLS = TRITONLOGTOEVENTLOG(CONFIG, tl)
%
%   Description:
%       Reformat a Triton log that has been collapsed, or just read in as 
%       a table (tl or tlm using collapseTritonLog) into a simplified event
%       log table that can be used in PAMpal and BANTER. It appends a
%       unique event ID to each event, that contains the glider's serial
%       (e.g., sg639) and then a sequential number in time. 
%
%   Inputs:
%       CONFIG  [struct] agate global mission configuration file
%       tl      [table] Triton log output from collapseTritonLog, or any
%               table with columns 'eventNum', 'start', 'stop'
%
%	Outputs:
%       tls     [table] simplified event table with columns 'start', 'end',
%               'sp', 'id'
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   14 March 2024
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% generate eventID string
eventStr = arrayfun(@(x) num2str(x, '%02.f'), tl.eventNum, 'UniformOutput', 0);
gc = cell(height(tl), 1);
gc(:) = {CONFIG.glider};
tl.eventID = cellfun(@(x,y) [x '_' y], gc, eventStr, 'UniformOutput', 0);

% build output table
tls = table;
tls.start = tl.start;
tls.end   = tl.stop;
tls.sp    = tl.species;
tls.id    = tl.eventID;
% tls = tl(:, [2 3 4 7]);
% tls.Properties.VariableNames = {'start', 'end', 'sp', 'id'};
tls.start.Format = 'MM/dd/uuuu HH:mm:ss';
tls.end.Format = 'MM/dd/uuuu HH:mm:ss';

end
