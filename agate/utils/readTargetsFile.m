function [targets, targetsFile] = readTargetsFile(CONFIG, targetsFile)
%READTARGETSFILE Read in Seaglider formatted targets file
%
%   Syntax:
%       TARGETS = TREADTARGETSFILE(CONFIG, TARGETSFILE)
%
%   Description:
%       Read in a Seaglider formatted targets file to a table variable. 
%       Fullfile name can be specified as input argument, or can be left
%       blank to prompt to select targets file to read. 
%
%   Inputs:
%       CONFIG       global CONFIG variable from agate mission
%                    configuration file loaded with agate initialization
%       targetsFile  fullfile path and name to Seaglider formatted
%		             targets file to be read in Optional - if not specified
%		             will prompt to select correct file
%
%   Outputs:
%       targets      table with waypoint names, latitudes, and
%		             longitudes
%       targetsFile  fullfile pathname either input or selected
%
%   Examples:
%
%   See also MAKETARGETSFILE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   unkonwn
%   Updated:        14 March 2024
%
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
    [fileName, filePath] = uigetfile([CONFIG.path.mission, '\*.*'], ...
        'Select targets file to read');
    targetsFile = fullfile(filePath, fileName);
    fprintf('targets file selected: %s\n', fileName);
end

% check that is fullfile name
[path, ~, ~] = fileparts(targetsFile);
if isempty(path)
    fprintf(1, ['No filepath specified, re-enter targetsFile argument with '...
        'path included. Exiting\n']);
end

% read in file
x = fileread(targetsFile);

% skip comment lines
idx = regexp(x, '\/');
idxBreak = regexp(x(idx(end):end), '\n');
idxBreak = idxBreak + idx(end);

numTargets = length(idxBreak);

targets = table;

for t = 1:numTargets
    idxPeriod = regexp(x(idxBreak(t):end), '\.');
    idxLat = regexp(x(idxBreak(t):end), 'lat=', 'once');
    idxLon = regexp(x(idxBreak(t):end), 'lon=', 'once');
    idxRad = regexp(x(idxBreak(t):end), 'radius=', 'once');
    
    if ~isempty(idxLat)
        targets.name{t} = deblank(x(idxBreak(t):idxBreak(t) + idxLat - 2));
        targets.lat(t) = str2num(x(idxBreak(t) + idxLat + 3:idxPeriod(1) + idxBreak(t) - 4)) ...
            + str2num(deblank(x(idxPeriod(1) + idxBreak(t) - 3:idxBreak(t) + idxLon - 2)))/60;
        targets.lon(t) = str2num(x(idxLon + idxBreak(t) + 3:idxPeriod(2) + idxBreak(t) - 4)) ...
            - str2num(deblank(x(idxPeriod(2) + idxBreak(t) - 3:idxBreak(t) + idxRad - 2)))/60;
    end
end


end