function outputFile = export_simulink_visualization(modelName, projectRoot)
%EXPORT_SIMULINK_VISUALIZATION Export the top-level workflow diagram to PNG.

if nargin < 1 || isempty(modelName)
    modelName = 'IEEE33bus_SmartInverter_Hybrid_PSO';
end
visualizationDir = fileparts(mfilename('fullpath'));
if nargin < 2 || isempty(projectRoot)
    projectRoot = fileparts(visualizationDir);
end
modelFile = fullfile(visualizationDir, [modelName '.slx']);
outputDir = fullfile(projectRoot, 'results', 'figures');
outputFile = fullfile(outputDir, 'simulink_visualization_overview.png');
if exist(outputDir, 'dir') ~= 7
    mkdir(outputDir);
end
if ~bdIsLoaded(modelName)
    load_system(modelFile);
end
open_system(modelName);
set_param(modelName, 'ZoomFactor', 'FitSystem');
save_system(modelName, modelFile);
try
    Simulink.BlockDiagram.exportToImage(modelName, outputFile);
catch firstError
    try
        print(['-s' modelName], '-dpng', outputFile);
    catch secondError
        error('PNG export failed. exportToImage: %s print: %s', ...
            firstError.message, secondError.message);
    end
end
fprintf('Exported Simulink visualization PNG:\n%s\n', outputFile);
end
