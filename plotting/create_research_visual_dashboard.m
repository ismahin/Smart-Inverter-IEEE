function create_research_visual_dashboard()
%CREATE_RESEARCH_VISUAL_DASHBOARD Generate compact publication/report dashboard.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
tableDir = fullfile(projectRoot, 'results', 'tables');
figureDir = fullfile(projectRoot, 'results', 'figures');

key = readtable(fullfile(tableDir, 'research_key_results.csv'));
hosting = readtable(fullfile(tableDir, 'hosting_capacity.csv'));
pso = readtable(fullfile(tableDir, 'pso_convergence.csv'));
fullData = load(fullfile(projectRoot, 'results', 'mat_files', 'full_results.mat'), 'allResults');
stressData = load(fullfile(projectRoot, 'results', 'mat_files', 'stress_results.mat'), 'stressResults');

proposal = key(strcmp(key.Scenario, 'proposal_80pct_partial_cloud'), :);
stress = key(strcmp(key.Scenario, 'stress_100pct_clear_low_daytime'), :);

fig = figure('Color', 'w', 'Position', [80 80 1500 950]);
tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
bar(categorical(proposal.ControlStrategy), proposal.MeanAbsVoltageDeviation);
title('80% PV Partial Cloud: Voltage Deviation');
ylabel('Mean |V-1| (p.u.)');
grid on;

nexttile;
bar(categorical(proposal.ControlStrategy), proposal.VoltageViolationCount);
title('80% PV Partial Cloud: Violations');
ylabel('Count');
grid on;

nexttile;
bar(categorical(proposal.ControlStrategy), proposal.MeanActiveLoss_kW);
title('80% PV Partial Cloud: Losses');
ylabel('kW');
grid on;

nexttile;
bar(categorical(stress.ControlStrategy), stress.MaxVoltage);
yline(1.05, '--r', 'Vmax');
title('Stress Case: Maximum Voltage');
ylabel('p.u.');
grid on;

nexttile;
bar(categorical(stress.ControlStrategy), stress.PVCurtailment_kWh);
title('Stress Case: PV Curtailment');
ylabel('kWh equivalent');
grid on;

nexttile;
plot(pso.Iteration, pso.BestObjective, '-o', 'LineWidth', 1.5);
title('PSO Convergence');
xlabel('Iteration');
ylabel('Best Objective');
grid on;

nexttile;
plot_voltage_envelope(fullData.allResults.P80_partial_cloud_hybrid_pso, ...
    'Proposal Case Voltage Envelope');

nexttile;
plot_voltage_envelope(stressData.stressResults.Stress_P100_hybrid_pso, ...
    'Stress Case Voltage Envelope');

nexttile;
bar(categorical(hosting.ControlStrategy), hosting.HostingCapacityPercent);
title('Hosting Capacity');
ylabel('PV Penetration (%)');
grid on;

exportgraphics(fig, fullfile(figureDir, 'research_results_dashboard.png'), 'Resolution', 220);
savefig(fig, fullfile(figureDir, 'research_results_dashboard.fig'));
close(fig);

fprintf('Created dashboard: results/figures/research_results_dashboard.png\n');
end

function plot_voltage_envelope(scenario, plotTitle)
time = scenario.time_h;
V = scenario.Vmag;
plot(time, min(V, [], 2), 'LineWidth', 1.5, 'DisplayName', 'Minimum');
hold on;
plot(time, mean(V, 2), 'LineWidth', 1.5, 'DisplayName', 'Mean');
plot(time, max(V, [], 2), 'LineWidth', 1.5, 'DisplayName', 'Maximum');
yline(0.95, '--r', 'Vmin', 'HandleVisibility', 'off');
yline(1.05, '--r', 'Vmax', 'HandleVisibility', 'off');
hold off;
title(plotTitle);
xlabel('Time (hours)');
ylabel('Voltage (p.u.)');
legend('Location', 'best');
grid on;
end
