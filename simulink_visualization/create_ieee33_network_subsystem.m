function create_ieee33_network_subsystem(modelName, position)
%CREATE_IEEE33_NETWORK_SUBSYSTEM Draw the IEEE 33-bus radial feeder.

h = visualization_helpers();
systemName = [modelName '/IEEE 33-Bus Distribution Network'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [0.93 0.90 1.00]);

h.inport(systemName, 'P_inj', 1, [25 440 55 454]);
h.inport(systemName, 'Q_inj', 2, [25 475 55 489]);
h.outport(systemName, 'V_meas', 1, [930 120 960 134]);
h.outport(systemName, 'I_meas', 2, [930 160 960 174]);
h.outport(systemName, 'P_load', 3, [930 200 960 214]);
h.outport(systemName, 'Q_load', 4, [930 240 960 254]);

add_block('simulink/Sources/Constant', [systemName '/Slack Bus - Utility Grid'], ...
    'Value', '1', 'Position', [35 150 95 190]);
set_param([systemName '/Slack Bus - Utility Grid'], ...
    'BackgroundColor', 'yellow', 'FontName', 'Arial', 'FontSize', 10);

mainY = 170;
mainX = 125:43:(125 + 43 * 17);
for bus = 1:18
    add_bus(systemName, bus, mainX(bus), mainY);
end
h.connect(systemName, 'Slack Bus - Utility Grid/1', 'Bus 1/1', 'Slack');
for bus = 1:17
    h.connect(systemName, sprintf('Bus %d/1', bus), sprintf('Bus %d/1', bus + 1), '');
end

add_branch(systemName, h, 2, 19:22, [168 168 168 168], [260 325 390 455]);
add_branch(systemName, h, 3, 23:25, [255 255 255], [260 335 410]);
add_branch(systemName, h, 6, 26:33, 125:88:(125 + 88 * 7), repmat(545, 1, 8));

h.visual(systemName, 'Three-Phase V-I Measurement', [790 105 900 155], ...
    [1.00 0.94 0.80], 'Three-Phase V-I Measurement');
h.connect(systemName, 'Bus 18/1', 'Three-Phase V-I Measurement/1', 'V-I measurement');
h.connect(systemName, 'Three-Phase V-I Measurement/1', 'V_meas/1', 'V_meas');

add_block('simulink/Sources/Constant', [systemName '/Current Measurement'], ...
    'Value', '0', 'Position', [800 165 850 185]);
add_block('simulink/Sources/Constant', [systemName '/Active Load'], ...
    'Value', '0', 'Position', [800 205 850 225]);
add_block('simulink/Sources/Constant', [systemName '/Reactive Load'], ...
    'Value', '0', 'Position', [800 245 850 265]);
h.connect(systemName, 'Current Measurement/1', 'I_meas/1', 'I_meas');
h.connect(systemName, 'Active Load/1', 'P_load/1', 'P_load');
h.connect(systemName, 'Reactive Load/1', 'Q_load/1', 'Q_load');

add_load(systemName, h, 18, [770 300 845 340]);
add_load(systemName, h, 22, [195 455 270 495]);
add_load(systemName, h, 25, [282 410 357 450]);
add_load(systemName, h, 33, [790 545 865 585]);
add_block('simulink/Sinks/Terminator', [systemName '/Injected P Sink'], ...
    'Position', [85 438 105 458]);
add_block('simulink/Sinks/Terminator', [systemName '/Injected Q Sink'], ...
    'Position', [85 473 105 493]);
h.connect(systemName, 'P_inj/1', 'Injected P Sink/1', 'P_inj');
h.connect(systemName, 'Q_inj/1', 'Injected Q Sink/1', 'Q_inj');

h.note(systemName, ...
    'IEEE 33-bus radial distribution feeder used for voltage regulation and PV hosting capacity analysis.', ...
    [40 25 900 58], 12, 'lightBlue');
h.note(systemName, 'Bus 18 and Bus 33 are weak/end-feeder monitoring locations.', ...
    [510 610 920 640], 10, 'yellow');
end

function add_bus(systemName, busNumber, x, y)
h = visualization_helpers();
name = sprintf('Bus %d', busNumber);
h.visual(systemName, name, [x y x + 24 y + 24], [0.82 0.82 0.82], num2str(busNumber));
end

function add_branch(systemName, h, sourceBus, buses, xPositions, yPositions)
for index = 1:numel(buses)
    add_bus(systemName, buses(index), xPositions(index), yPositions(index));
end
h.connect(systemName, sprintf('Bus %d/1', sourceBus), sprintf('Bus %d/1', buses(1)), '');
for index = 2:numel(buses)
    h.connect(systemName, sprintf('Bus %d/1', buses(index - 1)), ...
        sprintf('Bus %d/1', buses(index)), '');
end
end

function add_load(systemName, h, busNumber, position)
name = sprintf('Load at Bus %d', busNumber);
h.visual(systemName, name, position, [1.00 0.88 0.82], sprintf('Load\\nBus %d', busNumber));
add_block('simulink/Sinks/Terminator', [systemName '/' name ' Sink'], ...
    'Position', [position(3) + 25 position(2) + 10 position(3) + 45 position(2) + 30]);
h.connect(systemName, sprintf('Bus %d/1', busNumber), [name '/1'], '');
h.connect(systemName, [name '/1'], [name ' Sink/1'], '');
end
