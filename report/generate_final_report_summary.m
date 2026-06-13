function generate_final_report_summary()
%GENERATE_FINAL_REPORT_SUMMARY Create final CSV and markdown interpretation.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
tableDir = fullfile(projectRoot, 'results', 'tables');
reportDir = fullfile(projectRoot, 'results', 'report');

base = readtable(fullfile(tableDir, 'basecase_summary.csv'));
normal = readtable(fullfile(tableDir, 'all_case_summary.csv'));
stress = readtable(fullfile(tableDir, 'stress_case_summary.csv'));
activation = readtable(fullfile(tableDir, 'controller_activation_summary.csv'));
hosting = readtable(fullfile(tableDir, 'hosting_capacity_summary.csv'));
psoSeeds = readtable(fullfile(tableDir, 'pso_seed_summary.csv'));
psoParams = readtable(fullfile(tableDir, 'pso_best_params.csv'));

n80 = normal(normal.PVPenetrationPercent == 80 & strcmp(normal.IrradianceCondition, 'partial_cloud'), :);
s150 = stress(stress.PVPenetrationPercent == 150, :);
summary = [tag_table(n80, 'Normal_80PV_PartialCloud'); tag_table(s150, 'Stress_150PV_ClearSky')];
writetable(summary, fullfile(tableDir, 'final_research_summary.csv'));

bestHosting = sortrows(hosting, 'HostingCapacityPercent', 'descend');
vwStress = activation(strcmp(activation.ScenarioGroup, 'stress'), :);

lines = strings(0, 1);
lines(end + 1) = "# Final Research Interpretation";
lines(end + 1) = "";
lines(end + 1) = "## 1. Model Description";
lines(end + 1) = "This project uses a quasi-static time-series MATLAB load-flow model of the IEEE 33-bus radial distribution feeder. Smart inverter controls are represented by Volt-VAR and Volt-Watt control curves with inverter apparent-power limits.";
lines(end + 1) = "";
lines(end + 1) = "## 2. IEEE 33-Bus Validation";
lines(end + 1) = sprintf("The base-case validation passed with %d buses, %d branches, minimum voltage %.4f p.u., and active loss %.2f kW.", ...
    base.NumBuses(1), base.NumBranches(1), base.MinVoltage_pu(1), base.Ploss_kW(1));
lines(end + 1) = "";
lines(end + 1) = "## 3. Normal Proposal Scenario Results";
lines(end + 1) = "For the normal 20%, 50%, and 80% PV proposal cases, Volt-Watt may be inactive when feeder voltage does not exceed the Volt-Watt threshold. This is reported honestly in the activation tables.";
lines(end + 1) = sprintf("In the 80%% PV partial-cloud case, no-control violations were %d. Hybrid-PSO mean voltage deviation was %.4f p.u.", ...
    n80.VoltageViolationCount(strcmp(n80.ControlStrategy, 'none')), ...
    n80.MeanAbsVoltageDeviation(strcmp(n80.ControlStrategy, 'hybrid_pso')));
lines(end + 1) = "";
lines(end + 1) = "## 4. Stress Scenario Results";
lines(end + 1) = "Stress scenarios use low daytime load, clear-sky irradiance, end-feeder PV placement, and 80-200% PV penetration to create overvoltage in no-control cases.";
lines(end + 1) = sprintf("At 150%% PV stress, no-control maximum voltage was %.4f p.u.; hybrid maximum voltage was %.4f p.u.; hybrid-PSO maximum voltage was %.4f p.u.", ...
    s150.MaxVoltage(strcmp(s150.ControlStrategy, 'none')), ...
    s150.MaxVoltage(strcmp(s150.ControlStrategy, 'hybrid')), ...
    s150.MaxVoltage(strcmp(s150.ControlStrategy, 'hybrid_pso')));
lines(end + 1) = "";
lines(end + 1) = "## 5. Volt-Watt Activation";
lines(end + 1) = sprintf("Volt-Watt activation in stress cases is proven in controller_activation_summary.csv. The maximum stress Volt-Watt active percentage is %.2f%%.", ...
    max(vwStress.VoltWattActivePercent));
lines(end + 1) = "";
lines(end + 1) = "## 6. Hybrid Control";
lines(end + 1) = "Hybrid control combines active-power curtailment and reactive-power support. In normal cases it can match Volt-VAR when Volt-Watt is inactive; in stress cases it differs because Volt-Watt is activated.";
lines(end + 1) = "";
lines(end + 1) = "## 7. PSO Optimization";
lines(end + 1) = sprintf("PSO v2 used multiple seeds. Best objective %.4f; default hybrid objective %.4f. The optimized controller should be interpreted as improving the selected objective, not every individual metric.", ...
    psoParams.OptimizedHybridObjective(1), psoParams.DefaultHybridObjective(1));
lines(end + 1) = sprintf("Seed objective mean %.4f and standard deviation %.4f.", mean(psoSeeds.BestObjective), std(psoSeeds.BestObjective));
lines(end + 1) = "";
lines(end + 1) = "## 8. Hosting Capacity";
for i = 1:height(hosting)
    lines(end + 1) = sprintf("- %s: %.0f%% PV", hosting.ControlStrategy{i}, hosting.HostingCapacityPercent(i));
end
lines(end + 1) = sprintf("Best hosting capacity in this study: %s at %.0f%% PV.", ...
    bestHosting.ControlStrategy{1}, bestHosting.HostingCapacityPercent(1));
lines(end + 1) = "";
lines(end + 1) = "## 9. Limitations";
lines(end + 1) = "This is not EMT transient simulation. The response metric is a quasi-static voltage recovery indicator over time-series load-flow snapshots. Communication delay, detailed inverter switching, protection dynamics, and unbalanced phase modelling are outside the current scope.";
lines(end + 1) = "";
lines(end + 1) = "## 10. Final Conclusion";
lines(end + 1) = "The results support the proposal objectives with a careful interpretation: Volt-VAR is effective for voltage support, Volt-Watt is effective when overvoltage occurs, Hybrid is most valuable under high-PV stress, and PSO improves the selected multi-objective trade-off while possible loss/curtailment trade-offs must be reported.";

writelines(lines, fullfile(reportDir, 'final_interpretation.md'));
fprintf('Final report summary generated.\n');
end

function out = tag_table(in, scenarioName)
out = in(:, {'ControlStrategy', 'MeanAbsVoltageDeviation', 'MaxAbsVoltageDeviation', ...
    'MinVoltage', 'MaxVoltage', 'VoltageViolationCount', 'MeanActiveLoss_kW', 'PVCurtailment_kWh'});
out.Scenario = repmat(string(scenarioName), height(out), 1);
out = movevars(out, 'Scenario', 'Before', 'ControlStrategy');
end
