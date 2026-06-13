function validate_final_results()
%VALIDATE_FINAL_RESULTS Strict final result quality checks.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
tableDir = fullfile(projectRoot, 'results', 'tables');
figDir = fullfile(projectRoot, 'results', 'figures');
reportDir = fullfile(projectRoot, 'results', 'report');

requiredTables = {
    'basecase_summary.csv'
    'pv_penetration_validation.csv'
    'all_case_summary.csv'
    'stress_case_summary.csv'
    'voltwatt_activation_log.csv'
    'hybrid_activation_log.csv'
    'controller_activation_summary.csv'
    'pso_seed_summary.csv'
    'pso_best_params.csv'
    'pso_training_scenario_scores.csv'
    'pso_test_scenario_scores.csv'
    'hosting_capacity_curve.csv'
    'hosting_capacity_summary.csv'
    'voltage_recovery_summary.csv'
    'final_research_summary.csv'
};

requiredFigures = {
    'basecase_voltage_profile.png'
    'normal_voltage_comparison_80pv.png'
    'stress_voltage_comparison_150pv.png'
    'loss_comparison.png'
    'violation_comparison.png'
    'pv_curtailment_comparison.png'
    'controller_activation_heatmap.png'
    'pso_convergence_all_seeds.png'
    'hosting_capacity_comparison.png'
    'max_voltage_vs_pv_penetration.png'
    'violations_vs_pv_penetration.png'
    'final_results_dashboard.png'
};

for i = 1:numel(requiredTables)
    assert(exist(fullfile(tableDir, requiredTables{i}), 'file') == 2, ...
        'Missing required table: %s', requiredTables{i});
end
for i = 1:numel(requiredFigures)
    assert(exist(fullfile(figDir, requiredFigures{i}), 'file') == 2, ...
        'Missing required figure: %s', requiredFigures{i});
end
assert(exist(fullfile(reportDir, 'final_interpretation.md'), 'file') == 2, ...
    'Missing final interpretation markdown report.');

for i = 1:numel(requiredTables)
    T = readtable(fullfile(tableDir, requiredTables{i}));
    assert_no_nan_inf(T, requiredTables{i});
end

normal = readtable(fullfile(tableDir, 'all_case_summary.csv'));
stress = readtable(fullfile(tableDir, 'stress_case_summary.csv'));
assert(all(normal.MinVoltage >= 0.85 & normal.MaxVoltage <= 1.15), ...
    'Normal-case voltages outside physical reasonableness bounds.');
assert(all(stress.MinVoltage >= 0.85 & stress.MaxVoltage <= 1.15), ...
    'Stress-case voltages outside physical reasonableness bounds.');

stress150 = stress(stress.PVPenetrationPercent == 150, :);
baseViol = stress150.VoltageViolationCount(strcmp(stress150.ControlStrategy, 'none'));
hyViol = stress150.VoltageViolationCount(strcmp(stress150.ControlStrategy, 'hybrid'));
assert(baseViol > hyViol, 'Stress base case does not have more violations than hybrid control.');

vwLog = readtable(fullfile(tableDir, 'voltwatt_activation_log.csv'));
assert(any(strcmp(vwLog.ScenarioGroup, 'stress') & vwLog.VoltWattActive), ...
    'Volt-Watt activation count is zero in stress cases.');

hyLog = readtable(fullfile(tableDir, 'hybrid_activation_log.csv'));
assert(any(strcmp(hyLog.ScenarioGroup, 'stress') & hyLog.BothActive), ...
    'Hybrid both-active count is zero in stress cases.');

psoBest = readtable(fullfile(tableDir, 'pso_best_params.csv'));
assert(psoBest.OptimizedHybridObjective(1) < psoBest.DefaultHybridObjective(1), ...
    'PSO optimized objective did not improve over default hybrid objective.');

host = readtable(fullfile(tableDir, 'hosting_capacity_summary.csv'));
assert(height(host) >= 5, 'Hosting capacity summary missing control strategies.');

fprintf('Final result validation passed.\n');
end

function assert_no_nan_inf(T, name)
for j = 1:width(T)
    x = T.(j);
    if isnumeric(x) || islogical(x)
        assert(all(isfinite(double(x(:))) | isnan(double(x(:)))), 'Unexpected invalid numeric in %s.', name);
        % NaN is allowed only for recovery steps if unrecovered.
        if ~contains(name, 'voltage_recovery')
            assert(~any(isnan(double(x(:)))), 'NaN found in %s.', name);
        end
    end
end
end
