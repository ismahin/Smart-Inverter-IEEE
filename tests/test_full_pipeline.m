function test_full_pipeline()
%TEST_FULL_PIPELINE Run a compact scenario and verify full output pipeline.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
scenario = main_run_single_case(20, 'clear_sky', 'hybrid', default_control_params());
assert(size(scenario.Vmag, 2) == 33, 'Scenario voltage profile must include 33 buses.');
assert(all(isfinite(scenario.loss_kW)), 'Scenario losses contain non-finite values.');

allResults = main_run_all_cases(); %#ok<NASGU>
summaryFile = fullfile(projectRoot, 'results', 'tables', 'all_case_summary.csv');
hourlyFile = fullfile(projectRoot, 'results', 'tables', 'hourly_results.csv');
assert(exist(summaryFile, 'file') == 2, 'Summary CSV was not created.');
assert(exist(hourlyFile, 'file') == 2, 'Hourly CSV was not created.');
fprintf('test_full_pipeline passed.\n');
end
