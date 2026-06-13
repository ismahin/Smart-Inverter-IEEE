function create_scenario_subsystem(modelName, position)
%CREATE_SCENARIO_SUBSYSTEM Draw normal and stress scenario configuration.

h = visualization_helpers();
systemName = [modelName '/Simulation Scenarios'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [0.94 0.94 0.94]);

h.outport(systemName, 'scenario_id', 1, [870 95 900 109]);
h.outport(systemName, 'pv_penetration', 2, [870 155 900 169]);
h.outport(systemName, 'control_mode', 3, [870 215 900 229]);
h.outport(systemName, 'irradiance_case', 4, [870 275 900 289]);

h.visual(systemName, 'PV Penetration Levels', [80 80 300 280], [0.98 0.98 0.98], ...
    sprintf('PV Penetration Levels\\n20%%  50%%  80%%\\n100%%  150%%  200%%'));
h.visual(systemName, 'Control Modes', [350 80 570 280], [0.98 0.98 0.98], ...
    sprintf('Control Modes\\nNo control\\nVolt-VAR\\nVolt-Watt\\nHybrid\\nHybrid + PSO'));
h.visual(systemName, 'Irradiance and Load Conditions', [620 80 825 280], [0.98 0.98 0.98], ...
    sprintf('Irradiance / Load\\nClear sky\\nPartial cloud\\nLow irradiance\\nStress: low load, high PV'));

values = {'1', '80', '5', '1'};
outputNames = {'scenario_id', 'pv_penetration', 'control_mode', 'irradiance_case'};
for index = 1:numel(values)
    y = 95 + (index - 1) * 60;
    blockName = sprintf('Scenario Value %d', index);
    add_block('simulink/Sources/Constant', [systemName '/' blockName], ...
        'Value', values{index}, 'Position', [765 y 800 y + 20]);
    h.connect(systemName, [blockName '/1'], [outputNames{index} '/1'], outputNames{index});
end

h.note(systemName, ...
    'Normal scenarios evaluate proposal cases. Stress scenarios evaluate overvoltage and hosting capacity.', ...
    [90 350 820 395], 11, 'lightBlue');
end
