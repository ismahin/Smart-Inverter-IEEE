function generate_final_figures()
%GENERATE_FINAL_FIGURES Create required publication-style final figures.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
figDir = fullfile(projectRoot, 'results', 'figures');
fullData = load(fullfile(projectRoot, 'results', 'mat_files', 'full_results.mat'), 'allResults');
stressData = load(fullfile(projectRoot, 'results', 'mat_files', 'stress_results.mat'), 'stressResults');

plot_strategy_voltage_set(fullData.allResults, 'P80_partial_cloud', ...
    '80% PV Partial Cloud Voltage Comparison', ...
    fullfile(figDir, 'normal_voltage_comparison_80pv.png'));
plot_strategy_voltage_set(stressData.stressResults, 'Stress_P150', ...
    '150% PV Stress Voltage Comparison', ...
    fullfile(figDir, 'stress_voltage_comparison_150pv.png'));

create_final_dashboard(projectRoot);
fprintf('Final figures generated.\n');
end

function plot_strategy_voltage_set(resultsStruct, prefix, plotTitle, outputFile)
strategies = {'none', 'voltvar', 'voltwatt', 'hybrid', 'hybrid_pso'};
fig = figure('Color', 'w', 'Position', [100 100 920 520]);
hold on; grid on;
for i = 1:numel(strategies)
    key = matlab.lang.makeValidName([prefix '_' strategies{i}]);
    if isfield(resultsStruct, key)
        sc = resultsStruct.(key);
        [~, idx] = max(max(abs(sc.Vmag - 1), [], 2));
        plot(1:size(sc.Vmag, 2), sc.Vmag(idx, :), 'LineWidth', 1.6, ...
            'DisplayName', strategies{i});
    end
end
yline(0.95, '--r', 'Vmin', 'HandleVisibility', 'off');
yline(1.05, '--r', 'Vmax', 'HandleVisibility', 'off');
xlabel('Bus Number');
ylabel('Voltage Magnitude (p.u.)');
title(plotTitle);
legend('Location', 'best');
exportgraphics(fig, outputFile, 'Resolution', 220);
savefig(fig, replace(outputFile, '.png', '.fig'));
close(fig);
end

function create_final_dashboard(projectRoot)
tables = fullfile(projectRoot, 'results', 'tables');
figDir = fullfile(projectRoot, 'results', 'figures');
normal = readtable(fullfile(tables, 'all_case_summary.csv'));
stress = readtable(fullfile(tables, 'stress_case_summary.csv'));
host = readtable(fullfile(tables, 'hosting_capacity_summary.csv'));
pso = readtable(fullfile(tables, 'pso_convergence_all_seeds.csv'));
act = readtable(fullfile(tables, 'controller_activation_summary.csv'));

n80 = normal(normal.PVPenetrationPercent == 80 & strcmp(normal.IrradianceCondition, 'partial_cloud'), :);
s150 = stress(stress.PVPenetrationPercent == 150, :);

fig = figure('Color', 'w', 'Position', [80 80 1500 900]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; bar(categorical(n80.ControlStrategy), n80.MeanAbsVoltageDeviation); grid on;
title('Normal 80% PV Voltage Deviation'); ylabel('Mean |V-1|');
nexttile; bar(categorical(s150.ControlStrategy), s150.VoltageViolationCount); grid on;
title('Stress 150% PV Violations'); ylabel('Count');
nexttile; bar(categorical(s150.ControlStrategy), s150.PVCurtailment_kWh); grid on;
title('Stress 150% PV Curtailment'); ylabel('kWh equivalent');
nexttile; bar(categorical(host.ControlStrategy), host.HostingCapacityPercent); grid on;
title('Hosting Capacity'); ylabel('PV Penetration (%)');
nexttile; hold on; grid on;
seeds = unique(pso.Seed);
for i = 1:numel(seeds)
    idx = pso.Seed == seeds(i);
    plot(pso.Iteration(idx), pso.BestObjective(idx), 'DisplayName', sprintf('Seed %d', seeds(i)));
end
title('PSO Convergence'); xlabel('Iteration'); ylabel('Objective');
nexttile;
stressAct = act(strcmp(act.ScenarioGroup, 'stress'), :);
bar(categorical(strcat(stressAct.ControlStrategy, "_", string(stressAct.PVPenetrationPercent))), ...
    stressAct.VoltWattActivePercent); grid on;
title('Volt-Watt Activation in Stress Cases'); ylabel('Active (%)'); xtickangle(45);
exportgraphics(fig, fullfile(figDir, 'final_results_dashboard.png'), 'Resolution', 220);
savefig(fig, fullfile(figDir, 'final_results_dashboard.fig'));
close(fig);
end
