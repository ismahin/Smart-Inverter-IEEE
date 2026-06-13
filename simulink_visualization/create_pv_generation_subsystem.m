function create_pv_generation_subsystem(modelName, position)
%CREATE_PV_GENERATION_SUBSYSTEM Draw selected-bus PV generation sources.

h = visualization_helpers();
systemName = [modelName '/PV Generation at Selected Buses'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [0.90 1.00 0.88]);

h.inport(systemName, 'Irradiance_Profile', 1, [25 110 55 124]);
h.inport(systemName, 'Temperature', 2, [25 155 55 169]);
h.inport(systemName, 'PV_Penetration_Level', 3, [25 200 55 214]);
h.outport(systemName, 'Ppv_available', 1, [790 185 820 199]);
h.outport(systemName, 'PV_bus_list', 2, [790 240 820 254]);

buses = [6 14 18 25 30 33];
for index = 1:numel(buses)
    y = 55 + (index - 1) * 72;
    pvName = sprintf('PV Array Bus %d', buses(index));
    mpptName = sprintf('MPPT DC-DC Bus %d', buses(index));
    h.visual(systemName, pvName, [110 y 220 y + 42], [0.72 0.94 0.72], ...
        sprintf('PV Array\\nBus %d', buses(index)));
    h.visual(systemName, mpptName, [280 y 400 y + 42], [0.86 0.98 0.82], ...
        'DC-DC / MPPT');
    h.connect(systemName, 'Irradiance_Profile/1', [pvName '/1'], '');
    h.connect(systemName, [pvName '/1'], [mpptName '/1'], '');
end

add_block('simulink/Signal Routing/Mux', [systemName '/Aggregate PV Power'], ...
    'Inputs', '6', 'Position', [510 120 515 380]);
for index = 1:numel(buses)
    h.connect(systemName, sprintf('MPPT DC-DC Bus %d/1', buses(index)), ...
        sprintf('Aggregate PV Power/%d', index), '');
end
h.connect(systemName, 'Aggregate PV Power/1', 'Ppv_available/1', 'Ppv_available');

add_block('simulink/Sources/Constant', [systemName '/Selected PV Bus List'], ...
    'Value', '[6 14 18 25 30 33]', 'Position', [575 230 720 265]);
h.connect(systemName, 'Selected PV Bus List/1', 'PV_bus_list/1', 'PV_bus_list');
add_block('simulink/Sinks/Terminator', [systemName '/Temperature Sink'], ...
    'Position', [90 150 110 170]);
add_block('simulink/Sinks/Terminator', [systemName '/PV Penetration Sink'], ...
    'Position', [90 195 110 215]);
h.connect(systemName, 'Temperature/1', 'Temperature Sink/1', 'Temperature');
h.connect(systemName, 'PV_Penetration_Level/1', 'PV Penetration Sink/1', 'PV_Penetration_Level');

h.note(systemName, ...
    sprintf('PV penetration levels:\\n20%%\\n50%%\\n80%%\\n100%%\\n150%%\\n200%%'), ...
    [610 320 760 475], 10, 'white');
h.note(systemName, ...
    'PV capacity is distributed across selected weak/end feeder buses. PV output follows irradiance profile.', ...
    [55 490 760 530], 11, 'lightBlue');
end
