function create_control_system_subsystem(modelName, position)
%CREATE_CONTROL_SYSTEM_SUBSYSTEM Draw strategy selection and offline PSO.

h = visualization_helpers();
systemName = [modelName '/Control System - Smart Inverter Control'];
add_block('simulink/Ports & Subsystems/Subsystem', systemName, 'Position', position);
h.clear(systemName);
h.styleSection(systemName, [1.00 0.97 0.82]);

h.inport(systemName, 'V_meas', 1, [25 100 55 114]);
h.inport(systemName, 'P_available', 2, [25 160 55 174]);
h.inport(systemName, 'Metrics', 3, [25 340 55 354]);
h.inport(systemName, 'control_mode', 4, [25 400 55 414]);
h.outport(systemName, 'P_ref', 1, [850 175 880 189]);
h.outport(systemName, 'Q_ref', 2, [850 225 880 239]);

h.visual(systemName, 'Volt-VAR Control', [145 65 315 125], [1.00 0.93 0.66], ...
    'Volt-VAR Control  Q = f(V)');
h.visual(systemName, 'Volt-Watt Control', [145 145 315 205], [1.00 0.93 0.66], ...
    'Volt-Watt Control  P = f(V)');
h.visual(systemName, 'Hybrid Control', [145 225 315 295], [1.00 0.90 0.58], ...
    'Hybrid: Volt-VAR + Volt-Watt');
h.visual(systemName, 'PSO Optimization', [155 345 395 415], [1.00 0.78 0.90], ...
    'PSO Optimization (Offline)');

h.connect(systemName, 'V_meas/1', 'Volt-VAR Control/1', 'V_meas');
h.connect(systemName, 'V_meas/1', 'Volt-Watt Control/1', 'V_meas');
h.connect(systemName, 'V_meas/1', 'Hybrid Control/1', 'V_meas');
h.connect(systemName, 'Metrics/1', 'PSO Optimization/1', 'voltage deviation, violations, losses, curtailment');

add_block('simulink/Signal Routing/Mux', [systemName '/Strategy Mux'], ...
    'Inputs', '4', 'Position', [470 95 475 300]);
h.connect(systemName, 'Volt-VAR Control/1', 'Strategy Mux/1', 'Q_ref');
h.connect(systemName, 'Volt-Watt Control/1', 'Strategy Mux/2', 'P_ref');
h.connect(systemName, 'Hybrid Control/1', 'Strategy Mux/3', 'P_ref, Q_ref');
h.connect(systemName, 'control_mode/1', 'Strategy Mux/4', 'control_mode');

h.visual(systemName, 'Control Mode Selector', [555 145 725 245], [1.00 0.95 0.78], ...
    'Control Mode Selector');
h.connect(systemName, 'Strategy Mux/1', 'Control Mode Selector/1', 'candidate controls');
add_block('simulink/Signal Routing/Demux', [systemName '/Selected PQ References'], ...
    'Outputs', '2', 'Position', [770 165 775 245]);
h.connect(systemName, 'Control Mode Selector/1', 'Selected PQ References/1', 'selected P_ref, Q_ref');
h.connect(systemName, 'Selected PQ References/1', 'P_ref/1', 'P_ref');
h.connect(systemName, 'Selected PQ References/2', 'Q_ref/1', 'Q_ref');

add_block('simulink/Sinks/Terminator', [systemName '/PSO Parameter Sink'], ...
    'Position', [465 370 485 390]);
h.connect(systemName, 'PSO Optimization/1', 'PSO Parameter Sink/1', ...
    'V1 V2 V3 V4 Qinj Qabs VW_start VW_end Pmin');

h.note(systemName, ...
    sprintf('Control modes:\\n1. No control\\n2. Volt-VAR\\n3. Volt-Watt\\n4. Hybrid\\n5. Hybrid + PSO'), ...
    [590 270 815 385], 10, 'white');
h.note(systemName, ...
    'Control mode selector chooses the inverter strategy for comparison.', ...
    [55 465 780 495], 11, 'lightBlue');
h.note(systemName, ...
    'PSO may be run offline. Optimized parameters are then applied to Hybrid Control.', ...
    [55 505 780 535], 10, 'yellow');
end
