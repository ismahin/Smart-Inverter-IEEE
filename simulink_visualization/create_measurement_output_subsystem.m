function create_measurement_output_subsystem(modelName, position)
%CREATE_MEASUREMENT_OUTPUT_SUBSYSTEM Draw measurements and recorded outputs.

h = visualization_helpers();
systemName = [modelName '/Measurements and Outputs'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [1.00 0.88 0.90]);

inputNames = {'V_meas', 'I_meas', 'P_load', 'Q_load', 'P_inj', 'Q_inj', 'Curtailment'};
for index = 1:numel(inputNames)
    y = 65 + (index - 1) * 50;
    h.inport(systemName, inputNames{index}, index, [25 y 55 y + 14]);
end
h.outport(systemName, 'voltage_data', 1, [790 95 820 109]);
h.outport(systemName, 'loss_data', 2, [790 190 820 204]);
h.outport(systemName, 'curtailment_data', 3, [790 285 820 299]);
h.outport(systemName, 'activation_data', 4, [790 380 820 394]);

h.visual(systemName, 'Bus Voltages', [130 60 305 100], [1.00 0.92 0.92], 'Bus Voltages (p.u.)');
h.visual(systemName, 'Bus Currents', [130 110 305 150], [1.00 0.92 0.92], 'Bus Currents (A)');
h.visual(systemName, 'Active Power', [130 160 305 200], [1.00 0.92 0.92], 'Active Power (kW)');
h.visual(systemName, 'Reactive Power', [130 210 305 250], [1.00 0.92 0.92], 'Reactive Power (kVAr)');
h.visual(systemName, 'Power Losses', [390 165 565 205], [1.00 0.86 0.88], 'Power Losses (kW)');
h.visual(systemName, 'PV Curtailment', [390 260 565 300], [1.00 0.86 0.88], 'PV Curtailment (kWh)');
h.visual(systemName, 'Controller Activation Flags', [390 355 610 395], [1.00 0.86 0.88], ...
    'Controller Activation Flags');

h.connect(systemName, 'V_meas/1', 'Bus Voltages/1', 'V_meas');
h.connect(systemName, 'Bus Voltages/1', 'voltage_data/1', 'voltage_data');
h.connect(systemName, 'I_meas/1', 'Bus Currents/1', 'I_meas');
h.connect(systemName, 'P_load/1', 'Active Power/1', 'P_load');
h.connect(systemName, 'Q_load/1', 'Reactive Power/1', 'Q_load');
h.connect(systemName, 'Active Power/1', 'Power Losses/1', 'loss calculation');
h.connect(systemName, 'Power Losses/1', 'loss_data/1', 'loss_data');
h.connect(systemName, 'Curtailment/1', 'PV Curtailment/1', 'Curtailment');
h.connect(systemName, 'PV Curtailment/1', 'curtailment_data/1', 'curtailment_data');
h.connect(systemName, 'P_inj/1', 'Controller Activation Flags/1', 'controller activity');
h.connect(systemName, 'Controller Activation Flags/1', 'activation_data/1', 'activation_data');

add_sink(systemName, h, 'Bus Currents', 'current_data', [340 120 470 140]);
add_sink(systemName, h, 'Reactive Power', 'reactive_power_data', [340 220 470 240]);
add_sink(systemName, h, 'Bus Voltages', 'voltage_data_ws', [630 70 750 90]);
add_sink(systemName, h, 'Power Losses', 'loss_data_ws', [630 165 750 185]);
add_sink(systemName, h, 'PV Curtailment', 'curtailment_data_ws', [630 260 750 280]);
add_sink(systemName, h, 'Controller Activation Flags', 'activation_data_ws', [630 355 750 375]);
add_terminator(systemName, h, 'Q_inj', 'Q Injection Sink', [100 360 120 380]);

h.note(systemName, ...
    'Measurements are used to calculate voltage deviation, losses, curtailment and hosting capacity.', ...
    [70 455 760 495], 11, 'lightBlue');
end

function add_sink(systemName, h, sourceName, variableName, position)
blockName = ['To Workspace - ' variableName];
add_block('simulink/Sinks/To Workspace', [systemName '/' blockName], ...
    'VariableName', variableName, 'SaveFormat', 'Array', 'Position', position);
h.connect(systemName, [sourceName '/1'], [blockName '/1'], '');
end

function add_terminator(systemName, h, sourceName, blockName, position)
add_block('simulink/Sinks/Terminator', [systemName '/' blockName], 'Position', position);
h.connect(systemName, [sourceName '/1'], [blockName '/1'], '');
end
