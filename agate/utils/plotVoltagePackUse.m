function plotVoltagePackUse(CONFIG, pp)
%PLOTVOLTAGEPACKUSE	Plot power draw by individual glider devices
%
%   Syntax:
%       PLOTVOLTAGEPACKUSE(CONFIG, pp)
%
%   Description:
%       Plot power draw by different devices, each separately. Includes
%       VBD, pitch, and roll motors and PMAR. Power draw is on a by dive
%       basis (not normalized by dive duration) but is plotted over time
%       (days into mission)
%
%   Inputs:
%       CONFIG      Mission/agate global configuration variable
%       pp          Piloting parameters table created with
%                   extractPilotingParams.m
%
%   Outputs:
%       no output, creates figure
%
%   Examples:
%        plotVoltagePackUse(CONFIG, pp639)
%
%   See also EXTRACTPILOTINGPARAMS, PLOTVOLTAGEPACKUSE_NORM
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   unknown
%   Updated:        4 May 2023
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figNum = CONFIG.plots.figNumList(4);
% set position
figPosition = [600    40    600    400];
% overwrite if in config
if isfield(CONFIG.plots, 'positions')
	% is a position defined for this figure
	fnIdx = find(figNum == CONFIG.plots.figNumList);
	if length(CONFIG.plots.positions) >= fnIdx && ~isempty(CONFIG.plots.positions{fnIdx})
		figPosition = CONFIG.plots.positions{fnIdx};
	end
end

figure(figNum); 
set(gcf, 'Name', 'Power Draw by Device');
clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
plot(timeDays, pp.pkJ, 'LineWidth', 2);
hold on;
plot(timeDays, pp.rkJ, 'LineWidth', 2);
plot(timeDays, pp.vkJ, 'LineWidth', 2);

% add in pam info if present
if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
	plot(timeDays, pp.PMAR_kJ, 'LineWidth', 2);
	legendStrs = {'pitch', 'roll', 'vbd', 'pmar'};
end
if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
	plot(timeDays, pp.WS_kJ, 'LineWidth', 2);
	legendStrs = {'pitch', 'roll', 'vbd', 'wispr'};
end

ylim([0 max(pp.vkJ) + .1*max(pp.vkJ)]); ylabel('energy [kJ]');
xlim([0 max(timeDays)+5]); xlabel('days in mission');
grid on;
hold off;

title([CONFIG.glider ' Usage By Device']);
if (isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1) || ...
		(isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1)
	legend(legendStrs, 'Location', 'EastOutside')
else
	hleg = legend('pitch', 'roll', 'vbd', 'Location', 'EastOutside');
	title(hleg, 'motors');
end

set(gca, 'FontSize', 12)
set(gcf, 'Position', figPosition)

end

