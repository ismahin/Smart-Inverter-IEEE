function simulationOutput = run_ieee33_simscape_model(penetrationPercent, condition, strategy, openScopes)
%RUN_IEEE33_SIMSCAPE_MODEL Prepare, open, and simulate the physical model.

if nargin < 1 || isempty(penetrationPercent), penetrationPercent = 80; end
if nargin < 2 || isempty(condition), condition = 'partial_cloud'; end
if nargin < 3 || isempty(strategy), strategy = 'hybrid'; end
if nargin < 4 || isempty(openScopes), openScopes = true; end

physicalDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(physicalDir);
addpath(projectRoot);
addpath(physicalDir);
startup_project();
settings = prepare_ieee33_simscape_inputs(penetrationPercent, condition, strategy);

modelName = 'IEEE33_SmartInverter_Physical';
modelFile = fullfile(physicalDir, [modelName '.slx']);
if ~isfile(modelFile)
    build_ieee33_simscape_model();
end
load_system(modelFile);
set_param(modelName, 'StopTime', num2str(settings.stopTime_s));
if openScopes
    open_system(modelName);
    open_system([modelName '/All 33 Bus Voltages Scope']);
    open_system([modelName '/Voltage Envelope Scope']);
    open_system([modelName '/PV P-Q-Curtailment Scope']);
end

fprintf('Running %s: %g%% PV, %s, %s control.\n', ...
    modelName, penetrationPercent, condition, strategy);
simulationOutput = sim(modelName);
assignin('base', 'simscape_simulation_output', simulationOutput);
fprintf('Simulation finished. Scope time mapping: 0.1 s = 1 study hour.\n');
end
