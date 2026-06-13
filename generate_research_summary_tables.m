function generate_research_summary_tables()
%GENERATE_RESEARCH_SUMMARY_TABLES Create compact result tables for reporting.

startup_project();
projectRoot = fileparts(mfilename('fullpath'));
tableDir = fullfile(projectRoot, 'results', 'tables');

proposal = readtable(fullfile(tableDir, 'all_case_summary.csv'));
stress = readtable(fullfile(tableDir, 'stress_case_summary.csv'));

proposalCase = proposal(proposal.PVPenetrationPercent == 80 ...
    & strcmp(proposal.IrradianceCondition, 'partial_cloud'), :);
stressCase = stress(stress.PVPenetrationPercent == 100, :);

keyRows = [
    summarize_against_base(proposalCase, 'proposal_80pct_partial_cloud')
    summarize_against_base(stressCase, 'stress_100pct_clear_low_daytime')
];

writetable(keyRows, fullfile(tableDir, 'research_key_results.csv'));

bestRows = [
    best_by_metric(proposalCase, 'proposal_80pct_partial_cloud')
    best_by_metric(stressCase, 'stress_100pct_clear_low_daytime')
];
writetable(bestRows, fullfile(tableDir, 'best_control_by_metric.csv'));

fprintf('Research summary tables written to results/tables/research_key_results.csv\n');
end

function out = summarize_against_base(caseTable, scenarioName)
base = caseTable(strcmp(caseTable.ControlStrategy, 'none'), :);
rows = {};
for i = 1:height(caseTable)
    rows(end + 1, :) = {scenarioName, caseTable.ControlStrategy{i}, ...
        caseTable.MeanAbsVoltageDeviation(i), caseTable.MaxAbsVoltageDeviation(i), ...
        caseTable.MinVoltage(i), caseTable.MaxVoltage(i), ...
        caseTable.VoltageViolationCount(i), caseTable.MeanActiveLoss_kW(i), ...
        caseTable.PVCurtailment_kWh(i), ...
        pct_reduction(base.MeanAbsVoltageDeviation, caseTable.MeanAbsVoltageDeviation(i)), ...
        pct_reduction(base.VoltageViolationCount, caseTable.VoltageViolationCount(i)), ...
        pct_reduction(base.MeanActiveLoss_kW, caseTable.MeanActiveLoss_kW(i))}; %#ok<AGROW>
end

out = cell2table(rows, 'VariableNames', ...
    {'Scenario', 'ControlStrategy', 'MeanAbsVoltageDeviation', ...
    'MaxAbsVoltageDeviation', 'MinVoltage', 'MaxVoltage', ...
    'VoltageViolationCount', 'MeanActiveLoss_kW', 'PVCurtailment_kWh', ...
    'VoltageDeviationReductionPercent', 'ViolationReductionPercent', ...
    'LossReductionPercent'});
end

function out = best_by_metric(caseTable, scenarioName)
metrics = {'MeanAbsVoltageDeviation', 'MaxAbsVoltageDeviation', ...
    'VoltageViolationCount', 'MeanActiveLoss_kW'};
labels = {'Lowest mean voltage deviation', 'Lowest maximum voltage deviation', ...
    'Fewest voltage violations', 'Lowest mean active loss'};
rows = cell(numel(metrics), 4);
for i = 1:numel(metrics)
    [value, idx] = min(caseTable.(metrics{i}));
    rows(i, :) = {scenarioName, labels{i}, caseTable.ControlStrategy{idx}, value};
end
out = cell2table(rows, 'VariableNames', ...
    {'Scenario', 'Metric', 'BestControlStrategy', 'BestValue'});
end

function value = pct_reduction(baseValue, newValue)
if abs(baseValue) < eps
    value = 0;
else
    value = 100 * (baseValue - newValue) / baseValue;
end
end
