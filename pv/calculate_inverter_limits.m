function limits = calculate_inverter_limits(Pout_pu, Sinv_pu, Pavailable_pu)
%CALCULATE_INVERTER_LIMITS Inverter active/reactive capability limits.

Pout_pu = min(max(Pout_pu, 0), Pavailable_pu);
Qcap = sqrt(max(Sinv_pu.^2 - Pout_pu.^2, 0));

limits.Pmin_pu = zeros(size(Pout_pu));
limits.Pmax_pu = Pavailable_pu;
limits.QmaxInject_pu = Qcap;
limits.QmaxAbsorb_pu = Qcap;
limits.Sinv_pu = Sinv_pu;
limits.utilization = sqrt(Pout_pu.^2) ./ max(Sinv_pu, eps);
end
