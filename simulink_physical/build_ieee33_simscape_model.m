function modelFile = build_ieee33_simscape_model()
%BUILD_IEEE33_SIMSCAPE_MODEL Build an executable component-based feeder.

physicalDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(physicalDir);
addpath(projectRoot);
addpath(physicalDir);
startup_project();
prepare_ieee33_simscape_inputs(80, 'partial_cloud', 'hybrid');

modelName = 'IEEE33_SmartInverter_Physical';
modelFile = fullfile(physicalDir, [modelName '.slx']);
if bdIsLoaded(modelName), close_system(modelName, 0); end
if isfile(modelFile), delete(modelFile); end

new_system(modelName);
load_system('ee_lib');
set_param(modelName, ...
    'Location', [40 40 1550 850], ...
    'Solver', 'ode23t', ...
    'StopTime', '2.4', ...
    'MaxStep', '1e-3', ...
    'RelTol', '1e-3', ...
    'PreLoadFcn', preload_callback());

add_block('simulink/Sources/From Workspace', [modelName '/24 h Load Profile'], ...
    'VariableName', 'simscape_load_scale', 'Interpolate', 'on', ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Position', [50 175 190 215]);
add_block('simulink/Sources/From Workspace', [modelName '/Solar Irradiance'], ...
    'VariableName', 'simscape_irradiance', 'Interpolate', 'on', ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Position', [50 265 190 305]);
add_block('simulink/Sources/From Workspace', [modelName '/PV P Commands'], ...
    'VariableName', 'simscape_pv_p_commands', 'Interpolate', 'on', ...
    'OutputAfterFinalValue', 'Holding final value', 'Position', [50 350 190 390]);
add_block('simulink/Sources/From Workspace', [modelName '/PV Q Commands'], ...
    'VariableName', 'simscape_pv_q_commands', 'Interpolate', 'on', ...
    'OutputAfterFinalValue', 'Holding final value', 'Position', [50 415 190 455]);
add_block('simulink/Sources/From Workspace', [modelName '/PV Curtail Commands'], ...
    'VariableName', 'simscape_pv_curtail_commands', 'Interpolate', 'on', ...
    'OutputAfterFinalValue', 'Holding final value', 'Position', [50 480 190 520]);

feeder = [modelName '/IEEE 33-Bus Physical Feeder'];
add_block('simulink/Ports & Subsystems/Subsystem', feeder, ...
    'Position', [270 120 680 500], 'BackgroundColor', 'lightBlue');
Simulink.SubSystem.deleteContents(feeder);
build_feeder(feeder);

add_block('simulink/Signal Routing/Mux', [modelName '/Profile Mux'], ...
    'Inputs', '2', 'Position', [245 565 250 615]);
add_block('simulink/Sinks/Scope', [modelName '/Profiles Scope'], ...
    'Position', [300 555 380 625], 'ShowLegend', 'on', ...
    'TimeSpan', '2.4', 'YLabel', 'Load / irradiance (p.u.)');
add_block('simulink/Sinks/Scope', [modelName '/All 33 Bus Voltages Scope'], ...
    'Position', [790 110 930 180], 'ShowLegend', 'off', ...
    'TimeSpan', '2.4', 'YLabel', 'Voltage (p.u.)', ...
    'AxesScaling', 'Manual', 'ActiveDisplayYMinimum', '0.85', ...
    'ActiveDisplayYMaximum', '1.15');
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/Hourly Settled Voltage Samples'], ...
    'SampleTime', '[0.1 0.085]', 'Position', [710 120 760 155]);
add_block('simulink/Math Operations/MinMax', [modelName '/Minimum Voltage'], ...
    'Function', 'min', 'Position', [765 225 810 255]);
add_block('simulink/Math Operations/MinMax', [modelName '/Maximum Voltage'], ...
    'Function', 'max', 'Position', [765 280 810 310]);
add_block('simulink/Signal Routing/Mux', [modelName '/Voltage Envelope Mux'], ...
    'Inputs', '2', 'Position', [855 230 860 305]);
add_block('simulink/Sinks/Scope', [modelName '/Voltage Envelope Scope'], ...
    'Position', [920 225 1060 310], 'ShowLegend', 'on', ...
    'TimeSpan', '2.4', 'YLabel', 'Min / max voltage (p.u.)', ...
    'AxesScaling', 'Manual', 'ActiveDisplayYMinimum', '0.85', ...
    'ActiveDisplayYMaximum', '1.15');
add_block('simulink/Signal Routing/Mux', [modelName '/PV Output Mux'], ...
    'Inputs', '3', 'Position', [795 365 800 470]);
add_block('simulink/Sinks/Scope', [modelName '/PV P-Q-Curtailment Scope'], ...
    'Position', [880 365 1060 470], 'ShowLegend', 'on', ...
    'TimeSpan', '2.4', 'YLabel', 'kW / kVAr');

add_workspace_sink(modelName, 'Bus Voltages To Workspace', 'simscape_bus_voltage_pu', [1130 105 1325 140]);
add_workspace_sink(modelName, 'Voltage Envelope To Workspace', 'simscape_voltage_envelope', [1130 240 1325 275]);
add_workspace_sink(modelName, 'PV Outputs To Workspace', 'simscape_pv_outputs', [1130 395 1325 430]);

add_line(modelName, '24 h Load Profile/1', 'IEEE 33-Bus Physical Feeder/1', 'autorouting', 'on');
add_line(modelName, 'Solar Irradiance/1', 'IEEE 33-Bus Physical Feeder/2', 'autorouting', 'on');
add_line(modelName, 'PV P Commands/1', 'IEEE 33-Bus Physical Feeder/3', 'autorouting', 'on');
add_line(modelName, 'PV Q Commands/1', 'IEEE 33-Bus Physical Feeder/4', 'autorouting', 'on');
add_line(modelName, 'PV Curtail Commands/1', 'IEEE 33-Bus Physical Feeder/5', 'autorouting', 'on');
add_line(modelName, '24 h Load Profile/1', 'Profile Mux/1', 'autorouting', 'on');
add_line(modelName, 'Solar Irradiance/1', 'Profile Mux/2', 'autorouting', 'on');
add_line(modelName, 'Profile Mux/1', 'Profiles Scope/1', 'autorouting', 'on');
add_line(modelName, 'IEEE 33-Bus Physical Feeder/1', 'Hourly Settled Voltage Samples/1', 'autorouting', 'on');
add_line(modelName, 'Hourly Settled Voltage Samples/1', 'All 33 Bus Voltages Scope/1', 'autorouting', 'on');
add_line(modelName, 'Hourly Settled Voltage Samples/1', 'Minimum Voltage/1', 'autorouting', 'on');
add_line(modelName, 'Hourly Settled Voltage Samples/1', 'Maximum Voltage/1', 'autorouting', 'on');
add_line(modelName, 'Minimum Voltage/1', 'Voltage Envelope Mux/1', 'autorouting', 'on');
add_line(modelName, 'Maximum Voltage/1', 'Voltage Envelope Mux/2', 'autorouting', 'on');
add_line(modelName, 'Voltage Envelope Mux/1', 'Voltage Envelope Scope/1', 'autorouting', 'on');
add_line(modelName, 'IEEE 33-Bus Physical Feeder/2', 'PV Output Mux/1', 'autorouting', 'on');
add_line(modelName, 'IEEE 33-Bus Physical Feeder/3', 'PV Output Mux/2', 'autorouting', 'on');
add_line(modelName, 'IEEE 33-Bus Physical Feeder/4', 'PV Output Mux/3', 'autorouting', 'on');
add_line(modelName, 'PV Output Mux/1', 'PV P-Q-Curtailment Scope/1', 'autorouting', 'on');
add_line(modelName, 'Hourly Settled Voltage Samples/1', 'Bus Voltages To Workspace/1', 'autorouting', 'on');
add_line(modelName, 'Voltage Envelope Mux/1', 'Voltage Envelope To Workspace/1', 'autorouting', 'on');
add_line(modelName, 'PV Output Mux/1', 'PV Outputs To Workspace/1', 'autorouting', 'on');

add_annotation(modelName, 'IEEE 33-BUS SMART-INVERTER PHYSICAL MODEL', [370 30 1120 65], 18, 'yellow');
add_annotation(modelName, 'Simscape Electrical components | accelerated day: 0.1 simulated s = 1 study hour', [395 70 1095 100], 12, 'lightBlue');
add_annotation(modelName, 'Double-click the blue feeder subsystem to inspect all line, load, sensor, solar-cell and inverter components.', [300 675 1080 720], 12, 'white');

save_system(modelName, modelFile);
open_system(modelName);
fprintf('Created executable Simscape Electrical model:\n%s\n', modelFile);
end

function build_feeder(feeder)
net = ieee33_data();
pvBuses = select_pv_buses('default');

add_block('simulink/Ports & Subsystems/In1', [feeder '/Load scale'], 'Port', '1', 'Position', [20 40 50 60]);
add_block('simulink/Ports & Subsystems/In1', [feeder '/Irradiance'], 'Port', '2', 'Position', [20 90 50 110]);
add_block('simulink/Ports & Subsystems/In1', [feeder '/PV P commands'], 'Port', '3', 'Position', [20 140 50 160]);
add_block('simulink/Ports & Subsystems/In1', [feeder '/PV Q commands'], 'Port', '4', 'Position', [20 180 50 200]);
add_block('simulink/Ports & Subsystems/In1', [feeder '/PV curtail commands'], 'Port', '5', 'Position', [20 220 50 240]);
add_block('simulink/Ports & Subsystems/Out1', [feeder '/Vbus pu'], 'Port', '1', 'Position', [3330 80 3360 100]);
add_block('simulink/Ports & Subsystems/Out1', [feeder '/PV P kW'], 'Port', '2', 'Position', [3330 130 3360 150]);
add_block('simulink/Ports & Subsystems/Out1', [feeder '/PV Q kVAr'], 'Port', '3', 'Position', [3330 180 3360 200]);
add_block('simulink/Ports & Subsystems/Out1', [feeder '/Curtailment kW'], 'Port', '4', 'Position', [3330 230 3360 250]);

grid = [feeder '/12.66 kV Grid'];
ground = [feeder '/Electrical Reference'];
solver = [feeder '/Solver Configuration'];
add_block(ee_source('Voltage Source (Three-Phase)'), grid, ...
    'Position', [70 260 150 340], 'vline_rms', '12660', 'freq', '50', ...
    'impedance_option', '2', 'R', '0.001', 'L', '1e-6');
add_block(ee_source('Electrical Reference'), ground, 'Position', [20 280 45 305]);
add_block('nesl_utility/Solver Configuration', solver, 'Position', [75 365 125 415]);
gridPorts = get_param(grid, 'PortHandles');
groundPorts = get_param(ground, 'PortHandles');
solverPorts = get_param(solver, 'PortHandles');
add_line(feeder, groundPorts.LConn(1), gridPorts.LConn(1));
add_line(feeder, solverPorts.RConn(1), gridPorts.RConn(1));

[x, y] = bus_positions();
busPort = cell(net.nBus, 1);
busPort{1} = gridPorts.RConn(1);
for branchIndex = 1:net.nBranch
    fromBus = net.branch(branchIndex, 1);
    toBus = net.branch(branchIndex, 2);
    linePath = sprintf('%s/Line %02d-%02d', feeder, fromBus, toBus);
    cx = round((x(fromBus) + x(toBus)) / 2);
    cy = round((y(fromBus) + y(toBus)) / 2);
    inductance = net.branch(branchIndex, 4) / (2 * pi * 50);
    add_block(ee_source('RLC (Three-Phase)'), linePath, ...
        'Position', [cx-45 cy-22 cx+45 cy+22], ...
        'component_structure', 'ee.enum.rlc.structure.SeriesRL', ...
        'R', sprintf('%.12g', net.branch(branchIndex, 3)), ...
        'L', sprintf('%.12g', inductance), 'G_parasitic', '1e-9');
    linePorts = get_param(linePath, 'PortHandles');
    add_line(feeder, busPort{fromBus}, linePorts.LConn(1), 'autorouting', 'on');
    busPort{toBus} = linePorts.RConn(1);
end

voltageMux = [feeder '/33 Bus Voltage Mux'];
add_block('simulink/Signal Routing/Mux', voltageMux, 'Inputs', '33', 'Position', [3200 70 3205 720]);
vSignal = cell(net.nBus, 1);
for bus = 1:net.nBus
    sensor = sprintf('%s/V Sensor Bus %02d', feeder, bus);
    rmsBlock = sprintf('%s/RMS Bus %02d', feeder, bus);
    converter = sprintf('%s/V Converter Bus %02d', feeder, bus);
    selector = sprintf('%s/Phase A RMS Bus %02d', feeder, bus);
    add_block(ee_source('Line Voltage Sensor (Three-Phase)'), sensor, ...
        'Position', [x(bus)-28 y(bus)-105 x(bus)+28 y(bus)-55]);
    add_block('fl_lib/Physical Signals/Periodic Operators/PS RMS Estimator', rmsBlock, ...
        'Position', [x(bus)-28 y(bus)-155 x(bus)+28 y(bus)-125], 'f0', '50', 'f0_unit', 'Hz');
    add_block('nesl_utility/PS-Simulink Converter', converter, ...
        'Position', [x(bus)-30 y(bus)-205 x(bus)+30 y(bus)-175], 'Unit', 'V');
    add_block('simulink/Signal Routing/Selector', selector, ...
        'Position', [x(bus)-28 y(bus)-250 x(bus)+28 y(bus)-220], ...
        'InputPortWidth', '3', 'Indices', '1');
    gain = sprintf('%s/Per unit Bus %02d', feeder, bus);
    add_block('simulink/Math Operations/Gain', gain, ...
        'Position', [x(bus)-25 y(bus)-295 x(bus)+25 y(bus)-270], 'Gain', '1/12660');
    sensorPorts = get_param(sensor, 'PortHandles');
    rmsPorts = get_param(rmsBlock, 'PortHandles');
    converterPorts = get_param(converter, 'PortHandles');
    add_line(feeder, busPort{bus}, sensorPorts.LConn(1), 'autorouting', 'on');
    add_line(feeder, sensorPorts.RConn(1), rmsPorts.LConn(1));
    add_line(feeder, rmsPorts.RConn(1), converterPorts.LConn(1));
    add_line(feeder, [short_name(converter) '/1'], [short_name(selector) '/1'], 'autorouting', 'on');
    add_line(feeder, [short_name(selector) '/1'], [short_name(gain) '/1'], 'autorouting', 'on');
    add_line(feeder, [short_name(gain) '/1'], sprintf('33 Bus Voltage Mux/%d', bus), 'autorouting', 'on');
    vSignal{bus} = [short_name(gain) '/1'];
end
add_line(feeder, '33 Bus Voltage Mux/1', 'Vbus pu/1', 'autorouting', 'on');

for bus = 2:net.nBus
    add_dynamic_load(feeder, bus, busPort{bus}, x(bus), y(bus), net.loadP_kW(bus), net.loadQ_kVAr(bus));
end

irrGain = [feeder '/Irradiance Wm2'];
irrConverter = [feeder '/Irradiance PS'];
add_block('simulink/Math Operations/Gain', irrGain, 'Gain', '1000', 'Position', [100 90 155 120]);
add_block('nesl_utility/Simulink-PS Converter', irrConverter, 'Unit', 'W/m^2', 'Position', [185 85 250 125]);
add_line(feeder, 'Irradiance/1', 'Irradiance Wm2/1');
add_line(feeder, 'Irradiance Wm2/1', 'Irradiance PS/1');
irrPorts = get_param(irrConverter, 'PortHandles');

pSum = [feeder '/Total PV P']; qSum = [feeder '/Total PV Q']; cSum = [feeder '/Total Curtailment'];
signs = repmat('+', 1, numel(pvBuses));
add_block('simulink/Math Operations/Sum', pSum, 'Inputs', signs, 'Position', [3180 770 3210 900]);
add_block('simulink/Math Operations/Sum', qSum, 'Inputs', signs, 'Position', [3180 930 3210 1060]);
add_block('simulink/Math Operations/Sum', cSum, 'Inputs', signs, 'Position', [3180 1090 3210 1220]);

for pvIndex = 1:numel(pvBuses)
    bus = pvBuses(pvIndex);
    add_pv_site(feeder, pvIndex, bus, busPort{bus}, ...
        x(bus), y(bus), irrPorts.RConn(1), groundPorts.LConn(1));
    add_line(feeder, sprintf('P Command PV %02d/1', pvIndex), sprintf('Total PV P/%d', pvIndex), 'autorouting', 'on');
    add_line(feeder, sprintf('Q Command PV %02d/1', pvIndex), sprintf('Total PV Q/%d', pvIndex), 'autorouting', 'on');
    add_line(feeder, sprintf('Curtail Command PV %02d/1', pvIndex), sprintf('Total Curtailment/%d', pvIndex), 'autorouting', 'on');
end
add_line(feeder, 'Total PV P/1', 'PV P kW/1', 'autorouting', 'on');
add_line(feeder, 'Total PV Q/1', 'PV Q kVAr/1', 'autorouting', 'on');
add_line(feeder, 'Total Curtailment/1', 'Curtailment kW/1', 'autorouting', 'on');

add_annotation(feeder, 'NATIVE SIMSCAPE ELECTRICAL FEEDER: 32 series R-L lines, 32 dynamic P-Q loads, 33 voltage sensors, 6 PV sites', [700 10 2640 45], 16, 'yellow');
end

function add_dynamic_load(feeder, bus, electricalPort, x, y, p_kW, q_kVAr)
loadPath = sprintf('%s/Load Bus %02d', feeder, bus);
pGain = sprintf('%s/P Load Bus %02d', feeder, bus);
qGain = sprintf('%s/Q Load Bus %02d', feeder, bus);
pConv = sprintf('%s/P PS Bus %02d', feeder, bus);
qConv = sprintf('%s/Q PS Bus %02d', feeder, bus);
add_block(ee_source('Dynamic Load (Three-Phase)'), loadPath, ...
    'Position', [x-42 y+55 x+42 y+130], 'FRated', '50', ...
    'Vline_rms_min', '1000', 'Vline_rms_ini', '12660', 'tau', '0.02', 'gmin', '1e-9');
add_block('simulink/Math Operations/Gain', pGain, 'Gain', sprintf('%.12g', p_kW*1000), 'Position', [x-115 y+150 x-65 y+175]);
add_block('simulink/Math Operations/Gain', qGain, 'Gain', sprintf('%.12g', q_kVAr*1000), 'Position', [x-115 y+190 x-65 y+215]);
add_block('nesl_utility/Simulink-PS Converter', pConv, 'Unit', 'W', 'Position', [x-45 y+145 x+15 y+180]);
add_block('nesl_utility/Simulink-PS Converter', qConv, 'Unit', 'V*A', 'Position', [x-45 y+188 x+15 y+223]);
loadPorts = get_param(loadPath, 'PortHandles');
pPorts = get_param(pConv, 'PortHandles'); qPorts = get_param(qConv, 'PortHandles');
add_line(feeder, electricalPort, loadPorts.LConn(1), 'autorouting', 'on');
add_line(feeder, 'Load scale/1', [short_name(pGain) '/1'], 'autorouting', 'on');
add_line(feeder, 'Load scale/1', [short_name(qGain) '/1'], 'autorouting', 'on');
add_line(feeder, [short_name(pGain) '/1'], [short_name(pConv) '/1'], 'autorouting', 'on');
add_line(feeder, [short_name(qGain) '/1'], [short_name(qConv) '/1'], 'autorouting', 'on');
add_line(feeder, pPorts.RConn(1), loadPorts.LConn(2));
add_line(feeder, qPorts.RConn(1), loadPorts.LConn(3));
end

function add_pv_site(feeder, index, bus, electricalPort, x, y, irradiancePort, groundPort)
pSelect = sprintf('%s/P Command PV %02d', feeder, index);
qSelect = sprintf('%s/Q Command PV %02d', feeder, index);
cSelect = sprintf('%s/Curtail Command PV %02d', feeder, index);
add_block('simulink/Signal Routing/Selector', pSelect, ...
    'InputPortWidth', '6', 'Indices', num2str(index), 'Position', [x-90 y+270 x-40 y+295]);
add_block('simulink/Signal Routing/Selector', qSelect, ...
    'InputPortWidth', '6', 'Indices', num2str(index), 'Position', [x-90 y+310 x-40 y+335]);
add_block('simulink/Signal Routing/Selector', cSelect, ...
    'InputPortWidth', '6', 'Indices', num2str(index), 'Position', [x-90 y+350 x-40 y+375]);
add_line(feeder, 'PV P commands/1', sprintf('%s/1', short_name(pSelect)), 'autorouting', 'on');
add_line(feeder, 'PV Q commands/1', sprintf('%s/1', short_name(qSelect)), 'autorouting', 'on');
add_line(feeder, 'PV curtail commands/1', sprintf('%s/1', short_name(cSelect)), 'autorouting', 'on');

inverter = sprintf('%s/Average PQ Inverter Bus %02d', feeder, bus);
pNeg = sprintf('%s/Neg P PV %02d', feeder, bus);
qNeg = sprintf('%s/Neg Q PV %02d', feeder, bus);
pConv = sprintf('%s/P PV PS %02d', feeder, bus);
qConv = sprintf('%s/Q PV PS %02d', feeder, bus);
add_block(ee_source('Dynamic Load (Three-Phase)'), inverter, ...
    'Position', [x+105 y+275 x+200 y+360], 'FRated', '50', ...
    'Vline_rms_min', '1000', 'Vline_rms_ini', '12660', 'tau', '0.02', 'gmin', '1e-9');
add_block('simulink/Math Operations/Gain', pNeg, ...
    'Gain', '-1000', 'Position', [x+205 y+275 x+260 y+300]);
add_block('simulink/Math Operations/Gain', qNeg, ...
    'Gain', '-1000', 'Position', [x+205 y+325 x+260 y+350]);
add_block('nesl_utility/Simulink-PS Converter', pConv, ...
    'Unit', 'W', 'Position', [x+280 y+268 x+340 y+305]);
add_block('nesl_utility/Simulink-PS Converter', qConv, ...
    'Unit', 'V*A', 'Position', [x+280 y+318 x+340 y+355]);
invPorts = get_param(inverter, 'PortHandles');
pPorts = get_param(pConv, 'PortHandles'); qPorts = get_param(qConv, 'PortHandles');
add_line(feeder, electricalPort, invPorts.LConn(1), 'autorouting', 'on');
add_line(feeder, sprintf('%s/1', short_name(pSelect)), sprintf('%s/1', short_name(pNeg)), 'autorouting', 'on');
add_line(feeder, sprintf('%s/1', short_name(qSelect)), sprintf('%s/1', short_name(qNeg)), 'autorouting', 'on');
add_line(feeder, sprintf('%s/1', short_name(pNeg)), sprintf('%s/1', short_name(pConv)), 'autorouting', 'on');
add_line(feeder, sprintf('%s/1', short_name(qNeg)), sprintf('%s/1', short_name(qConv)), 'autorouting', 'on');
add_line(feeder, pPorts.RConn(1), invPorts.LConn(2));
add_line(feeder, qPorts.RConn(1), invPorts.LConn(3));

solar = sprintf('%s/Solar Cell Array Bus %02d', feeder, bus);
resistor = sprintf('%s/DC MPPT Equivalent R Bus %02d', feeder, bus);
add_block(ee_source('Solar Cell'), solar, 'Position', [x-65 y+445 x+5 y+515], ...
    'N_series', '600', 'N_parallel', sprintf('max(1,round(simscape_pv_capacity_kW(%d)/2.1))', index));
add_block(ee_source('Resistor'), resistor, 'Position', [x+45 y+460 x+105 y+500], ...
    'R', sprintf('(0.8*0.6*600)^2/max(simscape_pv_capacity_kW(%d)*1000,1)', index));
solarPorts = get_param(solar, 'PortHandles'); resistorPorts = get_param(resistor, 'PortHandles');
add_line(feeder, irradiancePort, solarPorts.LConn(1), 'autorouting', 'on');
add_line(feeder, solarPorts.LConn(2), resistorPorts.LConn(1));
add_line(feeder, resistorPorts.RConn(1), solarPorts.RConn(1));
add_line(feeder, solarPorts.RConn(1), groundPort, 'autorouting', 'on');
end

function source = ee_source(normalizedName)
persistent paths names
if isempty(paths)
    load_system('ee_lib');
    paths = find_system('ee_lib', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
    names = strrep(string(get_param(paths, 'Name')), newline, ' ');
end
match = find(names == normalizedName, 1, 'first');
assert(~isempty(match), 'Simscape Electrical library block not found: %s', normalizedName);
source = paths{match};
end

function [x, y] = bus_positions()
x = zeros(33, 1); y = zeros(33, 1);
x(1:18) = 200 + (0:17) * 170; y(1:18) = 340;
x(19:22) = 430 + (0:3) * 170; y(19:22) = 700;
x(23:25) = 600 + (0:2) * 170; y(23:25) = 950;
x(26:33) = 1110 + (0:7) * 170; y(26:33) = 1200;
end

function name = short_name(fullPath)
parts = split(string(fullPath), '/');
name = char(parts(end));
end

function add_workspace_sink(model, blockName, variableName, position)
add_block('simulink/Sinks/To Workspace', [model '/' blockName], ...
    'VariableName', variableName, 'SaveFormat', 'Timeseries', ...
    'MaxDataPoints', '20000', 'Position', position);
end

function add_annotation(model, textValue, position, fontSize, color)
note = Simulink.Annotation(model, textValue);
note.Position = position;
note.FontSize = fontSize;
note.FontWeight = 'bold';
note.BackgroundColor = color;
note.ForegroundColor = 'black';
note.Interpreter = 'off';
end

function callback = preload_callback()
callback = ['try, startup_project(); addpath(fullfile(pwd,''simulink_physical'')); ' ...
    'if evalin(''base'',''exist(''''simscape_pv_p_commands'''',''''var'''')'') == 0, ' ...
    'prepare_ieee33_simscape_inputs(80,''partial_cloud'',''hybrid''); end; ' ...
    'catch ME, disp([''Physical-model preload warning: '' ME.message]); end'];
end
