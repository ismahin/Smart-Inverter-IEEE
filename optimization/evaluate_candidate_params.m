function score = evaluate_candidate_params(params, scenarios, baseRefs)
%EVALUATE_CANDIDATE_PARAMS Score one hybrid parameter set on scenarios.

net = ieee33_data();
weights = struct('meanDev', 10, 'maxDev', 20, 'viol', 500, ...
    'over', 50, 'under', 50, 'loss', 1, 'curt', 2, 'q', 0.2);

rows = {};
totalJ = 0;
feasibilityPenalty = 0;
for i = 1:numel(scenarios)
    sc = scenarios(i);
    metrics = simulate_scenario_metrics(net, sc, 'hybrid_pso', params);
    ref = baseRefs(i);
    if metrics.hasNonFinite || ~metrics.allConverged || metrics.maxSlimitViolation > 1e-6
        feasibilityPenalty = feasibilityPenalty + 1;
    end
    J = weights.meanDev * normalized(metrics.meanAbsVoltageDeviation, ref.meanAbsVoltageDeviation) ...
        + weights.maxDev * normalized(metrics.maxAbsVoltageDeviation, ref.maxAbsVoltageDeviation) ...
        + weights.viol * normalized(metrics.violationCount, max(ref.violationCount, 1)) ...
        + weights.over * normalized(metrics.overvoltageCount, max(ref.overvoltageCount, 1)) ...
        + weights.under * normalized(metrics.undervoltageCount, max(ref.undervoltageCount, 1)) ...
        + weights.loss * normalized(metrics.loss_kWh, ref.loss_kWh) ...
        + weights.curt * normalized(metrics.curtailment_kWh, max(ref.availablePV_kWh, 1)) ...
        + weights.q * normalized(metrics.reactiveUsage_kVArh, max(ref.reactiveCapability_kVArh, 1));
    totalJ = totalJ + J;
    rows(end + 1, :) = {sc.name, J, metrics.meanAbsVoltageDeviation, ...
        metrics.maxAbsVoltageDeviation, metrics.violationCount, ...
        metrics.overvoltageCount, metrics.undervoltageCount, metrics.loss_kWh, ...
        metrics.curtailment_kWh, metrics.reactiveUsage_kVArh, metrics.maxVoltage, metrics.minVoltage}; %#ok<AGROW>
end

constraintPenalty = parameter_constraint_penalty(params);
totalJ = totalJ / max(numel(scenarios), 1) + 100 * (constraintPenalty + feasibilityPenalty);

score.objective = totalJ;
score.scenarioTable = cell2table(rows, 'VariableNames', ...
    {'Scenario', 'ObjectiveContribution', 'MeanAbsVoltageDeviation', ...
    'MaxAbsVoltageDeviation', 'VoltageViolationCount', 'OvervoltageCount', ...
    'UndervoltageCount', 'Loss_kWh', 'Curtailment_kWh', 'ReactiveUsage_kVArh', ...
    'MaxVoltage', 'MinVoltage'});
score.constraintPenalty = constraintPenalty;
score.feasibilityPenalty = feasibilityPenalty;
end

function metrics = simulate_scenario_metrics(net, sc, strategy, params)
pv = apply_pv_penetration(net, sc.pvPercent, sc.pvBuses, sc.pvWeights);
V = zeros(numel(sc.loadProfile.time_h), net.nBus);
loss = 0;
curt = 0;
qUsage = 0;
availablePV = 0;
reactiveCap = 0;
allConverged = true;
maxSlimitViolation = 0;
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
    apparent = sqrt(r.Ppv_pu(:).^2 + r.Qpv_pu(:).^2);
    maxSlimitViolation = max(maxSlimitViolation, max(apparent - pv.Sinv_pu(:)));
end
metrics.meanAbsVoltageDeviation = mean(abs(V(:) - 1));
metrics.maxAbsVoltageDeviation = max(abs(V(:) - 1));
metrics.violationCount = sum(V(:) < net.Vmin | V(:) > net.Vmax);
metrics.overvoltageCount = sum(V(:) > net.Vmax);
metrics.undervoltageCount = sum(V(:) < net.Vmin);
metrics.loss_kWh = loss;
metrics.curtailment_kWh = curt;
metrics.reactiveUsage_kVArh = qUsage;
metrics.availablePV_kWh = availablePV;
metrics.reactiveCapability_kVArh = reactiveCap;
metrics.maxVoltage = max(V(:));
metrics.minVoltage = min(V(:));
metrics.hasNonFinite = any(~isfinite(V(:)));
metrics.allConverged = allConverged;
metrics.maxSlimitViolation = maxSlimitViolation;
end

function value = normalized(x, ref)
value = x / max(abs(ref), 1e-9);
end

function penalty = parameter_constraint_penalty(params)
x = [params.V1 params.V2 params.V3 params.V4 params.Qinj_frac params.Qabs_frac ...
    params.VW_Vstart params.VW_Vend params.Pmin_frac];
penalty = 0;
if ~(x(1) < x(2) && x(2) < x(3) && x(3) < x(4))
    penalty = penalty + 10;
end
if ~(x(7) < x(8))
    penalty = penalty + 10;
end
if x(2) > 1.00 || x(3) < 1.00
    penalty = penalty + 10;
end
end
