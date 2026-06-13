function stressResults = main_run_stress_cases()
%MAIN_RUN_STRESS_CASES Run supplementary high-PV overvoltage stress study.
%
% The proposal cases remain 20/50/80% PV. This supplementary study uses
% higher PV and low daytime load to activate Volt-Watt behavior and quantify
% curtailment/overvoltage mitigation.

startup_project();
projectRoot = fileparts(mfilename('fullpath'));
net = ieee33_data();

penetrations = [80 100 120 150 180 200];
strategies = {'none', 'voltvar', 'voltwatt', 'hybrid'};
bestFile = fullfile(projectRoot, 'results', 'mat_files', 'best_params.mat');
psoParams = [];
if exist(bestFile, 'file')
    s = load(bestFile, 'bestParams');
    psoParams = s.bestParams;
    strategies{end + 1} = 'hybrid_pso';
end

simOptions = struct();
simOptions.loadProfileType = 'stress';
simOptions.pvBusOption = 'stress_end_buses';
simOptions.pvWeights = [0.8 0.9 1.0 1.0 1.1 1.2];
simOptions.scenarioLabel = 'overvoltage_stress';
simOptions.controlOptions = struct('maxOuterIter', 120, 'outerTol', 1e-6, 'relaxation', 0.20);

summaryRows = {};
hourlyRows = {};
activationRows = {};
recoveryRows = table();
stressResults = struct();

for p = penetrations
    voltagePlotStruct = struct();
    for s = 1:numel(strategies)
        strategy = strategies{s};
        params = default_control_params();
        if strcmp(strategy, 'hybrid_pso') && ~isempty(psoParams)
            params = psoParams;
        end
        scenario = main_run_single_case(p, 'stress_clear_sky', strategy, params, simOptions);
        safeName = matlab.lang.makeValidName(sprintf('Stress_P%d_%s', p, strategy));
        stressResults.(safeName) = scenario;
        voltagePlotStruct.(matlab.lang.makeValidName(strategy)) = scenario;

        vm = calculate_voltage_metrics(scenario.Vmag, net);
        response = scenario.response;
        recoveryRows = [recoveryRows; calculate_voltage_recovery_steps( ...
            scenario.time_h, scenario.Vmag, net, sprintf('stress_%dpct', p), strategy)]; %#ok<AGROW>
        summaryRows(end + 1, :) = {p, strategy, vm.meanAbsVoltageDeviation, ...
            vm.maxAbsVoltageDeviation, vm.minVoltage, vm.maxVoltage, ...
            sum(scenario.violations), sum(scenario.loss_kW), ...
            mean(scenario.loss_kW), sum(scenario.curtail_kW), ...
            response.maxSettlingSteps, response.maxSettlingHours}; %#ok<AGROW>

        for t = 1:numel(scenario.time_h)
            hourlyRows(end + 1, :) = {p, strategy, scenario.time_h(t), ...
                scenario.loadMultiplier(t), scenario.irradiance(t), ...
                min(scenario.Vmag(t, :)), max(scenario.Vmag(t, :)), ...
                mean(abs(scenario.Vmag(t, :) - 1)), scenario.loss_kW(t), ...
                scenario.violations(t), scenario.curtail_kW(t), scenario.q_kVAr(t)}; %#ok<AGROW>
        end
        activationRows = append_activation_rows(activationRows, 'stress', p, 'stress_clear_sky', strategy, scenario);
    end

    noneScenario = stressResults.(matlab.lang.makeValidName(sprintf('Stress_P%d_none', p)));
    if p >= 100
        assert(max(noneScenario.Vmag(:)) > 1.05, ...
            'Stress scenario did not create overvoltage for no-control case at %d%% PV.', p);
    end

    plot_voltage_profiles(net, voltagePlotStruct, p, ...
        fullfile(projectRoot, 'results', 'figures', sprintf('stress_voltage_profile_penetration_%d.png', p)));
end

stressSummary = cell2table(summaryRows, 'VariableNames', ...
    {'PVPenetrationPercent', 'ControlStrategy', 'MeanAbsVoltageDeviation', ...
    'MaxAbsVoltageDeviation', 'MinVoltage', 'MaxVoltage', ...
    'VoltageViolationCount', 'TotalActiveLoss_kWh', 'MeanActiveLoss_kW', ...
    'PVCurtailment_kWh', 'ResponseSettlingSteps', 'ResponseSettlingHours'});

stressHourly = cell2table(hourlyRows, 'VariableNames', ...
    {'PVPenetrationPercent', 'ControlStrategy', 'Time_h', 'LoadMultiplier', ...
    'Irradiance', 'MinVoltage', 'MaxVoltage', 'MeanAbsVoltageDeviation', ...
    'ActiveLoss_kW', 'VoltageViolationCount', 'PVCurtailment_kW', 'ReactivePower_kVAr'});

