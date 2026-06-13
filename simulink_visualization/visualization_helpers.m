function helpers = visualization_helpers()
%VISUALIZATION_HELPERS Shared drawing helpers for workflow subsystems.

helpers.clear = @clear_subsystem;
helpers.styleSection = @style_section;
helpers.styleBlock = @style_block;
helpers.note = @add_note;
helpers.visual = @add_visual_block;
helpers.inport = @add_inport;
helpers.outport = @add_outport;
helpers.connect = @connect;
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

function style_section(pathName, rgb)
displayText = strrep(get_param(pathName, 'Name'), '''', '''''');
maskDisplay = sprintf( ...
    'color(''black''); patch([0 1 1 0],[0 0 1 1],[%.3f %.3f %.3f]); disp(''%s'');', ...
    rgb(1), rgb(2), rgb(3), displayText);
set_param(pathName, ...
    'Mask', 'on', ...
    'MaskDisplay', maskDisplay, ...
    'MaskIconFrame', 'on', ...
    'MaskIconOpaque', 'on', ...
    'ForegroundColor', 'black', ...
    'FontName', 'Arial', ...
    'FontSize', 12, ...
    'FontWeight', 'bold');
end

function style_block(pathName, rgb, label)
displayText = strrep(label, '''', '''''');
maskDisplay = sprintf( ...
    'color(''black''); patch([0 1 1 0],[0 0 1 1],[%.3f %.3f %.3f]); disp(''%s'');', ...
    rgb(1), rgb(2), rgb(3), displayText);
set_param(pathName, ...
    'Mask', 'on', ...
    'MaskDisplay', maskDisplay, ...
    'MaskIconFrame', 'on', ...
    'MaskIconOpaque', 'on', ...
    'ShowName', 'off', ...
    'FontName', 'Arial', ...
    'FontSize', 10);
end

function add_note(systemName, textValue, position, fontSize, color)
annotation = Simulink.Annotation(systemName, textValue);
annotation.Position = position;
annotation.FontSize = fontSize;
annotation.BackgroundColor = color;
annotation.ForegroundColor = 'black';
annotation.Interpreter = 'off';
end

function add_visual_block(systemName, blockName, position, rgb, label)
pathName = [systemName '/' blockName];
add_block('simulink/Ports & Subsystems/Subsystem', pathName, 'Position', position);
clear_subsystem(pathName);
add_block('simulink/Ports & Subsystems/In1', [pathName '/In1'], ...
    'Position', [25 43 55 57]);
add_block('simulink/Ports & Subsystems/Out1', [pathName '/Out1'], ...
    'Position', [145 43 175 57]);
add_line(pathName, 'In1/1', 'Out1/1');
style_block(pathName, rgb, label);
end

function add_inport(systemName, blockName, portNumber, position)
add_block('simulink/Ports & Subsystems/In1', [systemName '/' blockName], ...
    'Port', num2str(portNumber), 'Position', position);
end

function add_outport(systemName, blockName, portNumber, position)
add_block('simulink/Ports & Subsystems/Out1', [systemName '/' blockName], ...
    'Port', num2str(portNumber), 'Position', position);
end

function connect(systemName, source, destination, signalName)
lineHandle = add_line(systemName, source, destination, 'autorouting', 'on');
if nargin > 3 && ~isempty(signalName)
    set_param(lineHandle, 'Name', signalName);
end
end
