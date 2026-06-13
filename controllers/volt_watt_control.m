function [Pout_pu, info] = volt_watt_control(Vpu, Pavailable_pu, params)
%VOLT_WATT_CONTROL Volt-Watt active power curtailment curve.

p = parse_vw_params(params);
Vpu = Vpu(:);
Pavailable_pu = Pavailable_pu(:);
Pout_pu = Pavailable_pu;

curtail = Vpu > p.VW_Vstart & Vpu < p.VW_Vend;
high = Vpu >= p.VW_Vend;

slopeFrac = (Vpu(curtail) - p.VW_Vstart) ./ max(p.VW_Vend - p.VW_Vstart, eps);
Pout_pu(curtail) = Pavailable_pu(curtail) .* (1 - slopeFrac .* (1 - p.Pmin_frac));
Pout_pu(high) = p.Pmin_frac .* Pavailable_pu(high);
Pout_pu = min(max(Pout_pu, 0), Pavailable_pu);

info.active = (Vpu > p.VW_Vstart) & (Pavailable_pu > 0);
info.inLinearRegion = curtail;
info.inMinimumRegion = high;
info.Pcurtailed_pu = max(Pavailable_pu - Pout_pu, 0);
info.VW_Vstart = p.VW_Vstart;
info.VW_Vend = p.VW_Vend;
info.Pmin_frac = p.Pmin_frac;
end

function p = parse_vw_params(params)
if nargin < 1 || isempty(params)
    params = default_control_params();
end
if isnumeric(params)
    p.VW_Vstart = params(7); p.VW_Vend = params(8); p.Pmin_frac = params(9);
elseif isstruct(params)
    p = default_control_params();
    f = fieldnames(params);
    for k = 1:numel(f), p.(f{k}) = params.(f{k}); end
else
    error('Unsupported Volt-Watt parameter type.');
end
end
