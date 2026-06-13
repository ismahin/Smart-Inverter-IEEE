function losses = calculate_power_losses(net, lf)
%CALCULATE_POWER_LOSSES Convert load-flow losses to common units.

losses.Ploss_pu = lf.Ploss_pu;
losses.Qloss_pu = lf.Qloss_pu;
losses.Ploss_kW = lf.Ploss_kW;
losses.Qloss_kVAr = lf.Qloss_kVAr;
losses.Ploss_percent_of_load = 100 * lf.Ploss_kW / max(net.totalLoad_kW, eps);
end
