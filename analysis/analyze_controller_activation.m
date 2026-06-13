function activationSummary = analyze_controller_activation()
%ANALYZE_CONTROLLER_ACTIVATION Summarize controller activity from logs.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
tableDir = fullfile(projectRoot, 'results', 'tables');
hyFile = fullfile(tableDir, 'hybrid_activation_log.csv');
vwFile = fullfile(tableDir, 'voltwatt_activation_log.csv');
assert(exist(hyFile, 'file') == 2, 'Missing hybrid_activation_log.csv.');

hy = readtable(hyFile);
if exist(vwFile, 'file') == 2
    vw = readtable(vwFile);
else
    vw = hy([]);
end
allLog = unique([hy; vw], 'rows');
groups = unique(allLog(:, {'ScenarioGroup', 'PVPenetrationPercent', 'IrradianceCondition', 'ControlStrategy'}), 'rows');
rows = {};
for i = 1:height(groups)
    idx = strcmp(allLog.ScenarioGroup, groups.ScenarioGroup{i}) ...
        & allLog.PVPenetrationPercent == groups.PVPenetrationPercent(i) ...
        & strcmp(allLog.IrradianceCondition, groups.IrradianceCondition{i}) ...
        & strcmp(allLog.ControlStrategy, groups.ControlStrategy{i});
    sub = allLog(idx, :);
    rows(end + 1, :) = {groups.ScenarioGroup{i}, groups.PVPenetrationPercent(i), ...
        groups.IrradianceCondition{i}, groups.ControlStrategy{i}, ...
        100 * mean(sub.VoltVARActive), 100 * mean(sub.VoltWattActive), ...
        100 * mean(sub.BothActive), sum(abs(sub.Qoutput_kVAr)), ...
        sum(sub.Pcurtailed_kW)}; %#ok<AGROW>
end

activationSummary = cell2table(rows, 'VariableNames', ...
    {'ScenarioGroup', 'PVPenetrationPercent', 'IrradianceCondition', 'ControlStrategy', ...
    'VoltVARActivePercent', 'VoltWattActivePercent', 'BothActivePercent', ...
    'TotalReactiveSupport_kVArh', 'TotalCurtailedPV_kWh'});
writetable(activationSummary, fullfile(tableDir, 'controller_activation_summary.csv'));
plot_activation_heatmap(projectRoot, activationSummary);
fprintf('Controller activation analysis complete.\n');
end

function plot_activation_heatmap(projectRoot, activationSummary)
stress = activationSummary(strcmp(activationSummary.ScenarioGroup, 'stress'), :);
if isempty(stress), stress = activationSummary; end
labels = strcat(stress.ControlStrategy, "_", string(stress.PVPenetrationPercent), "%");
data = [stress.VoltVARActivePercent stress.VoltWattActivePercent stress.BothActivePercent]';
fig = figure('Color', 'w', 'Position', [100 100 1100 420]);
imagesc(data);
colormap(parula);
colorbar;
yticks(1:3);
yticklabels({'Volt-VAR Active (%)', 'Volt-Watt Active (%)', 'Both Active (%)'});
xticks(1:numel(labels));
xticklabels(labels);
xtickangle(45);
title('Controller Activation Heatmap');
exportgraphics(fig, fullfile(projectRoot, 'results', 'figures', 'controller_activation_heatmap.png'), 'Resolution', 220);
savefig(fig, fullfile(projectRoot, 'results', 'figures', 'controller_activation_heatmap.fig'));
close(fig);
end