writetable(stressSummary, fullfile(projectRoot, 'results', 'tables', 'stress_case_summary.csv'));
writetable(stressHourly, fullfile(projectRoot, 'results', 'tables', 'stress_hourly_results.csv'));
stressActivationLog = activation_rows_to_table(activationRows);
append_or_write_activation(projectRoot, stressActivationLog);
append_or_write_recovery(projectRoot, recoveryRows);
stressEffectiveness = create_stress_effectiveness_table(stressSummary);
writetable(stressEffectiveness, fullfile(projectRoot, 'results', 'tables', 'stress_control_effectiveness_summary.csv'));
save(fullfile(projectRoot, 'results', 'mat_files', 'stress_results.mat'), ...
    'stressResults', 'stressSummary', 'stressHourly', 'stressEffectiveness');

plot_case_comparison(stressSummary, 'VoltageViolationCount', 'Stress Voltage Violation Count', ...
    fullfile(projectRoot, 'results', 'figures', 'stress_violation_comparison.png'));
plot_case_comparison(stressSummary, 'PVCurtailment_kWh', 'Stress PV Curtailment (kWh equivalent)', ...
    fullfile(projectRoot, 'results', 'figures', 'stress_pv_curtailment_comparison.png'));
plot_case_comparison(stressSummary, 'MeanActiveLoss_kW', 'Stress Power Loss (kW)', ...
    fullfile(projectRoot, 'results', 'figures', 'stress_loss_comparison.png'));

fprintf('Stress cases complete. Summary written to results/tables/stress_case_summary.csv\n');
end

function append_or_write_recovery(projectRoot, recoveryRows)
fileName = fullfile(projectRoot, 'results', 'tables', 'voltage_recovery_summary.csv');
if exist(fileName, 'file')
    existing = readtable(fileName);
    recoveryRows = [existing; recoveryRows];
end
writetable(recoveryRows, fileName);
end

function rows = append_activation_rows(rows, scenarioGroup, penetration, condition, strategy, scenario)
logTable = scenario.pvLog;
for i = 1:height(logTable)
    rows(end + 1, :) = {scenarioGroup, penetration, condition, strategy, ...
        logTable.TimeIndex(i), logTable.Time_h(i), logTable.Bus(i), ...
        logTable.LocalVoltage_pu(i), logTable.Pavailable_kW(i), ...
        logTable.Poutput_kW(i), logTable.Pcurtailed_kW(i), ...
        logTable.Qoutput_kVAr(i), logTable.Qlimit_kVAr(i), ...
        logTable.VoltVARActive(i), logTable.VoltWattActive(i), logTable.BothActive(i)}; %#ok<AGROW>
end
end

function out = activation_rows_to_table(rows)
out = cell2table(rows, 'VariableNames', ...
    {'ScenarioGroup', 'PVPenetrationPercent', 'IrradianceCondition', 'ControlStrategy', ...
    'TimeIndex', 'Time_h', 'Bus', 'LocalVoltage_pu', 'Pavailable_kW', ...
    'Poutput_kW', 'Pcurtailed_kW', 'Qoutput_kVAr', 'Qlimit_kVAr', ...
    'VoltVARActive', 'VoltWattActive', 'BothActive'});
end

function append_or_write_activation(projectRoot, stressActivationLog)
tableDir = fullfile(projectRoot, 'results', 'tables');
vwFile = fullfile(tableDir, 'voltwatt_activation_log.csv');
hyFile = fullfile(tableDir, 'hybrid_activation_log.csv');
vwStress = stressActivationLog(stressActivationLog.VoltWattActive, :);
hyStress = stressActivationLog(strcmp(stressActivationLog.ControlStrategy, 'hybrid') ...
    | strcmp(stressActivationLog.ControlStrategy, 'hybrid_pso'), :);
if exist(vwFile, 'file')
    vwExisting = readtable(vwFile);
    vwStress = [vwExisting; vwStress];
end
if exist(hyFile, 'file')
    hyExisting = readtable(hyFile);
    hyStress = [hyExisting; hyStress];
end
writetable(vwStress, vwFile);
writetable(hyStress, hyFile);
end

function out = create_stress_effectiveness_table(stressSummary)
rows = {};
penetrations = unique(stressSummary.PVPenetrationPercent);
for p = penetrations(:)'
    sub = stressSummary(stressSummary.PVPenetrationPercent == p, :);
    baseIdx = strcmp(sub.ControlStrategy, 'none');
    if ~any(baseIdx), continue; end
    base = sub(baseIdx, :);
    for i = 1:height(sub)
        rows(end + 1, :) = {p, sub.ControlStrategy{i}, ...
            percent_reduction(base.MeanAbsVoltageDeviation, sub.MeanAbsVoltageDeviation(i)), ...
            percent_reduction(base.VoltageViolationCount, sub.VoltageViolationCount(i)), ...
            percent_reduction(base.MeanActiveLoss_kW, sub.MeanActiveLoss_kW(i)), ...
            sub.PVCurtailment_kWh(i), sub.MinVoltage(i), sub.MaxVoltage(i)}; %#ok<AGROW>
    end
end
out = cell2table(rows, 'VariableNames', ...
    {'PVPenetrationPercent', 'ControlStrategy', ...
    'VoltageDeviationReductionPercent', 'ViolationReductionPercent', ...
    'LossReductionPercent', 'PVCurtailment_kWh', 'MinVoltage', 'MaxVoltage'});
end

function value = percent_reduction(baseValue, newValue)
if abs(baseValue) < eps
    value = 0;
else
    value = 100 * (baseValue - newValue) / baseValue;
end
end
