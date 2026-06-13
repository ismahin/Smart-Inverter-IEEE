function simOut = run_smart_inverter_results_viewer(scenarioName, controlStrategy)
%RUN_SMART_INVERTER_RESULTS_VIEWER Prepare data, create model, and simulate.

if nargin < 1 || isempty(scenarioName)
    scenarioName = 'proposal_80pct_partial_cloud';
end
if nargin < 2 || isempty(controlStrategy)
    controlStrategy = 'hybrid_pso';
end

startup_project();
prepare_simulink_visualization_data(scenarioName, controlStrategy);
create_smart_inverter_results_viewer();

model = 'Smart_Inverter_IEEE33_Results_Viewer';
set_param(model, 'InitFcn', sprintf( ...
    "startup_project; prepare_simulink_visualization_data('%s','%s');", ...
    scenarioName, controlStrategy));
save_system(model);
simOut = sim(model);
fprintf('Simulink results viewer finished for %s / %s.\n', scenarioName, controlStrategy);
end
