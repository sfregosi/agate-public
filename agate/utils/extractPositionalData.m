function [gpsSurfT, locCalcT] = extractPositionalData(CONFIG, plotOn)
%EXTRACTPOSITIONALDATA	Extracts glider location data from nc files
%
%   Syntax:
%	    [gpsSurfT, locCalcT] = EXTRACTPOSITIONALDATA(CONFIG, plotOn)
%
%   Description:
%	    Extracts glider positional data from basestation-generated .nc
%	    files and compiles into two tables, one with just GPS/surface
%	    locations and one with dead-reckoned locations underwater. Also
%	    includes various metrics related to speed and currents
%
%   Inputs:
%       CONFIG    agate mission configuration file with relevant mission and
%                 glider information. Minimum CONFIG fields are 'glider',
%                 'mission', 'path.mission'
%       plotOn    optional argument to plot basic maps of outputs for
%                 checking; (1) to plot, (0) to not plot
%
%   Outputs:
%       gpsSurfT  Table with glider surface locations, from GPS, one per
%                 dive, and includes columns for dive start and end
%                 time/lat/lon, dive duration, depth average current,
%                 average speed over ground as northing and easting,
%                 calculated by the hydrodynamic model or the glide slope
%                 model
%       locCalcT  Table with glider calculated locations underwater every
%                 science file sampling interval. This gives more
%                 instantaneous flight details and includes columns
%                 for time, lat, lon from hydrodynamic and glide slope
%                 models, displacement from both models, temperature,
%                 salinity, density, sound speed, glider vertical and
%                 horizontal speed (from both models), pitch, glide
%                 angle, and heading
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%    FirstVersion:   03 September 2019
%    Updated:        12 April 2024
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Surface locations - extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));
lf = length(files);

% use number of files (number of dives) to preallocate
% sometimes odd abort behaviors mess this up, but NaNs will fill in
surfNames = {'dive', 'startTime', 'startDateTime', 'startLatitude', ...
	'startLongitude', 'endTime', 'endDateTime', 'endLatitude', 'endLongitude', ...
	'duration_hr', 'distance_km', 'maxDepth_m', 'dac_n', 'dac_e', ...
	'dac_n_gsm', 'dac_e_gsm', 'dac_qc', 'avg_speed_n', 'avg_speed_e', ...
	'avg_speed_n_gsm', 'avg_speed_e_gsm', 'hdm_qc'};

gpsSurfT = array2table(NaN(lf, length(surfNames)));
gpsSurfT.Properties.VariableNames = surfNames;
gpsSurfT.startDateTime = datetime(gpsSurfT.startDateTime, 'ConvertFrom', 'datenum');
gpsSurfT.endDateTime = datetime(gpsSurfT.endDateTime, 'ConvertFrom', 'datenum');

% loop through each file/dive
for f = 1:length(files)
	fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
	[~, fname_name, fname_ext] = fileparts(fname);
	% ncdisp(fname,'/','min');
	try
		latgps = ncread(fname,'log_gps_lat');
		longps = ncread(fname,'log_gps_lon');
		timegps = ncread(fname,'log_gps_time');

		gpsSurfT.dive(f)			= f;
		gpsSurfT.startTime(f)		= unix2matlab(timegps(2));
		gpsSurfT.startDateTime(f)	= datetime(gpsSurfT.startTime(f), ...
										'ConvertFrom','datenum');
		gpsSurfT.startLatitude(f)	= latgps(2);
		gpsSurfT.startLongitude(f)	= longps(2);
		gpsSurfT.endTime(f)			= unix2matlab(timegps(3));
		gpsSurfT.endDateTime(f)		= datetime(gpsSurfT.endTime(f), ...
										'ConvertFrom','datenum');
		gpsSurfT.endLatitude(f)		= latgps(3);
		gpsSurfT.endLongitude(f)	= longps(3);
		gpsSurfT.duration_hr(f)		= hours(gpsSurfT.endDateTime(f) - ...
										gpsSurfT.startDateTime(f));
		gpsSurfT.distance_km(f)		= lldistkm([latgps(2) longps(2)], ...
										[latgps(3) longps(3)]);
		gpsSurfT.maxDepth_m(f)		= max(ncread(fname, 'depth'));
		gpsSurfT.dac_n(f)			= ncread(fname,'depth_avg_curr_north');
		gpsSurfT.dac_e(f)			= ncread(fname,'depth_avg_curr_east');
		gpsSurfT.dac_qc(f)			= str2double(ncread(fname,'depth_avg_curr_qc'));
		gpsSurfT.dac_n_gsm(f)		= ncread(fname,'depth_avg_curr_north_gsm');
		gpsSurfT.dac_e_gsm(f)		= ncread(fname,'depth_avg_curr_east_gsm');
		gpsSurfT.avg_speed_n(f)		= ncread(fname,'flight_avg_speed_north');
		gpsSurfT.avg_speed_e(f)		= ncread(fname,'flight_avg_speed_east');
		gpsSurfT.avg_speed_n_gsm(f)	= ncread(fname,'flight_avg_speed_north_gsm');
		gpsSurfT.avg_speed_e_gsm(f)	= ncread(fname,'flight_avg_speed_east_gsm');
		gpsSurfT.hdm_qc(f)			= str2double(ncread(fname,'hdm_qc'));
	catch
				fprintf(1, 'Problem loading %s. Skipped.\n', [fname_name fname_ext])
	end
