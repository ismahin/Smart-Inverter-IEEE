function params = default_control_params()
%DEFAULT_CONTROL_PARAMS Default Volt-VAR and Volt-Watt control settings.

params.V1 = 0.94;
params.V2 = 0.98;
params.V3 = 1.02;
params.V4 = 1.06;
params.Qinj_frac = 1.0;
params.Qabs_frac = 1.0;
params.VW_Vstart = 1.03;
params.VW_Vend = 1.08;
params.Pmin_frac = 0.10;
end
