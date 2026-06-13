function [summaryTable, curveTable] = calculate_hosting_capacity(strategies, paramsMap)
%CALCULATE_HOSTING_CAPACITY Evaluate stress-profile PV hosting capacity.
%
% Hosting capacity is the maximum PV penetration with no voltage violations
% over the stress profile and converged load flow at every time step.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(strategies)
    strategies = {'none', 'voltvar', 'voltwatt', 'hybrid', 'hybrid_pso'};
end
if nargin < 2, paramsMap = struct(); end

net = ieee33_data();
penetrations = [0 20 40 60 80 100 120 140 160 180 200 220 250];
loadProfile = create_stress_load_profile(1);
irrProfile = create_stress_irradiance_profile(1);
pvBuses = select_pv_buses('stress_end_buses');
weights = [0.8 0.9 1.0 1.0 1.1 1.2];

curveRows = {};
summaryRows = {};

for s = 1:numel(strategies)
    strategy = strategies{s};
    hosting = 0;
    for p = penetrations
        params = get_strategy_params(strategy, paramsMap);
        pv = apply_pv_penetration(net, p, pvBuses, weights);
        Vmin = inf;
        Vmax = -inf;
        violations = 0;
        curtailment = 0;
        losses = 0;
        converged = true;
        for t = 1:numel(loadProfile.time_h)
            r = apply_smart_inverter_control(net, pv, loadProfile.multiplier(t), ...
                irrProfile.irradiance(t), strategy, params);
            Vmin = min(Vmin, min(r.lf.Vmag));
            Vmax = max(Vmax, max(r.lf.Vmag));
            violations = violations + sum(r.lf.Vmag < net.Vmin | r.lf.Vmag > net.Vmax);
            curtailment = curtailment + sum(r.Pcurtailed_kW);
            losses = losses + r.lf.Ploss_kW;
            converged = converged && r.lf.converged;
        end
        feasible = converged && violations == 0 && Vmin >= net.Vmin && Vmax <= net.Vmax;
        if feasible
            hosting = p;
        end
        curveRows(end + 1, :) = {strategy, p, Vmin, Vmax, violations, ...
            curtailment, losses, converged, feasible}; %#ok<AGROW>
    end
    summaryRows(end + 1, :) = {strategy, hosting}; %#ok<AGROW>
end

curveTable = cell2table(curveRows, 'VariableNames', ...
    {'ControlStrategy', 'PVPenetrationPercent', 'MinVoltage', 'MaxVoltage', ...
    'VoltageViolationCount', 'PVCurtailment_kWh', 'TotalActiveLoss_kWh', ...
    'Converged', 'Feasible'});
summaryTable = cell2table(summaryRows, 'VariableNames', ...
    {'ControlStrategy', 'HostingCapacityPercent'});

writetable(curveTable, fullfile(projectRoot, 'results', 'tables', 'hosting_capacity_curve.csv'));
writetable(summaryTable, fullfile(projectRoot, 'results', 'tables', 'hosting_capacity_summary.csv'));
writetable(summaryTable, fullfile(projectRoot, 'results', 'tables', 'hosting_capacity.csv'));

plot_hosting_capacity_outputs(projectRoot, curveTable, summaryTable);
fprintf('Hosting capacity evaluation complete.\n');
end

function params = get_strategy_params(strategy, paramsMap)
params = default_control_params();
validName = matlab.lang.makeValidName(strategy);
if isfield(paramsMap, validName)
    params = paramsMap.(validName);
else
    bestFile = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'mat_files', 'best_params_v2.mat');
    if strcmp(strategy, 'hybrid_pso') && exist(bestFile, 'file')
        s = load(bestFile, 'bestParams');
        params = s.bestParams;
    end
end
end

function plot_hosting_capacity_outputs(projectRoot, curveTable, summaryTable)
figDir = fullfile(projectRoot, 'results', 'figures');

fig = figure('Color', 'w', 'Position', [100 100 850 480]);
bar(categorical(summaryTable.ControlStrategy), summaryTable.HostingCapacityPercent);
grid on;
ylabel('Hosting Capacity (% PV)');
xlabel('Control Strategy');
title('PV Hosting Capacity Under Stress Profile');
exportgraphics(fig, fullfile(figDir, 'hosting_capacity_comparison.png'), 'Resolution', 220);
savefig(fig, fullfile(figDir, 'hosting_capacity_comparison.fig'));
close(fig);

fig = figure('Color', 'w', 'Position', [100 100 900 520]);
hold on; grid on;
strategies = unique(curveTable.ControlStrategy, 'stable');
for i = 1:numel(strategies)
    idx = strcmp(curveTable.ControlStrategy, strategies{i});
    plot(curveTable.PVPenetrationPercent(idx), curveTable.MaxVoltage(idx), '-o', ...
        'LineWidth', 1.6, 'DisplayName', strategies{i});
end
yline(1.05, '--r', 'Vmax');
xlabel('PV Penetration (%)');
ylabel('Maximum Voltage (p.u.)');
title('Maximum Voltage vs PV Penetration');
legend('Location', 'best');
exportgraphics(fig, fullfile(figDir, 'max_voltage_vs_pv_penetration.png'), 'Resolution', 220);
savefig(fig, fullfile(figDir, 'max_voltage_vs_pv_penetration.fig'));
close(fig);

fig = figure('Color', 'w', 'Position', [100 100 900 520]);
hold on; grid on;
for i = 1:numel(strategies)
    idx = strcmp(curveTable.ControlStrategy, strategies{i});
    plot(curveTable.PVPenetrationPercent(idx), curveTable.VoltageViolationCount(idx), '-o', ...
        'LineWidth', 1.6, 'DisplayName', strategies{i});
end
xlabel('PV Penetration (%)');
ylabel('Voltage Violation Count');
title('Voltage Violations vs PV Penetration');
legend('Location', 'best');
exportgraphics(fig, fullfile(figDir, 'violations_vs_pv_penetration.png'), 'Resolution', 220);
savefig(fig, fullfile(figDir, 'violations_vs_pv_penetration.fig'));
close(fig);
end
