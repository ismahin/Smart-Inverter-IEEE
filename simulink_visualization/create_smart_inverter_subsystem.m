function create_smart_inverter_subsystem(modelName, position)
%CREATE_SMART_INVERTER_SUBSYSTEM Draw the high-level smart inverter chain.

h = visualization_helpers();
systemName = [modelName '/Smart Inverter - VSI'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [0.86 0.94 1.00]);

h.inport(systemName, 'P_ref', 1, [25 80 55 94]);
h.inport(systemName, 'Q_ref', 2, [25 120 55 134]);
h.inport(systemName, 'Ppv_available', 3, [25 190 55 204]);
h.inport(systemName, 'V_meas', 4, [25 300 55 314]);
h.outport(systemName, 'P_inj', 1, [730 175 760 189]);
h.outport(systemName, 'Q_inj', 2, [730 235 760 249]);
h.outport(systemName, 'Curtailment', 3, [730 295 760 309]);

h.visual(systemName, 'DC Link', [110 175 200 225], [0.78 0.91 1.00], 'DC Link');
h.visual(systemName, 'Three-Phase VSI', [270 160 390 240], [0.72 0.88 1.00], ...
    'Three-Phase VSI');
h.visual(systemName, 'LCL Filter', [455 175 545 225], [0.82 0.93 1.00], 'LCL Filter');
h.connect(systemName, 'Ppv_available/1', 'DC Link/1', 'Ppv_available');
h.connect(systemName, 'DC Link/1', 'Three-Phase VSI/1', 'Vdc');
h.connect(systemName, 'Three-Phase VSI/1', 'LCL Filter/1', 'AC output');
h.connect(systemName, 'LCL Filter/1', 'P_inj/1', 'P_inj');

add_block('simulink/Signal Routing/Mux', [systemName '/PQ Reference Mux'], ...
    'Inputs', '2', 'Position', [105 65 110 135]);
h.visual(systemName, 'P-Q Reference Input', [150 70 260 130], [1.00 0.96 0.78], ...
    'P/Q Reference Input');
add_block('simulink/Sinks/Terminator', [systemName '/Reference Sink'], ...
    'Position', [310 90 330 110]);
h.connect(systemName, 'P_ref/1', 'PQ Reference Mux/1', 'P_ref');
h.connect(systemName, 'Q_ref/1', 'PQ Reference Mux/2', 'Q_ref');
h.connect(systemName, 'PQ Reference Mux/1', 'P-Q Reference Input/1', 'P_ref, Q_ref');
h.connect(systemName, 'P-Q Reference Input/1', 'Reference Sink/1', '');

h.visual(systemName, 'Grid Synchronization PLL', [150 285 310 335], [0.88 0.95 1.00], ...
    'Grid Synchronization / PLL');
add_block('simulink/Sinks/Terminator', [systemName '/PLL Sink'], ...
    'Position', [350 300 370 320]);
h.connect(systemName, 'V_meas/1', 'Grid Synchronization PLL/1', 'V_meas');
h.connect(systemName, 'Grid Synchronization PLL/1', 'PLL Sink/1', 'phase angle');

add_block('simulink/Sources/Constant', [systemName '/Reactive Injection Placeholder'], ...
    'Value', '0', 'Position', [595 230 650 250]);
add_block('simulink/Sources/Constant', [systemName '/Curtailment Placeholder'], ...
    'Value', '0', 'Position', [595 290 650 310]);
h.connect(systemName, 'Reactive Injection Placeholder/1', 'Q_inj/1', 'Q_inj');
h.connect(systemName, 'Curtailment Placeholder/1', 'Curtailment/1', 'Curtailment');

h.visual(systemName, 'Inverter Capability Limit', [430 60 680 115], [1.00 0.94 0.80], ...
    'Capability Limit: sqrt(P^2 + Q^2) <= S_inv');
h.note(systemName, ...
    'Smart inverter injects active and reactive power while respecting apparent power limit.', ...
    [70 385 690 425], 11, 'lightBlue');
end
