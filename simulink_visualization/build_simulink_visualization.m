%BUILD_SIMULINK_VISUALIZATION Build the thesis workflow visualization model.
%
% Quasi-static MATLAB/Simulink workflow visualization for IEEE 33-bus
% smart inverter control. Numerical results remain in the MATLAB load-flow
% and controller scripts; this model presents the complete study workflow.

visualizationDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(visualizationDir);
addpath(projectRoot);
addpath(visualizationDir);
startup_project();

modelName = 'IEEE33bus_SmartInverter_Hybrid_PSO';
modelFile = fullfile(visualizationDir, [modelName '.slx']);

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist(modelFile, 'file') == 2
    delete(modelFile);
end

new_system(modelName);
open_system(modelName);
set_param(modelName, ...
    'Location', [40 40 1760 860], ...
    'ZoomFactor', 'FitSystem', ...
    'PreLoadFcn', callback_preload(), ...
    'InitFcn', callback_init(), ...
    'StopFcn', callback_stop());

create_ieee33_network_subsystem(modelName, [40 145 500 560]);
create_pv_generation_subsystem(modelName, [540 145 820 410]);
create_smart_inverter_subsystem(modelName, [850 145 1080 410]);
create_control_system_subsystem(modelName, [1110 145 1480 410]);
create_measurement_output_subsystem(modelName, [1510 145 1700 410]);
create_results_analysis_subsystem(modelName, [1510 450 1700 700]);
create_scenario_subsystem(modelName, [540 450 940 700]);
create_performance_indices_subsystem(modelName, [980 450 1480 700]);
add_matlab_engine_launcher(modelName);
add_block('simulink/Signal Attributes/Signal Specification', ...
    [modelName '/Voltage Profile Tap'], ...
    'Position', [1450 115 1480 135], ...
    'ShowName', 'off');

add_title(modelName, ...
    'Smart Inverter Control Using Volt-VAR, Volt-Watt and Hybrid Control with PSO Optimization in IEEE 33-Bus Distribution Network', ...
    [350 28 1450 68], 18, 'bold', 'yellow');
add_title(modelName, ...
    'Quasi-static MATLAB/Simulink workflow visualization for IEEE 33-bus smart inverter control.', ...
    [470 76 1350 106], 12, 'bold', 'lightBlue');
add_title(modelName, ...
    'MATLAB numerical engine: load flow, controller comparison, stress cases, hosting capacity and offline PSO.', ...
    [50 735 1110 765], 11, 'normal', 'white');

% Major workflow signal paths.
connect(modelName, 'Simulation Scenarios/4', 'PV Generation at Selected Buses/1', 'Irradiance_Profile');
connect(modelName, 'Simulation Scenarios/2', 'PV Generation at Selected Buses/3', 'PV_Penetration_Level');
connect(modelName, 'Simulation Scenarios/3', 'Control System - Smart Inverter Control/4', 'control_mode');
connect(modelName, 'PV Generation at Selected Buses/1', 'Smart Inverter - VSI/3', 'Ppv_available');
connect(modelName, 'PV Generation at Selected Buses/1', 'Control System - Smart Inverter Control/2', 'Ppv_available');
connect(modelName, 'IEEE 33-Bus Distribution Network/1', 'Control System - Smart Inverter Control/1', 'V_meas');
connect(modelName, 'IEEE 33-Bus Distribution Network/1', 'Smart Inverter - VSI/4', 'V_meas');
connect(modelName, 'Control System - Smart Inverter Control/1', 'Smart Inverter - VSI/1', 'P_ref');
connect(modelName, 'Control System - Smart Inverter Control/2', 'Smart Inverter - VSI/2', 'Q_ref');
connect(modelName, 'Smart Inverter - VSI/1', 'IEEE 33-Bus Distribution Network/1', 'P_inj');
connect(modelName, 'Smart Inverter - VSI/2', 'IEEE 33-Bus Distribution Network/2', 'Q_inj');
connect(modelName, 'IEEE 33-Bus Distribution Network/1', 'Voltage Profile Tap/1', 'V_meas');
connect(modelName, 'Voltage Profile Tap/1', 'Measurements and Outputs/1', 'Voltage_Profile');
connect(modelName, 'IEEE 33-Bus Distribution Network/2', 'Measurements and Outputs/2', 'I_meas');
connect(modelName, 'IEEE 33-Bus Distribution Network/3', 'Measurements and Outputs/3', 'P_load');
connect(modelName, 'IEEE 33-Bus Distribution Network/4', 'Measurements and Outputs/4', 'Q_load');
connect(modelName, 'Smart Inverter - VSI/1', 'Measurements and Outputs/5', 'P_inj');
connect(modelName, 'Smart Inverter - VSI/2', 'Measurements and Outputs/6', 'Q_inj');
connect(modelName, 'Smart Inverter - VSI/3', 'Measurements and Outputs/7', 'Curtailment');
connect(modelName, 'Measurements and Outputs/1', 'Performance Indices/1', 'voltage_data');
connect(modelName, 'Measurements and Outputs/2', 'Performance Indices/2', 'Losses');
connect(modelName, 'Measurements and Outputs/3', 'Performance Indices/3', 'Curtailment');
connect(modelName, 'Measurements and Outputs/4', 'Performance Indices/4', 'activation_data');
connect(modelName, 'Performance Indices/1', 'Results and Analysis/1', 'Metrics');
connect(modelName, 'Measurements and Outputs/1', 'Results and Analysis/2', 'Voltage_Profile');
connect(modelName, 'Performance Indices/1', 'Control System - Smart Inverter Control/3', 'Metrics');

