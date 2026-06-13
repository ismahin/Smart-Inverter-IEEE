function J = pso_objective_function(x, net, pv, loadProfile, irrProfile, weights)
%PSO_OBJECTIVE_FUNCTION Weighted objective for optimized hybrid inverter control.

if nargin < 6 || isempty(weights)
    weights = struct('w1', 1, 'w2', 100, 'w3', 1, 'w4', 0.2, 'w5', 1000);
end

penalty = constraint_penalty(x);
params = vector_to_control_params(x);
nT = numel(loadProfile.time_h);
meanDev = zeros(nT, 1);
violations = zeros(nT, 1);
losses = zeros(nT, 1);
curtail = zeros(nT, 1);

try
    for t = 1:nT
        r = apply_smart_inverter_control(net, pv, loadProfile.multiplier(t), ...
            irrProfile.irradiance(t), 'hybrid_pso', params);
        vm = calculate_voltage_metrics(r.lf.Vmag, net);
        meanDev(t) = vm.meanAbsVoltageDeviation;
        violations(t) = vm.totalViolationCount;
        losses(t) = r.lf.Ploss_pu;
        curtail(t) = sum(r.Pcurtailed_pu);
        if ~r.lf.converged || any(~isfinite(r.lf.Vmag))
            penalty = penalty + 100;
        end
    end
    J = weights.w1 * mean(meanDev) ...
        + weights.w2 * sum(violations) ...
        + weights.w3 * sum(losses) ...
        + weights.w4 * sum(curtail) ...
        + weights.w5 * penalty;
catch
    J = 1e9 + weights.w5 * (1 + penalty);
end
end

function p = constraint_penalty(x)
p = 0;
ordered = [x(1) < x(2), x(2) < x(3), x(3) < x(4), x(7) < x(8)];
if ~all(ordered)
    p = p + sum(~ordered);
end
p = p + max(0, x(1) - x(2) + 1e-4) * 100;
p = p + max(0, x(2) - x(3) + 1e-4) * 100;
p = p + max(0, x(3) - x(4) + 1e-4) * 100;
p = p + max(0, x(7) - x(8) + 1e-4) * 100;
end
