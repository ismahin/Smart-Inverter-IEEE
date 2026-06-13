function create_smart_inverter_results_viewer()
%CREATE_SMART_INVERTER_RESULTS_VIEWER Create clean Simulink results viewer.
%
% This model is an English, ASCII-only visualization/replay model. It uses
% short block names, Arial fonts, clear colors, and grouped signal paths so
% the generated diagram is readable in Simulink.

startup_project();
if ~has_simulink()
    fprintf('Simulink is unavailable in this MATLAB session. Model creation skipped.\n');
    return;
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
model = 'Smart_Inverter_IEEE33_Results_Viewer';
modelPath = fullfile(projectRoot, 'simulink', [model '.slx']);
set_label_dir(fullfile(projectRoot, 'simulink', 'label_images'));

prepare_simulink_visualization_data('proposal_80pct_partial_cloud', 'hybrid_pso');

if bdIsLoaded(model)
    close_system(model, 0);
end
if exist(modelPath, 'file')
    delete(modelPath);
end

new_system(model);
open_system(model);
set_param(model, ...
    'StopTime', '23', ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '1', ...
    'ZoomFactor', 'FitSystem', ...
    'InitFcn', "startup_project; prepare_simulink_visualization_data('proposal_80pct_partial_cloud','hybrid_pso');");

% Group headings.
add_note(model, 'InputHeading', 'RESULT SIGNALS', [60 125 250 155], 12, 'bold');
add_note(model, 'VoltageHeading', 'VOLTAGE VISUALIZATION', [370 125 690 155], 12, 'bold');
add_note(model, 'MetricHeading', 'PERFORMANCE METRICS', [940 125 1260 155], 12, 'bold');

% Data replay blocks.
add_data_scope(model, 'BusVoltage', 'sim_voltage_all_buses', ...
    [80 190 240 230], [430 170 720 250], ...
    'Scope: 33 Bus Voltages', [0.88 0.95 1.00]);

add_data_scope(model, 'VoltageEnvelope', 'sim_voltage_envelope', ...
    [80 295 240 335], [430 275 720 355], ...
    'Scope: Min Mean Max Voltage', [0.88 1.00 0.88]);

add_data_scope(model, 'VoltageDeviation', 'sim_voltage_deviation', ...
    [80 400 240 440], [430 380 720 460], ...
    'Scope: Mean Voltage Deviation', [1.00 0.94 0.82]);

add_data_scope(model, 'Loss', 'sim_losses', ...
    [870 190 1030 230], [1220 170 1510 250], ...
    'Scope: Active Power Loss kW', [1.00 0.90 0.84]);

add_data_scope(model, 'Violations', 'sim_violations', ...
    [870 295 1030 335], [1220 275 1510 355], ...
    'Scope: Voltage Violations', [1.00 0.86 0.86]);

add_data_scope(model, 'Curtailment', 'sim_pv_curtailment', ...
    [870 400 1030 440], [1220 380 1510 460], ...
    'Scope: PV Curtailment kW', [0.92 0.92 1.00]);

add_data_scope(model, 'ReactivePower', 'sim_reactive_power', ...
    [80 535 240 575], [430 515 720 595], ...
    'Scope: Reactive Power kVAr', [0.94 0.90 1.00]);

add_data_scope(model, 'Profiles', 'sim_profiles', ...
    [870 535 1030 575], [1220 515 1510 595], ...
    'Scope: Load and Irradiance', [0.90 1.00 0.92]);

set_english_fonts(model);
save_system(model, modelPath);
export_model_image(model, projectRoot);
fprintf('Created clean Simulink results viewer:\n%s\n', modelPath);
end

function add_data_scope(model, baseName, variableName, dataPos, scopePos, scopeLabel, color)
dataBlock = [baseName '_Data'];
scopeBlock = [baseName '_Scope'];

add_source_subsystem(model, dataBlock, variableName, dataPos);
style_block([model '/' dataBlock], [0.92 0.96 1.00], 10);

add_block('simulink/Sinks/Scope', [model '/' scopeBlock], ...
    'Position', scopePos);
set_param([model '/' scopeBlock], 'OpenAtSimulationStart', 'on');
style_block([model '/' scopeBlock], color, 11);

add_line(model, [dataBlock '/1'], [scopeBlock '/1'], 'autorouting', 'on');

add_note(model, [baseName '_DataLabel'], ['Data: ' readable_name(baseName)], ...
    [dataPos(1) dataPos(2) - 28 dataPos(3) dataPos(2) - 4], 9, 'bold');
add_note(model, [baseName '_Label'], scopeLabel, ...
    [scopePos(1) scopePos(2) - 30 scopePos(3) scopePos(2) - 5], 10, 'bold');
end

function add_source_subsystem(model, blockName, variableName, position)
subPath = [model '/' blockName];
add_block('simulink/Ports & Subsystems/Subsystem', subPath, 'Position', position);
try
    Simulink.SubSystem.deleteContents(subPath);
