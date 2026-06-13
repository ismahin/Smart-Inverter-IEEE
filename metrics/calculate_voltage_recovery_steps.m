function recovery = calculate_voltage_recovery_steps(time_h, Vseries, net, scenarioName, controlStrategy)
%CALCULATE_VOLTAGE_RECOVERY_STEPS Quasi-static voltage recovery indicator.
%
% This is not EMT transient response time. It counts time-series steps from
% a voltage-limit violation until all bus voltages return inside limits.

if nargin < 4, scenarioName = ""; end
if nargin < 5, controlStrategy = ""; end

inside = all(Vseries >= net.Vmin & Vseries <= net.Vmax, 2);
maxSteps = 0;
episodes = 0;
unrecovered = false;
k = 1;
while k <= numel(inside)
    if ~inside(k)
        episodes = episodes + 1;
        j = k;
        while j <= numel(inside) && ~inside(j)
            j = j + 1;
        end
        if j > numel(inside)
            unrecovered = true;
            maxSteps = NaN;
            break;
        end
        maxSteps = max(maxSteps, j - k);
        k = j;
    else
        k = k + 1;
    end
end
dt = median(diff(time_h(:)));
if isempty(dt) || isnan(dt), dt = 1; end

recovery = table(string(scenarioName), string(controlStrategy), episodes, maxSteps, ...
    maxSteps * dt, unrecovered, ...
    'VariableNames', {'Scenario', 'ControlStrategy', 'ViolationEpisodes', ...
    'QuasiStaticVoltageRecoverySteps', 'QuasiStaticVoltageRecoveryHours', 'Unrecovered'});
end
