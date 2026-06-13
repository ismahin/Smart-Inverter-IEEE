function allResults = main_run_all_cases()
%MAIN_RUN_ALL_CASES Run all penetration/control/weather scenarios.

startup_project();
projectRoot = fileparts(mfilename('fullpath'));
net = ieee33_data();

penetrations = [20 50 80];
conditions = {'clear_sky', 'partial_cloud', 'low_irradiance'};
strategies = {'none', 'voltvar', 'voltwatt', 'hybrid'};

bestFile = fullfile(projectRoot, 'results', 'mat_files', 'best_params.mat');
psoParams = [];
if exist(bestFile, 'file')
    s = load(bestFile, 'bestParams');
    psoParams = s.bestParams;
    strategies{end + 1} = 'hybrid_pso';
end

summaryRows = {};
hourlyRows = {};
activationRows = {};
recoveryRows = table();
allResults = struct();
caseIndex = 0;

for p = penetrations
    voltagePlotStruct = struct();
    for c = 1:numel(conditions)
        for s = 1:numel(strategies)
            strategy = strategies{s};
            params = default_control_params();
            if strcmp(strategy, 'hybrid_pso') && ~isempty(psoParams)
                params = psoParams;
            end

            scenario = main_run_single_case(p, conditions{c}, strategy, params);
            caseIndex = caseIndex + 1;
            caseName = sprintf('P%d_%s_%s', p, conditions{c}, strategy);
            safeName = matlab.lang.makeValidName(caseName);
            allResults.(safeName) = scenario;

            if strcmp(conditions{c}, 'partial_cloud')
                voltagePlotStruct.(matlab.lang.makeValidName(strategy)) = scenario;
            end

            V = scenario.Vmag;
            vm = calculate_voltage_metrics(V, net);
            totalCurtail_kWh = sum(scenario.curtail_kW);
            totalLoss_kWh = sum(scenario.loss_kW);
            response = scenario.response;
            recoveryRows = [recoveryRows; calculate_voltage_recovery_steps( ...
                scenario.time_h, scenario.Vmag, net, ...
                sprintf('normal_%dpct_%s', p, conditions{c}), strategy)]; %#ok<AGROW>

            summaryRows(end + 1, :) = {p, conditions{c}, strategy, ...
                vm.meanAbsVoltageDeviation, vm.maxAbsVoltageDeviation, ...
                vm.minVoltage, vm.maxVoltage, sum(scenario.violations), ...
                totalLoss_kWh, mean(scenario.loss_kW), totalCurtail_kWh, ...
                response.maxSettlingSteps, response.maxSettlingHours}; %#ok<AGROW>

            for t = 1:numel(scenario.time_h)
                hourlyRows(end + 1, :) = {p, conditions{c}, strategy, scenario.time_h(t), ...
                    scenario.loadMultiplier(t), scenario.irradiance(t), min(V(t, :)), ...
                    max(V(t, :)), mean(abs(V(t, :) - 1)), scenario.loss_kW(t), ...
                    scenario.violations(t), scenario.curtail_kW(t), scenario.q_kVAr(t), ...
                    scenario.outerIter(t)}; %#ok<AGROW>
            end
            activationRows = append_activation_rows(activationRows, 'normal', p, conditions{c}, strategy, scenario);
        end
    end

    plot_voltage_profiles(net, voltagePlotStruct, p, ...
        fullfile(projectRoot, 'results', 'figures', sprintf('voltage_profile_penetration_%d.png', p)));
end

summaryTable = cell2table(summaryRows, 'VariableNames', ...
    {'PVPenetrationPercent', 'IrradianceCondition', 'ControlStrategy', ...
    'MeanAbsVoltageDeviation', 'MaxAbsVoltageDeviation', 'MinVoltage', ...
    'MaxVoltage', 'VoltageViolationCount', 'TotalActiveLoss_kWh', ...
    'MeanActiveLoss_kW', 'PVCurtailment_kWh', 'ResponseSettlingSteps', ...
    'ResponseSettlingHours'});

hourlyTable = cell2table(hourlyRows, 'VariableNames', ...
    {'PVPenetrationPercent', 'IrradianceCondition', 'ControlStrategy', 'Time_h', ...
    'LoadMultiplier', 'Irradiance', 'MinVoltage', 'MaxVoltage', ...
    'MeanAbsVoltageDeviation', 'ActiveLoss_kW', 'VoltageViolationCount', ...
    'PVCurtailment_kW', 'ReactivePower_kVAr', 'OuterIterations'});