catch
    inside = find_system(subPath, 'SearchDepth', 1, 'Type', 'Block');
    for k = 1:numel(inside)
        if ~strcmp(inside{k}, subPath)
            delete_block(inside{k});
        end
    end
end
add_block('simulink/Sources/From Workspace', [subPath '/InputData'], ...
    'Position', [40 45 170 75], 'VariableName', variableName);
add_block('simulink/Ports & Subsystems/Out1', [subPath '/Out1'], ...
    'Position', [230 48 260 72]);
add_line(subPath, 'InputData/1', 'Out1/1', 'autorouting', 'on');
set_param(subPath, ...
    'Mask', 'on', ...
    'MaskDisplay', "color('blue'); patch([0 1 1 0],[0 0 1 1],[0.35 0.70 0.93]);", ...
    'MaskIconFrame', 'on', ...
    'MaskIconOpaque', 'on');
end

function label = readable_name(baseName)
switch baseName
    case 'BusVoltage'
        label = '33 Bus Voltages';
    case 'VoltageEnvelope'
        label = 'Min Mean Max Voltage';
    case 'VoltageDeviation'
        label = 'Mean Voltage Deviation';
    case 'Loss'
        label = 'Active Power Loss';
    case 'Violations'
        label = 'Voltage Violations';
    case 'Curtailment'
        label = 'PV Curtailment';
    case 'ReactivePower'
        label = 'Reactive Power';
    case 'Profiles'
        label = 'Load and Irradiance';
    otherwise
        label = baseName;
end
end

function add_note(model, name, textValue, position, fontSize, weight)
annotation = Simulink.Annotation(model, ' ');
annotation.Name = name;
annotation.Position = position;
annotation.FixedWidth = 'on';
annotation.FixedHeight = 'on';
imageFile = make_label_image(name, textValue, position, fontSize, weight);
setImage(annotation, imageFile);
end

function style_block(blockPath, backgroundColor, fontSize)
set_param(blockPath, ...
    'BackgroundColor', rgb_to_color(backgroundColor), ...
    'ForegroundColor', 'black', ...
    'FontName', 'Courier New', ...
    'FontSize', fontSize, ...
    'ShowName', 'off');
end

function set_english_fonts(model)
blocks = find_system(model, 'SearchDepth', 1, 'Type', 'Block');
for k = 1:numel(blocks)
    try
        set_param(blocks{k}, 'FontName', 'Courier New', 'FontSize', 11);
    catch
    end
end
annotations = find_system(model, 'FindAll', 'on', 'Type', 'annotation');
for k = 1:numel(annotations)
    try
        set_param(annotations(k), 'FontName', 'Courier New', 'Interpreter', 'off');
    catch
    end
end
end

function colorName = rgb_to_color(rgb)
if isequal(rgb, [0.92 0.96 1.00])
    colorName = 'lightBlue';
elseif isequal(rgb, [1.00 0.86 0.86])
    colorName = 'red';
elseif isequal(rgb, [1.00 0.94 0.82])
    colorName = 'orange';
elseif isequal(rgb, [0.90 1.00 0.92]) || isequal(rgb, [0.88 1.00 0.88])
    colorName = 'green';
elseif isequal(rgb, [0.94 0.90 1.00]) || isequal(rgb, [0.92 0.92 1.00])
    colorName = 'lightBlue';
else
    colorName = 'white';
end
end

function labelDir = set_label_dir(pathName)
persistent storedLabelDir
if nargin > 0
    storedLabelDir = pathName;
    if ~exist(storedLabelDir, 'dir')
        mkdir(storedLabelDir);
    end
end
labelDir = storedLabelDir;
end

function pathName = get_label_dir()
pathName = set_label_dir();
end

function imageFile = make_label_image(name, textValue, position, fontSize, weight)
labelDir = get_label_dir();
safeName = regexprep(name, '[^A-Za-z0-9_]', '_');
imageFile = fullfile(labelDir, [safeName '.png']);
widthPx = max(220, round((position(3) - position(1)) * 1.4));
heightPx = max(38, round((position(4) - position(2)) * 1.6));

fig = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100 100 widthPx heightPx]);
ax = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off');
axis(ax, [0 1 0 1]);
text(ax, 0.5, 0.5, textValue, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontName', 'Arial', ...
    'FontSize', fontSize, ...
    'FontWeight', weight, ...
    'Interpreter', 'none', ...
    'Color', [0 0 0]);
exportgraphics(fig, imageFile, 'Resolution', 160, 'BackgroundColor', 'white');
close(fig);
end

function export_model_image(model, projectRoot)
imageFile = fullfile(projectRoot, 'results', 'figures', [model '.png']);
try
    Simulink.BlockDiagram.exportToImage(model, imageFile);
catch
    try
        print(['-s' model], '-dpng', imageFile);
    catch
        fprintf('Model image export skipped; open the SLX file to view the diagram.\n');
    end
end
end

function tf = has_simulink()
tf = license('test', 'Simulink') && ~isempty(which('new_system')) && ~isempty(which('add_block'));
end
