function psoResult = run_pso_optimization_v2()
%RUN_PSO_OPTIMIZATION_V2 Multi-seed, multi-scenario PSO optimization.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(projectRoot, 'results');

[trainingScenarios, testScenarios] = build_pso_scenarios();
baseRefs = build_base_refs(trainingScenarios);

lb = [0.90 0.95 1.00 1.03 0.1 0.1 1.01 1.04 0.0];
ub = [0.97 1.00 1.05 1.10 1.0 1.0 1.06 1.10 0.8];
seeds = [1 2 3 4 5];
requestedSwarmSize = 40;
requestedMaxIterations = 80;

useParticleswarm = exist('particleswarm', 'file') == 2 && license('test', 'GADS_Toolbox');
if useParticleswarm
    swarmSize = requestedSwarmSize;
    maxIterations = requestedMaxIterations;
else
    % The fallback is deliberately stronger than the previous quick PSO but
    % smaller than particleswarm settings so it can finish without the
    % Global Optimization Toolbox in a live validation session.
    swarmSize = 8;
    maxIterations = 8;
end
seedRows = {};
allHistory = table();
bestF = inf;
bestX = [];
bestSeed = NaN;

defaultParams = default_control_params();
defaultScore = evaluate_candidate_params(defaultParams, trainingScenarios, baseRefs);

for s = 1:numel(seeds)
    rng(seeds(s));
    obj = @(x) pso_objective_function_v2(x, trainingScenarios, baseRefs);
    if useParticleswarm
        historyValues = [];
        opts = optimoptions('particleswarm', 'SwarmSize', swarmSize, ...
            'MaxIterations', maxIterations, 'Display', 'off', 'OutputFcn', @outfun);
        [x, f] = particleswarm(obj, 9, lb, ub, opts);
        history = table(repmat(seeds(s), numel(historyValues), 1), ...
            (0:numel(historyValues)-1)', historyValues(:), ...
            'VariableNames', {'Seed', 'Iteration', 'BestObjective'});
        solverName = 'particleswarm';
    else
        opts = struct('SwarmSize', swarmSize, 'MaxIterations', maxIterations, 'Display', 'off');
        [x, f, historyRaw] = custom_pso_fallback(obj, lb, ub, opts);
        history = table(repmat(seeds(s), height(historyRaw), 1), ...
            historyRaw.Iteration, historyRaw.BestObjective, ...
            'VariableNames', {'Seed', 'Iteration', 'BestObjective'});
        solverName = 'custom_pso_fallback';
    end
    allHistory = [allHistory; history]; %#ok<AGROW>
    seedRows(end + 1, :) = {seeds(s), f, solverName}; %#ok<AGROW>
    if f < bestF
        bestF = f;
        bestX = x;
        bestSeed = seeds(s);
    end
end

bestParams = vector_to_control_params(bestX);
bestTrainingScore = evaluate_candidate_params(bestParams, trainingScenarios, baseRefs);
testRefs = build_base_refs(testScenarios);
bestTestScore = evaluate_candidate_params(bestParams, testScenarios, testRefs);

seedSummary = cell2table(seedRows, 'VariableNames', {'Seed', 'BestObjective', 'Solver'});
seedStats = table(mean(seedSummary.BestObjective), std(seedSummary.BestObjective), ...
    min(seedSummary.BestObjective), bestSeed, defaultScore.objective, bestF, ...
    requestedSwarmSize, requestedMaxIterations, swarmSize, maxIterations, ...
    'VariableNames', {'MeanObjective', 'StdObjective', 'BestObjective', ...
    'BestSeed', 'DefaultHybridObjective', 'OptimizedHybridObjective', ...
    'RequestedSwarmSize', 'RequestedMaxIterations', 'ActualSwarmSize', 'ActualMaxIterations'});

bestParamTable = struct2table(bestParams);
bestParamTable.OptimizedHybridObjective = bestF;
bestParamTable.DefaultHybridObjective = defaultScore.objective;

writetable(seedSummary, fullfile(resultDir, 'tables', 'pso_seed_summary.csv'));
writetable(seedStats, fullfile(resultDir, 'tables', 'pso_seed_statistics.csv'));
writetable(bestParamTable, fullfile(resultDir, 'tables', 'pso_best_params.csv'));
writetable(bestTrainingScore.scenarioTable, fullfile(resultDir, 'tables', 'pso_training_scenario_scores.csv'));
writetable(bestTestScore.scenarioTable, fullfile(resultDir, 'tables', 'pso_test_scenario_scores.csv'));
writetable(allHistory, fullfile(resultDir, 'tables', 'pso_convergence_all_seeds.csv'));
writetable(allHistory(allHistory.Seed == bestSeed, {'Iteration', 'BestObjective'}), ...
    fullfile(resultDir, 'tables', 'pso_convergence.csv'));

save(fullfile(resultDir, 'mat_files', 'best_params_v2.mat'), ...
    'bestParams', 'bestX', 'bestF', 'bestSeed', 'defaultScore', 'bestTrainingScore', 'bestTestScore');
save(fullfile(resultDir, 'mat_files', 'best_params.mat'), ...
    'bestParams', 'bestX', 'bestF', 'solverName');

plot_all_seed_convergence(allHistory, fullfile(resultDir, 'figures', 'pso_convergence_all_seeds.png'));
plot_pso_convergence(allHistory(allHistory.Seed == bestSeed, {'Iteration', 'BestObjective'}), ...
    fullfile(resultDir, 'figures', 'pso_convergence.png'));

