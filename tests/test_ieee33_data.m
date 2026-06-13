function test_ieee33_data()
%TEST_IEEE33_DATA Validate IEEE 33-bus data integrity.

startup_project();
net = ieee33_data();
assert(net.nBus == 33, 'IEEE 33-bus system must have 33 buses.');
assert(net.nBranch == 32, 'IEEE 33-bus radial system must have 32 branches.');
assert(numel(net.loadP_kW) == 33, 'Load vector length mismatch.');
assert(all(isfinite(net.branch(:))), 'Branch data contains non-finite values.');
assert(net.totalLoad_kW > 0, 'Total active load must be positive.');
fprintf('test_ieee33_data passed.\n');
end
