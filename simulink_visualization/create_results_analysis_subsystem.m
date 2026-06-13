function create_results_analysis_subsystem(modelName, position)
%CREATE_RESULTS_ANALYSIS_SUBSYSTEM Draw plots, tables and dashboard outputs.

h = visualization_helpers();
systemName = [modelName '/Results and Analysis'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [0.86 1.00 1.00]);

h.inport(systemName, 'Metrics', 1, [25 110 55 124]);
h.inport(systemName, 'Voltage_Profile', 2, [25 180 55 194]);

labels = { ...
    'Voltage Profile Plot'
    'Voltage Violation Count'
    'Power Loss Comparison'
    'PV Hosting Capacity'
    'PV Curtailment Comparison'
    'PSO Convergence Plot'};
for index = 1:numel(labels)
    y = 55 + (index - 1) * 55;
    h.visual(systemName, labels{index}, [125 y 340 y + 38], [0.84 0.98 1.00], labels{index});
end
h.visual(systemName, 'Final Result Dashboard', [465 150 700 245], [0.72 0.96 1.00], ...
    'Final Result Dashboard');

add_block('simulink/Sinks/Scope', [systemName '/Voltage Profile Scope'], ...
    'Position', [385 55 435 95]);
h.connect(systemName, 'Voltage_Profile/1', 'Voltage Profile Scope/1', 'Voltage_Profile');
h.connect(systemName, 'Metrics/1', 'Final Result Dashboard/1', 'Metrics');
add_block('simulink/Sinks/Terminator', [systemName '/Dashboard Sink'], ...
    'Position', [760 185 780 205]);
h.connect(systemName, 'Final Result Dashboard/1', 'Dashboard Sink/1', '');

h.note(systemName, ...
    'Results are generated using MATLAB scripts and saved as CSV tables and PNG figures.', ...
    [65 420 760 460], 11, 'lightBlue');
h.note(systemName, ...
    'Use results/figures and results/tables for thesis-ready outputs.', ...
    [95 475 720 510], 10, 'white');
end
