function J = pso_objective_function_v2(x, scenarios, baseRefs)
%PSO_OBJECTIVE_FUNCTION_V2 Multi-scenario normalized PSO objective.

params = vector_to_control_params(x);
score = evaluate_candidate_params(params, scenarios, baseRefs);
J = score.objective;
if ~isfinite(J)
    J = 1e12;
end
end
