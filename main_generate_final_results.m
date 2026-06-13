function main_generate_final_results()
%MAIN_GENERATE_FINAL_RESULTS Run the full thesis-ready result pipeline.

startup_project();
validate_ieee33_basecase();
validate_pv_penetration();
test_loadflow_basecase();
test_controllers();

main_run_all_cases();
main_run_stress_cases();

run_pso_optimization_v2();

main_run_all_cases();
main_run_stress_cases();

calculate_hosting_capacity({'none', 'voltvar', 'voltwatt', 'hybrid', 'hybrid_pso'});
analyze_controller_activation();
generate_final_report_tables();
generate_final_figures();
validate_final_results();

fprintf('FINAL PROJECT RESULTS GENERATED SUCCESSFULLY\n');
end
