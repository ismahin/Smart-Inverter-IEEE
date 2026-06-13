function startup_project()
%STARTUP_PROJECT Add project folders to the MATLAB path and create outputs.

projectRoot = fileparts(mfilename('fullpath'));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'data'));
addpath(fullfile(projectRoot, 'loadflow'));
addpath(fullfile(projectRoot, 'pv'));
addpath(fullfile(projectRoot, 'controllers'));
addpath(fullfile(projectRoot, 'optimization'));
addpath(fullfile(projectRoot, 'metrics'));
addpath(fullfile(projectRoot, 'plotting'));
addpath(fullfile(projectRoot, 'tests'));
addpath(fullfile(projectRoot, 'simulink'));
addpath(fullfile(projectRoot, 'simulink_visualization'));
addpath(fullfile(projectRoot, 'validation'));
addpath(fullfile(projectRoot, 'analysis'));
addpath(fullfile(projectRoot, 'report'));

ensure_dir(fullfile(projectRoot, 'results'));
ensure_dir(fullfile(projectRoot, 'results', 'figures'));
ensure_dir(fullfile(projectRoot, 'results', 'tables'));
ensure_dir(fullfile(projectRoot, 'results', 'mat_files'));
ensure_dir(fullfile(projectRoot, 'results', 'report'));

fprintf('Smart Inverter IEEE33 project initialized at:\n%s\n', projectRoot);
end

function ensure_dir(pathName)
if ~exist(pathName, 'dir')
    mkdir(pathName);
end
end
