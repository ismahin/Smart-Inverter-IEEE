function create_performance_indices_subsystem(modelName, position)
%CREATE_PERFORMANCE_INDICES_SUBSYSTEM Draw study metrics and saved outputs.

h = visualization_helpers();
systemName = [modelName '/Performance Indices'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [0.94 0.90 1.00]);

h.inport(systemName, 'voltage_data', 1, [25 85 55 99]);
h.inport(systemName, 'loss_data', 2, [25 135 55 149]);
h.inport(systemName, 'curtailment_data', 3, [25 185 55 199]);
h.inport(systemName, 'activation_data', 4, [25 235 55 249]);
h.outport(systemName, 'Metrics', 1, [910 150 940 164]);
h.outport(systemName, 'all_case_summary_csv', 2, [910 310 940 324]);
h.outport(systemName, 'stress_case_summary_csv', 3, [910 345 940 359]);
h.outport(systemName, 'hosting_capacity_summary_csv', 4, [910 380 940 394]);
h.outport(systemName, 'pso_best_params_csv', 5, [910 415 940 429]);
h.outport(systemName, 'final_interpretation_md', 6, [910 450 940 464]);

metricLabels = { ...
    'Min Voltage'
    'Max Voltage'
    'Mean Voltage Deviation'
    'Maximum Voltage Deviation'
    'Number of Voltage Violations'
    'Total Power Loss'
    'PV Curtailment'
    'Hosting Capacity'
    'Quasi-static Voltage Recovery Steps'
    'PSO Objective Function'};
for index = 1:numel(metricLabels)
    column = floor((index - 1) / 5);
    row = mod(index - 1, 5);
    x = 115 + column * 265;
    y = 55 + row * 60;
    h.visual(systemName, metricLabels{index}, [x y x + 220 y + 38], ...
        [0.96 0.93 1.00], metricLabels{index});
end

add_block('simulink/Signal Routing/Mux', [systemName '/Metric Inputs'], ...
    'Inputs', '4', 'Position', [650 80 655 245]);
for index = 1:4
    h.connect(systemName, sprintf('%s/1', get_param([systemName '/' get_input_name(index)], 'Name')), ...
        sprintf('Metric Inputs/%d', index), '');
end
h.visual(systemName, 'Calculate Metrics', [700 120 845 195], [0.88 0.82 1.00], ...
    'Calculate Metrics');
h.connect(systemName, 'Metric Inputs/1', 'Calculate Metrics/1', 'case data');
h.connect(systemName, 'Calculate Metrics/1', 'Metrics/1', 'Metrics');

h.visual(systemName, 'Save Tables and Figures', [650 290 845 465], [0.90 0.84 1.00], ...
    'Save Tables and Figures');
add_block('simulink/Sources/Constant', [systemName '/Saved File Placeholders'], ...
    'Value', '0', 'Position', [855 385 880 405]);
for outputIndex = 2:6
    h.connect(systemName, 'Saved File Placeholders/1', ...
        sprintf('%s/1', get_output_name(outputIndex)), '');
end

h.note(systemName, ...
    sprintf('Saved outputs:\\nall_case_summary.csv\\nstress_case_summary.csv\\nhosting_capacity_summary.csv\\npso_best_params.csv\\nfinal_interpretation.md'), ...
    [650 490 920 610], 10, 'white');
h.note(systemName, ...
    'Performance indices are calculated after each simulation case.', ...
    [110 370 560 405], 11, 'lightBlue');
end

function name = get_input_name(index)
names = {'voltage_data', 'loss_data', 'curtailment_data', 'activation_data'};
name = names{index};
end

function name = get_output_name(index)
names = {'Metrics', 'all_case_summary_csv', 'stress_case_summary_csv', ...
    'hosting_capacity_summary_csv', 'pso_best_params_csv', 'final_interpretation_md'};
name = names{index};
end
