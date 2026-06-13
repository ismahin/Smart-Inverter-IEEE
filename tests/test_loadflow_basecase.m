function test_loadflow_basecase()
%TEST_LOADFLOW_BASECASE Validate base-case backward/forward sweep load flow.

startup_project();
net = ieee33_data();
lf = bfs_loadflow_ieee33(net, net.loadP_pu, net.loadQ_pu, struct('maxIter', 100, 'tol', 1e-9));
assert(lf.converged, 'Base load flow did not converge.');
assert(abs(lf.Vmag(1) - 1) < 1e-10, 'Slack voltage must be 1.0 p.u.');
assert(lf.Vmag(33) < lf.Vmag(2), 'End bus voltage should be lower than upstream voltage.');
assert(all(isfinite(lf.Vmag)), 'Voltage contains NaN or Inf.');
assert(lf.Ploss_kW > 0, 'Losses must be positive.');
fprintf('Base case minimum voltage %.4f p.u., losses %.2f kW.\n', min(lf.Vmag), lf.Ploss_kW);
fprintf('test_loadflow_basecase passed.\n');
end
