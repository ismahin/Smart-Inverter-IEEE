function test_controllers()
%TEST_CONTROLLERS Validate inverter control behavior and limits.

startup_project();
params = default_control_params();
Sinv = 0.01;
Ppv = 0.008;

Qlow = volt_var_control(0.93, Ppv, Sinv, params);
Qhigh = volt_var_control(1.07, Ppv, Sinv, params);
assert(Qlow > 0, 'Volt-VAR should inject positive Q at low voltage.');
assert(Qhigh < 0, 'Volt-VAR should absorb negative Q at high voltage.');

Pcurt = volt_watt_control(1.08, 0.01, params);
assert(Pcurt < 0.01, 'Volt-Watt should curtail active power at high voltage.');

out = hybrid_volt_var_watt_control(1.08, 0.01, Sinv, params);
assert(sqrt(out.Pout_pu.^2 + out.Qout_pu.^2) <= Sinv + 1e-12, ...
    'Hybrid controller must respect inverter apparent power rating.');
fprintf('test_controllers passed.\n');
end