paramsMap = struct();
if ~isempty(psoParams), paramsMap.hybrid_pso = psoParams; end
hostingStrategies = strategies;
[hostingTable, hostingCurveTable] = calculate_hosting_capacity(hostingStrategies, paramsMap);

writetable(summaryTable, fullfile(projectRoot, 'results', 'tables', 'all_case_summary.csv'));
writetable(hourlyTable, fullfile(projectRoot, 'results', 'tables', 'hourly_results.csv'));
activationLog = activation_rows_to_table(activationRows);
writetable(activationLog(activationLog.VoltWattActive, :), ...
    fullfile(projectRoot, 'results', 'tables', 'voltwatt_activation_log.csv'));
writetable(activationLog(strcmp(activationLog.ControlStrategy, 'hybrid') ...
    | strcmp(activationLog.ControlStrategy, 'hybrid_pso'), :), ...
    fullfile(projectRoot, 'results', 'tables', 'hybrid_activation_log.csv'));
writetable(recoveryRows, fullfile(projectRoot, 'results', 'tables', 'voltage_recovery_summary.csv'));
effectivenessTable = create_effectiveness_table(summaryTable, {'PVPenetrationPercent', 'IrradianceCondition'});
writetable(effectivenessTable, fullfile(projectRoot, 'results', 'tables', 'control_effectiveness_summary.csv'));
save(fullfile(projectRoot, 'results', 'mat_files', 'full_results.mat'), ...
    'allResults', 'summaryTable', 'hourlyTable', 'hostingTable', 'hostingCurveTable', ...
    'effectivenessTable', 'recoveryRows');

plot_case_comparison(summaryTable, 'MeanActiveLoss_kW', 'Power Loss (kW)', ...
    fullfile(projectRoot, 'results', 'figures', 'loss_comparison.png'));
plot_case_comparison(summaryTable, 'VoltageViolationCount', 'Voltage Violation Count', ...
    fullfile(projectRoot, 'results', 'figures', 'violation_comparison.png'));
plot_case_comparison(summaryTable, 'PVCurtailment_kWh', 'PV Curtailment (kWh equivalent)', ...
    fullfile(projectRoot, 'results', 'figures', 'pv_curtailment_comparison.png'));
plot_case_comparison(hostingTable, 'HostingCapacityPercent', 'Hosting Capacity (% PV)', ...
    fullfile(projectRoot, 'results', 'figures', 'hosting_capacity_comparison.png'));

fprintf('All cases complete. Summary written to results/tables/all_case_summary.csv\n');
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

function out = create_effectiveness_table(summaryTable, groupVars)
rows = {};
groups = unique(summaryTable(:, groupVars), 'rows');
for g = 1:height(groups)
    mask = true(height(summaryTable), 1);
    for v = 1:numel(groupVars)
        gv = groupVars{v};
        if iscell(summaryTable.(gv))
            mask = mask & strcmp(summaryTable.(gv), groups.(gv){g});
        else
            mask = mask & summaryTable.(gv) == groups.(gv)(g);
        end
    end
    sub = summaryTable(mask, :);
    baseIdx = strcmp(sub.ControlStrategy, 'none');
    if ~any(baseIdx), continue; end
    base = sub(baseIdx, :);
    for i = 1:height(sub)
        devReduction = percent_reduction(base.MeanAbsVoltageDeviation, sub.MeanAbsVoltageDeviation(i));
        violationReduction = percent_reduction(base.VoltageViolationCount, sub.VoltageViolationCount(i));
        lossReduction = percent_reduction(base.MeanActiveLoss_kW, sub.MeanActiveLoss_kW(i));
        rows(end + 1, :) = {sub.PVPenetrationPercent(i), sub.IrradianceCondition{i}, ...
            sub.ControlStrategy{i}, devReduction, violationReduction, lossReduction, ...
            sub.PVCurtailment_kWh(i), sub.MinVoltage(i), sub.MaxVoltage(i)}; %#ok<AGROW>
    end
end
out = cell2table(rows, 'VariableNames', ...
    {'PVPenetrationPercent', 'IrradianceCondition', 'ControlStrategy', ...
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