end

% optional check by plotting
if plotOn
	figure
	plot(gpsSurfT.startLongitude,gpsSurfT.startLatitude,'.k');
	text(gpsSurfT.startLongitude+0.002,gpsSurfT.startLatitude+0.002, ...
		num2str(gpsSurfT.dive));
end


% Sample locations - extracted from individual nc files

% guesstimate size for preallocation
% 6 hr dives with 10 sec sampling interval (6 samples per min) == 2160 samples per dive
initSize = 2160*lf;

% set up output table
calcNames = {'dive', 'time', 'dateTime', 'latitude', 'longitude', ...
	'latitude_gsm', 'longitude_gsm', 'north_displacement', 'east_displacement', ...
	'north_displacement_gsm', 'east_displacement_gsm', 'depth', 'temperature', ...
	'salinity', 'soundVelocity', 'density', 'vertSpeed', 'horzSpeed', 'speed', ...
	'speed_qc', 'vertSpeed_gsm', 'horzSpeed_gsm', 'speed_gsm', 'pitch', ...
	'glideAngle', 'glideAngle_gsm', 'heading'};

locCalcT = array2table(NaN(initSize, length(calcNames)));
locCalcT.Properties.VariableNames = calcNames;
locCalcT.dateTime = datetime(locCalcT.dateTime, 'ConvertFrom', 'datenum');

% loop through all files
lastIdx = 0;
spaceCheck = false;
for f = 1:length(files)
			fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
		[~, fname_name, fname_ext] = fileparts(fname);
	try
		%how many data points
		finfo = ncinfo(fname);
		dimMatch = strcmp({finfo.Dimensions.Name}, 'sg_data_point');
		samples = finfo.Dimensions(dimMatch).Length;
		sampIdx = lastIdx + 1:lastIdx + samples;
		% check for sufficient space - if not enough, pre-allocate more
		if sampIdx(end) > height(locCalcT) && spaceCheck == false
			fprintf(1, 'FYI More rows were needed!!\n')
			spaceCheck = true; % only print that once...
		end

		% assign values
		locCalcT.dive(sampIdx)					= repmat(f, samples, 1);
		locCalcT.time(sampIdx)					= unix2matlab(ncread(fname, 'time'));
		locCalcT.latitude(sampIdx)				= ncread(fname, 'latitude');
		locCalcT.longitude(sampIdx)				= ncread(fname, 'longitude');
		locCalcT.latitude_gsm(sampIdx)			= ncread(fname, 'latitude_gsm');
		locCalcT.longitude_gsm(sampIdx)			= ncread(fname, 'longitude_gsm');
		locCalcT.north_displacement(sampIdx)	= ncread(fname, 'north_displacement');
		locCalcT.east_displacement(sampIdx)		= ncread(fname, 'east_displacement');
		locCalcT.north_displacement_gsm(sampIdx) = ncread(fname, 'north_displacement_gsm');
		locCalcT.east_displacement_gsm(sampIdx)	= ncread(fname, 'east_displacement_gsm');
		locCalcT.depth(sampIdx)					= ncread(fname, 'depth');
		locCalcT.temperature(sampIdx)			= ncread(fname, 'temperature');
		locCalcT.salinity(sampIdx)				= ncread(fname, 'salinity');
		locCalcT.soundVelocity(sampIdx)			= ncread(fname, 'sound_velocity');
		locCalcT.density(sampIdx)				= ncread(fname, 'density');
		locCalcT.vertSpeed(sampIdx)				= ncread(fname, 'vert_speed');
		locCalcT.horzSpeed(sampIdx)				= ncread(fname, 'horz_speed');
		locCalcT.speed(sampIdx)					= ncread(fname, 'speed');
		locCalcT.speed_qc(sampIdx)				= ncread(fname, 'speed_qc');
		locCalcT.vertSpeed_gsm(sampIdx)			= ncread(fname, 'vert_speed_gsm');
		locCalcT.horzSpeed_gsm(sampIdx)			= ncread(fname, 'horz_speed_gsm');
		locCalcT.speed_gsm(sampIdx)				= ncread(fname, 'speed_gsm');
		locCalcT.pitch(sampIdx)					= ncread(fname, 'eng_pitchAng');
		locCalcT.glideAngle(sampIdx)			= ncread(fname, 'glide_angle');
		locCalcT.glideAngle_gsm(sampIdx)		= ncread(fname, 'glide_angle_gsm');
		locCalcT.heading(sampIdx)				= ncread(fname, 'eng_head');

		% move incrementally
		lastIdx = lastIdx + samples;
	catch
		fprintf(1, 'Problem loading %s. Skipped.\n', [fname_name fname_ext])
	end
end

% get dateTime from datenum
locCalcT.dateTime = datetime(locCalcT.time, 'ConvertFrom', 'datenum');
% remove extra NaNs from preallocation
locCalcT = locCalcT(1:lastIdx,:);

% check by plotting
if plotOn
	% dive profile
	figure;
	plot(locCalcT.time,-locCalcT.depth)
	title('dive profile');
	% compare hydro vs glide slope models
	figure;
	plot(locCalcT.longitude, locCalcT.latitude)
	hold on
	plot(locCalcT.longitude_gsm, locCalcT.latitude_gsm)
end

end

