function baseSummary = validate_ieee33_basecase()
%VALIDATE_IEEE33_BASECASE Validate IEEE 33-bus data and base load flow.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
net = ieee33_data();

assert(net.nBus == 33, 'Validation failed: IEEE feeder must have 33 buses.');
assert(net.nBranch == 32, 'Validation failed: IEEE radial feeder must have 32 branches.');

lf = bfs_loadflow_ieee33(net, net.loadP_pu, net.loadQ_pu, struct('maxIter', 200, 'tol', 1e-10));
Vmag = lf.Vmag(:);

assert(lf.converged, 'Validation failed: base-case load flow did not converge.');
assert(max(abs(Vmag(1) - 1.0)) < 1e-6, 'Validation failed: slack bus is not 1.0 p.u.');
assert(all(isfinite(Vmag)), 'Validation failed: voltage contains NaN or Inf.');
assert(lf.Ploss_kW > 0, 'Validation failed: active losses must be positive.');
assert(min(Vmag) > 0.85, 'Validation failed: minimum base voltage is not physically reasonable.');
assert(max(Vmag) <= 1.02, 'Validation failed: no-PV maximum voltage unexpectedly high.');

endFeederCheck = mean(Vmag([18 22 25 33])) < mean(Vmag([2 3 4 5]));
assert(endFeederCheck, 'Validation failed: voltage does not generally drop toward end feeder buses.');

profile = table((1:net.nBus)', Vmag, angle(lf.V(:)), ...
    'VariableNames', {'Bus', 'Voltage_pu', 'Angle_rad'});
baseSummary = table(net.nBus, net.nBranch, net.totalLoad_kW, net.totalLoad_kVAr, ...
    min(Vmag), max(Vmag), lf.Ploss_kW, lf.Qloss_kVAr, lf.iter, lf.converged, ...
    'VariableNames', {'NumBuses', 'NumBranches', 'TotalLoad_kW', 'TotalLoad_kVAr', ...
    'MinVoltage_pu', 'MaxVoltage_pu', 'Ploss_kW', 'Qloss_kVAr', 'Iterations', 'Converged'});

writetable(profile, fullfile(projectRoot, 'results', 'tables', 'basecase_voltage_profile.csv'));
writetable(baseSummary, fullfile(projectRoot, 'results', 'tables', 'basecase_summary.csv'));

fig = figure('Color', 'w', 'Position', [100 100 880 480]);
plot(1:net.nBus, Vmag, '-o', 'LineWidth', 1.8);
grid on;
yline(net.Vmin, '--r', 'Vmin');
xlabel('Bus Number');
ylabel('Voltage Magnitude (p.u.)');
title('Validated IEEE 33-Bus Base-Case Voltage Profile');
exportgraphics(fig, fullfile(projectRoot, 'results', 'figures', 'basecase_voltage_profile.png'), 'Resolution', 220);
savefig(fig, fullfile(projectRoot, 'results', 'figures', 'basecase_voltage_profile.fig'));
close(fig);

fprintf('IEEE 33-bus base-case validation passed. Min V = %.4f p.u., Ploss = %.2f kW.\n', ...
    min(Vmag), lf.Ploss_kW);
end
