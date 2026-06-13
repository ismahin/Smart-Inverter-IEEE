function simData = prepare_simulink_visualization_data(scenarioName, controlStrategy)
%PREPARE_SIMULINK_VISUALIZATION_DATA Load result signals for Simulink scopes.
%
% Example:
%   startup_project
%   prepare_simulink_visualization_data('proposal_80pct_partial_cloud','hybrid_pso')
%   sim('Smart_Inverter_IEEE33_Results_Viewer')

if nargin < 1 || isempty(scenarioName)
    scenarioName = 'proposal_80pct_partial_cloud';
end
if nargin < 2 || isempty(controlStrategy)
    controlStrategy = 'hybrid_pso';
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(projectRoot, 'results');

switch lower(scenarioName)
    case 'proposal_80pct_partial_cloud'
        matFile = fullfile(resultDir, 'mat_files', 'full_results.mat');
        scenarioKey = sprintf('P80_partial_cloud_%s', controlStrategy);
        data = load(matFile, 'allResults');
        scenario = data.allResults.(matlab.lang.makeValidName(scenarioKey));
    case 'stress_100pct_clear_low_daytime'
        matFile = fullfile(resultDir, 'mat_files', 'stress_results.mat');
        scenarioKey = sprintf('Stress_P100_%s', controlStrategy);
        data = load(matFile, 'stressResults');
        scenario = data.stressResults.(matlab.lang.makeValidName(scenarioKey));
    otherwise
        error('Unknown scenarioName: %s', scenarioName);
end

time = scenario.time_h(:);
voltageMatrix = scenario.Vmag;
minVoltage = min(voltageMatrix, [], 2);
maxVoltage = max(voltageMatrix, [], 2);
meanVoltage = mean(voltageMatrix, 2);
meanAbsDeviation = mean(abs(voltageMatrix - 1), 2);

simData.scenarioName = scenarioName;
simData.controlStrategy = controlStrategy;
simData.time_h = time;
simData.voltageMatrix = voltageMatrix;
simData.minVoltage = minVoltage;
simData.maxVoltage = maxVoltage;
simData.meanVoltage = meanVoltage;
simData.meanAbsDeviation = meanAbsDeviation;
simData.loss_kW = scenario.loss_kW(:);
simData.violations = scenario.violations(:);
simData.curtail_kW = scenario.curtail_kW(:);
simData.q_kVAr = scenario.q_kVAr(:);
simData.loadMultiplier = scenario.loadMultiplier(:);
simData.irradiance = scenario.irradiance(:);

assignin('base', 'sim_voltage_all_buses', timeseries(voltageMatrix, time));
assignin('base', 'sim_voltage_envelope', timeseries([minVoltage maxVoltage meanVoltage], time));
assignin('base', 'sim_voltage_deviation', timeseries(meanAbsDeviation, time));
assignin('base', 'sim_losses', timeseries(simData.loss_kW, time));
assignin('base', 'sim_violations', timeseries(simData.violations, time));
assignin('base', 'sim_pv_curtailment', timeseries(simData.curtail_kW, time));
assignin('base', 'sim_reactive_power', timeseries(simData.q_kVAr, time));
assignin('base', 'sim_profiles', timeseries([simData.loadMultiplier simData.irradiance], time));
assignin('base', 'simData', simData);

fprintf('Loaded Simulink visualization data: %s / %s\n', scenarioName, controlStrategy);
end
