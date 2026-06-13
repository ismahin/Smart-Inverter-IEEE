function params = vector_to_control_params(x)
%VECTOR_TO_CONTROL_PARAMS Convert 9 PSO variables to parameter struct.

params.V1 = x(1);
params.V2 = x(2);
params.V3 = x(3);
params.V4 = x(4);
params.Qinj_frac = x(5);
params.Qabs_frac = x(6);
params.VW_Vstart = x(7);
params.VW_Vend = x(8);
params.Pmin_frac = x(9);
end
