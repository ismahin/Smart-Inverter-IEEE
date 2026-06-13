function out = hybrid_volt_var_watt_control(Vpu, Pavailable_pu, Sinv_pu, params)
%HYBRID_VOLT_VAR_WATT_CONTROL Coordinated Volt-Watt then Volt-VAR control.

[Pout, vwInfo] = volt_watt_control(Vpu, Pavailable_pu, params);
Qout = volt_var_control(Vpu, Pout, Sinv_pu, params);

S = sqrt(Pout.^2 + Qout.^2);
over = S > Sinv_pu + 1e-12;
if any(over)
    scale = Sinv_pu(over) ./ S(over);
    Qout(over) = Qout(over) .* scale;
end

out.Pout_pu = Pout;
out.Qout_pu = Qout;
out.curtailed_pu = max(Pavailable_pu(:) - Pout(:), 0);
out.utilization = sqrt(Pout.^2 + Qout.^2) ./ max(Sinv_pu(:), eps);
out.Qlimit_pu = sqrt(max(Sinv_pu(:).^2 - Pout(:).^2, 0));
out.voltwatt_active = vwInfo.active(:);
out.voltvar_active = abs(Qout(:)) > 1e-8;
out.both_active = out.voltwatt_active & out.voltvar_active;
end
