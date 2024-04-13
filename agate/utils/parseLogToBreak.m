function val = parseLogToBreak(x, string)
%PARSELOGTOBREAK   Parse a value from the log from string to line break
%
%   Syntax:
%       val = PARSELOGTOBREAK(x, string)
%
%   Description:
%       Parse a value that is given after a log parameter, defined by a
%       string (e.g., '$TGT_NAME') and return the value given after the
%       string up until the next line break. Works for parameters that just
%       have a single value after the parameter string. Used within
%       extractPilotingParams and elsewhere
%
%   Inputs:
%       x       character string of log
%       string  log parameter to search for (e.g., '$D_TGT')
%
%   Outputs:
%       val     value of entry after log parameter (e.g., $D_TGT,100 would
%               return '100')
%
%   Examples:
%      val = parseLogToBreak(x, '$D_TGT');
%
%   See also EXTRACTPILOTINGPARAMS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   24 April 2023
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the string in the log character vector (read in with fileread)
idx = strfind(x, string);
sl = length(string);
% find the index of the next break
idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
% parse out the value
if ~isempty(idx) % in case it didn't find anything
    val = x(idx+sl+1:idxBreak-1); 
else
    val = nan;
end

end