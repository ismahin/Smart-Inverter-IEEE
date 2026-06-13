function Qout_pu = volt_var_control(Vpu, Ppv_pu, Sinv_pu, params)
%VOLT_VAR_CONTROL Four-point Volt-VAR smart inverter control.
%
% Positive Qout is reactive injection. Negative Qout is absorption.

p = parse_vv_params(params);
Vpu = Vpu(:);
Ppv_pu = Ppv_pu(:);
Sinv_pu = Sinv_pu(:);

Qcap = sqrt(max(Sinv_pu.^2 - Ppv_pu.^2, 0));
QinjMax = p.Qinj_frac .* Qcap;
QabsMax = p.Qabs_frac .* Qcap;
Qout_pu = zeros(size(Vpu));

low = Vpu <= p.V1;
midLow = Vpu > p.V1 & Vpu < p.V2;
dead = Vpu >= p.V2 & Vpu <= p.V3;
midHigh = Vpu > p.V3 & Vpu < p.V4;
high = Vpu >= p.V4;

Qout_pu(low) = QinjMax(low);
Qout_pu(midLow) = QinjMax(midLow) .* (p.V2 - Vpu(midLow)) ./ max(p.V2 - p.V1, eps);
Qout_pu(dead) = 0;
Qout_pu(midHigh) = -QabsMax(midHigh) .* (Vpu(midHigh) - p.V3) ./ max(p.V4 - p.V3, eps);
Qout_pu(high) = -QabsMax(high);
Qout_pu = min(max(Qout_pu, -Qcap), Qcap);
end

function p = parse_vv_params(params)
if nargin < 1 || isempty(params)
    params = default_control_params();
end
if isnumeric(params)
    p.V1 = params(1); p.V2 = params(2); p.V3 = params(3); p.V4 = params(4);
    p.Qinj_frac = params(5); p.Qabs_frac = params(6);
elseif isstruct(params)
    p = default_control_params();
    f = fieldnames(params);
    for k = 1:numel(f), p.(f{k}) = params.(f{k}); end
else
    error('Unsupported Volt-VAR parameter type.');
end
end
