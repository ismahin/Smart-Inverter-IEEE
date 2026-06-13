function psoResult = run_pso_optimization()
%RUN_PSO_OPTIMIZATION Optimize hybrid Volt-VAR/Volt-Watt parameters.

startup_project();
rng(1);
projectRoot = fileparts(fileparts(mfilename('fullpath')));
net = ieee33_data();
pvNormal = apply_pv_penetration(net, 80, select_pv_buses());
loadNormal = create_load_profile('mixed', 1);
irrNormal = create_irradiance_profile('partial_cloud', 1);
pvStress = apply_pv_penetration(net, 100, select_pv_buses('end_buses'), ...
    [0.5 0.7 1.0 1.2 1.4 1.6]);
loadStress = create_load_profile('low_daytime', 1);
irrStress = create_irradiance_profile('clear_sky', 1);

lb = [0.90 0.95 1.00 1.03 0.1 0.1 1.02 1.06 0.0];
ub = [0.97 1.00 1.05 1.10 1.0 1.0 1.07 1.12 0.8];
obj = @(x) 0.55 * pso_objective_function(x, net, pvNormal, loadNormal, irrNormal) ...
    + 0.45 * pso_objective_function(x, net, pvStress, loadStress, irrStress);

useParticleswarm = exist('particleswarm', 'file') == 2 && license('test', 'GADS_Toolbox');
if useParticleswarm
    historyValues = [];
    opts = optimoptions('particleswarm', ...
        'SwarmSize', 16, ...
        'MaxIterations', 18, ...
        'Display', 'iter', ...
        'OutputFcn', @outfun);
    [bestX, bestF] = particleswarm(obj, 9, lb, ub, opts);
    history = table((0:numel(historyValues)-1)', historyValues(:), ...
        'VariableNames', {'Iteration', 'BestObjective'});
    solverName = 'particleswarm';
else
    opts = struct('SwarmSize', 12, 'MaxIterations', 15, 'Display', 'iter');
    [bestX, bestF, history] = custom_pso_fallback(obj, lb, ub, opts);
    solverName = 'custom_pso_fallback';
end

bestParams = vector_to_control_params(bestX);
resultDir = fullfile(projectRoot, 'results');
save(fullfile(resultDir, 'mat_files', 'best_params.mat'), ...
    'bestParams', 'bestX', 'bestF', 'solverName');
writetable(history, fullfile(resultDir, 'tables', 'pso_convergence.csv'));
plot_pso_convergence(history, fullfile(resultDir, 'figures', 'pso_convergence.png'));

comparison = compare_default_vs_optimized(net, pvNormal, loadNormal, irrNormal, ...
    pvStress, loadStress, irrStress, bestParams);
writetable(comparison, fullfile(resultDir, 'tables', 'optimized_vs_default_summary.csv'));

psoResult.bestParams = bestParams;
psoResult.bestX = bestX;
psoResult.bestF = bestF;
psoResult.history = history;
psoResult.solverName = solverName;
fprintf('PSO complete using %s. Best objective %.6g\n', solverName, bestF);

    function stop = outfun(optimValues, state)
        stop = false;
        if strcmp(state, 'iter') || strcmp(state, 'init')
            historyValues(end + 1, 1) = optimValues.bestfval;
        end
    end
end

function comparison = compare_default_vs_optimized(net, pvNormal, loadNormal, irrNormal, ...
    pvStress, loadStress, irrStress, bestParams)
caseNames = {'normal_80pct_partial_cloud'; 'stress_100pct_clear_low_daytime'};
pvCases = {pvNormal; pvStress};
loadCases = {loadNormal; loadStress};
irrCases = {irrNormal; irrStress};
labels = {'hybrid_default'; 'hybrid_pso'};
paramsList = {default_control_params(); bestParams};
rows = {};
for c = 1:numel(caseNames)
    for i = 1:numel(labels)
        loadProfile = loadCases{c};
        irrProfile = irrCases{c};
        pv = pvCases{c};
        V = zeros(numel(loadProfile.time_h), net.nBus);
        loss = zeros(numel(loadProfile.time_h), 1);
        curt = zeros(numel(loadProfile.time_h), 1);
        viol = zeros(numel(loadProfile.time_h), 1);
        for t = 1:numel(loadProfile.time_h)
            r = apply_smart_inverter_control(net, pv, loadProfile.multiplier(t), ...
                irrProfile.irradiance(t), 'hybrid', paramsList{i});
            vm = calculate_voltage_metrics(r.lf.Vmag, net);
            V(t, :) = r.lf.Vmag(:)';
            loss(t) = r.lf.Ploss_kW;
            curt(t) = sum(r.Pcurtailed_kW);
            viol(t) = vm.totalViolationCount;
        end
        vmAll = calculate_voltage_metrics(V, net);
        rows(end + 1, :) = {caseNames{c}, labels{i}, vmAll.meanAbsVoltageDeviation, ...
            vmAll.maxAbsVoltageDeviation, min(V(:)), max(V(:)), ...
            sum(viol), sum(loss), sum(curt)}; %#ok<AGROW>
    end
end

comparison = cell2table(rows, 'VariableNames', ...
    {'OptimizationScenario', 'ControlStrategy', 'MeanAbsVoltageDeviation', ...
    'MaxAbsVoltageDeviation', 'MinVoltage', 'MaxVoltage', ...
    'VoltageViolationCount', 'TotalActiveLoss_kWh', 'PVCurtailment_kWh'});
end