psoResult.bestParams = bestParams;
psoResult.bestX = bestX;
psoResult.bestF = bestF;
psoResult.bestSeed = bestSeed;
psoResult.defaultObjective = defaultScore.objective;
psoResult.solverName = solverName;
fprintf('PSO v2 complete. Default J = %.4g, optimized J = %.4g.\n', ...
    defaultScore.objective, bestF);

    function stop = outfun(optimValues, state)
        stop = false;
        if strcmp(state, 'iter') || strcmp(state, 'init')
            historyValues(end + 1, 1) = optimValues.bestfval;
        end
    end
end

function refs = build_base_refs(scenarios)
net = ieee33_data();
for i = 1:numel(scenarios)
    m = local_metrics(net, scenarios(i), 'none', default_control_params());
    if i == 1
        refs = repmat(m, numel(scenarios), 1);
    else
        refs(i) = m;
    end
end
end

function m = local_metrics(net, sc, strategy, params)
pv = apply_pv_penetration(net, sc.pvPercent, sc.pvBuses, sc.pvWeights);
V = zeros(numel(sc.loadProfile.time_h), net.nBus);
loss = 0; curt = 0; qUsage = 0; availablePV = 0; reactiveCap = 0;
allConverged = true;
for t = 1:numel(sc.loadProfile.time_h)
    r = apply_smart_inverter_control(net, pv, sc.loadProfile.multiplier(t), ...
        sc.irrProfile.irradiance(t), strategy, params);
    V(t, :) = r.lf.Vmag(:)';
    loss = loss + r.lf.Ploss_kW;
    curt = curt + sum(r.Pcurtailed_kW);
    qUsage = qUsage + sum(abs(r.Qpv_kVAr));
    availablePV = availablePV + sum(r.Pavailable_pu) * net.baseMVA * 1000;
    reactiveCap = reactiveCap + sum(pv.Sinv_pu) * net.baseMVA * 1000;
    allConverged = allConverged && r.lf.converged;
end
m.meanAbsVoltageDeviation = mean(abs(V(:) - 1));
m.maxAbsVoltageDeviation = max(abs(V(:) - 1));
m.violationCount = sum(V(:) < net.Vmin | V(:) > net.Vmax);
m.overvoltageCount = sum(V(:) > net.Vmax);
m.undervoltageCount = sum(V(:) < net.Vmin);
m.loss_kWh = loss;
m.curtailment_kWh = curt;
m.reactiveUsage_kVArh = qUsage;
m.availablePV_kWh = availablePV;
m.reactiveCapability_kVArh = reactiveCap;
m.maxVoltage = max(V(:));
m.minVoltage = min(V(:));
m.hasNonFinite = any(~isfinite(V(:)));
m.allConverged = allConverged;
m.maxSlimitViolation = 0;
end

function [trainingScenarios, testScenarios] = build_pso_scenarios()
normalLoad = create_load_profile('mixed', 1);
partialCloud = create_irradiance_profile('partial_cloud', 1);
stressLoad = create_stress_load_profile(1);
stressIrr = create_stress_irradiance_profile(1);
normalLoad = subset_profile(normalLoad, 10:2:16);
partialCloud = subset_profile(partialCloud, 10:2:16);
stressLoad = subset_profile(stressLoad, 10:2:16);
stressIrr = subset_profile(stressIrr, 10:2:16);
defaultBuses = select_pv_buses();
stressBuses = select_pv_buses('stress_end_buses');
stressWeights = [0.8 0.9 1.0 1.0 1.1 1.2];

trainingScenarios = struct( ...
    'name', {'normal_80_partial_cloud', 'stress_120_clear', 'stress_150_clear', 'stress_low_load_high_pv'}, ...
    'pvPercent', {80, 120, 150, 180}, ...
    'loadProfile', {normalLoad, stressLoad, stressLoad, stressLoad}, ...
    'irrProfile', {partialCloud, stressIrr, stressIrr, stressIrr}, ...
    'pvBuses', {defaultBuses, stressBuses, stressBuses, stressBuses}, ...
    'pvWeights', {[], stressWeights, stressWeights, stressWeights});

testScenarios = struct( ...
    'name', {'stress_100_clear', 'stress_180_clear', 'stress_200_clear'}, ...
    'pvPercent', {100, 180, 200}, ...
    'loadProfile', {stressLoad, stressLoad, stressLoad}, ...
    'irrProfile', {stressIrr, stressIrr, stressIrr}, ...
    'pvBuses', {stressBuses, stressBuses, stressBuses}, ...
    'pvWeights', {stressWeights, stressWeights, stressWeights});
end

function profile = subset_profile(profile, idx)
idx = idx(idx >= 1 & idx <= numel(profile.time_h));
profile.time_h = profile.time_h(idx);
if isfield(profile, 'multiplier')
    profile.multiplier = profile.multiplier(idx);
end
if isfield(profile, 'irradiance')
    profile.irradiance = profile.irradiance(idx);
end
end

function plot_all_seed_convergence(history, outputFile)
fig = figure('Color', 'w', 'Position', [100 100 900 520]);
hold on; grid on;
seeds = unique(history.Seed);
for i = 1:numel(seeds)
    idx = history.Seed == seeds(i);
    plot(history.Iteration(idx), history.BestObjective(idx), 'LineWidth', 1.4, ...
        'DisplayName', sprintf('Seed %d', seeds(i)));
end
xlabel('Iteration');
ylabel('Best Objective');
title('PSO v2 Convergence Across Seeds');
legend('Location', 'best');
exportgraphics(fig, outputFile, 'Resolution', 220);
savefig(fig, replace(outputFile, '.png', '.fig'));
close(fig);
end
