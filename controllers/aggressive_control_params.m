function params = aggressive_control_params()
%AGGRESSIVE_CONTROL_PARAMS Lower Volt-Watt thresholds for stress studies.

params = default_control_params();
params.VW_Vstart = 1.02;
params.VW_Vend = 1.06;
params.Pmin_frac = 0.00;
end
