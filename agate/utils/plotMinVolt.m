function plotMinVolt(CONFIG, pp)
% PLOTMINVOLT	Plot minimum reported battery voltage(s) over time
%
%	Syntax:
%		PLOTMINVOLT(CONFIG, PP)
%
%	Description:
%		Plot of minimum battery voltage(s) reported on each dive, over
%       time.
%       For Rev B gliders, both 10V and 24V battery voltage is
%       plotted, even if it's a 2-15V glider.
%		For Rev E gliders, a single voltage is reported and plotted
%
%	Inputs:
%		CONFIG      Mission/agate global configuration variable
%       pp          Piloting parameters table created with
%                   extractPilotingParams.m
%
%	Outputs:
%		no output, creates figure
%
%	Examples:
%
%	See also
%       extractPilotingParams
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	23 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figNum = CONFIG.figNumList(6);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
plot(timeDays, pp.minVolt_24, 'LineWidth', 2)
hold on
plot(timeDays, pp.minVolt_10, 'LineWidth', 2)
ylim([8 15]);ylabel('minimum voltage [V]');
xlim([0 max(timeDays)+5]); xlabel('days in mission');

co = colororder;
% pull specified voltage lims from most recent dive
logFileList = dir(fullfile(CONFIG.path.bsLocal, ['p' CONFIG.glider(3:end) '*.log']));
x = fileread(fullfile(CONFIG.path.bsLocal, logFileList(end).name));

idx = strfind(x, '$MINV_24V');
sl = length('$MINV_24V');
idxBreak =  regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
val = str2num(x(idx+sl+1:idxBreak-1));
yline(val, '--', '$MINV\_24V', 'Color', co(1,:));

idx = strfind(x, '$MINV_10V');
sl = length('$MINV_10V');
idxBreak =  regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
val = str2num(x(idx+sl+1:idxBreak-1));
yline(val, '--', '$MINV\_10V', 'Color', co(2,:));

% finalize fig
grid on;
hold off;

title(['Glider ' CONFIG.glider ' Minimum Battery Voltages']);
set(gca, 'FontSize', 14)
legend('24V', '10V')
set(gcf, 'Position', [800   40    600    400])

end
