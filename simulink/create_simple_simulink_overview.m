function create_simple_simulink_overview()
%CREATE_SIMPLE_SIMULINK_OVERVIEW Create high-level overview Simulink model.
%
% This is an architectural overview only, not an EMT/Simscape physical
% model. It documents the quasi-static MATLAB simulation workflow.

if exist('simulink', 'file') ~= 4 && exist('new_system', 'file') ~= 2
    fprintf('Simulink is not installed or unavailable. Skipping overview model.\n');
    return;
end

model = 'Smart_Inverter_IEEE33_Overview';
if bdIsLoaded(model)
    close_system(model, 0);
end
new_system(model);
open_system(model);

blocks = {
    'IEEE 33-bus Network', [80 90 230 140]
    'PV Generation', [80 210 230 260]
    'Load Profile', [80 330 230 380]
    'Smart Inverter Control', [330 210 520 270]
    'Load Flow MATLAB Function', [620 200 840 280]
    'Metrics', [940 200 1090 260]
    'Results Sink', [1190 200 1340 260]
};

for k = 1:size(blocks, 1)
    add_block('simulink/Commonly Used Blocks/Subsystem', ...
        [model '/' blocks{k, 1}], 'Position', blocks{k, 2});
end

add_line(model, 'PV Generation/1', 'Smart Inverter Control/1', 'autorouting', 'on');
add_line(model, 'Load Profile/1', 'Load Flow MATLAB Function/1', 'autorouting', 'on');
add_line(model, 'IEEE 33-bus Network/1', 'Load Flow MATLAB Function/2', 'autorouting', 'on');
add_line(model, 'Smart Inverter Control/1', 'Load Flow MATLAB Function/3', 'autorouting', 'on');
add_line(model, 'Load Flow MATLAB Function/1', 'Metrics/1', 'autorouting', 'on');
add_line(model, 'Metrics/1', 'Results Sink/1', 'autorouting', 'on');

save_system(model, fullfile(fileparts(mfilename('fullpath')), [model '.slx']));
fprintf('Created Simulink overview model: %s.slx\n', model);
end