set_model_fonts(modelName);
save_system(modelName, modelFile);
export_simulink_visualization(modelName, projectRoot);
validate_visualization(modelName, modelFile, projectRoot);
fprintf('Created thesis workflow visualization:\n%s\n', modelFile);

function connect(modelName, source, destination, signalName)
lineHandle = add_line(modelName, source, destination, 'autorouting', 'on');
set_param(lineHandle, 'Name', signalName);
end

function add_matlab_engine_launcher(modelName)
pathName = [modelName '/Run MATLAB Engine'];
add_block('simulink/Ports & Subsystems/Subsystem', pathName, ...
    'Position', [40 590 500 700]);
clear_subsystem(pathName);
set_param(pathName, ...
    'BackgroundColor', 'orange', ...
    'ForegroundColor', 'black', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'OpenFcn', [ ...
        'try, evalin(''base'',''main_generate_final_results''); ' ...
        'catch ME, disp([''Pipeline launch failed: '' ME.message]); end']);
add_title(modelName, ...
    sprintf('Run MATLAB Engine:\\nmain_generate_final_results.m\\nDouble-click to launch full results pipeline'), ...
    [65 610 475 680], 11, 'bold', 'orange');
end

function clear_subsystem(pathName)
try
    Simulink.SubSystem.deleteContents(pathName);
catch
    blocks = find_system(pathName, 'SearchDepth', 1, 'Type', 'Block');
    for index = 1:numel(blocks)
        if ~strcmp(blocks{index}, pathName)
            delete_block(blocks{index});
        end
    end
end
end

function add_title(modelName, textValue, position, fontSize, weight, color)
annotation = Simulink.Annotation(modelName, textValue);
annotation.Position = position;
annotation.FontSize = fontSize;
annotation.FontWeight = weight;
annotation.BackgroundColor = color;
annotation.ForegroundColor = 'black';
annotation.Interpreter = 'off';
end

function set_model_fonts(modelName)
blocks = find_system(modelName, 'SearchDepth', 1, 'Type', 'Block');
for index = 1:numel(blocks)
    try
        set_param(blocks{index}, 'FontName', 'Arial', 'FontSize', 12);
    catch
    end
end
end

function textValue = callback_preload()
textValue = [ ...
    'try, if exist(''startup_project'',''file'') == 2, startup_project(); end, ' ...
    'catch ME, disp([''PreLoadFcn warning: '' ME.message]); end'];
end

function textValue = callback_init()
textValue = [ ...
    'try, ' ...
    'if exist(''ieee33_data'',''file'') == 2, assignin(''base'',''ieee33_visual_network'',ieee33_data()); end; ' ...
    'if exist(''default_control_params'',''file'') == 2, assignin(''base'',''ieee33_visual_control_params'',default_control_params()); end; ' ...
    'disp(''IEEE33 visualization initialized. MATLAB scripts provide numerical results.''); ' ...
    'catch ME, disp([''InitFcn warning: '' ME.message]); end'];
end

function textValue = callback_stop()
textValue = [ ...
    'try, disp(''IEEE33 visualization stopped. Use main_generate_final_results for refreshed tables and figures.''); ' ...
    'catch ME, disp([''StopFcn warning: '' ME.message]); end'];
end

function validate_visualization(modelName, modelFile, projectRoot)
assert(isfile(modelFile), 'Model file was not created.');
assert(bdIsLoaded(modelName), 'Model is not open after creation.');
expected = { ...
    'IEEE 33-Bus Distribution Network'
    'PV Generation at Selected Buses'
    'Smart Inverter - VSI'
    'Control System - Smart Inverter Control'
    'Measurements and Outputs'
    'Results and Analysis'
    'Simulation Scenarios'
    'Performance Indices'};
for index = 1:numel(expected)
    assert(getSimulinkBlockHandle([modelName '/' expected{index}]) > 0, ...
        'Missing top-level section: %s', expected{index});
end
lineHandles = find_system(modelName, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'line');
lineNames = string(get_param(lineHandles, 'Name'));
requiredLabels = ["V_meas" "Ppv_available" "P_ref" "Q_ref" "P_inj" ...
    "Q_inj" "Voltage_Profile" "Losses" "Curtailment" "Metrics"];
for index = 1:numel(requiredLabels)
    assert(any(lineNames == requiredLabels(index)), ...
        'Missing major signal label: %s', requiredLabels(index));
end
pngFile = fullfile(projectRoot, 'results', 'figures', 'simulink_visualization_overview.png');
assert(isfile(pngFile), 'PNG export was not created.');
readmeFile = fullfile(projectRoot, 'simulink_visualization', 'README_simulink_visualization.md');
assert(isfile(readmeFile), 'Visualization README is missing.');
fprintf('Visualization validation passed: model, PNG, 8 sections, labels and README are present.\n');
end
