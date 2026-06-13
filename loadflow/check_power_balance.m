function balance = check_power_balance(net, lf, Pnet_pu, Qnet_pu)
%CHECK_POWER_BALANCE Return approximate feeder power balance quantities.

Sload = sum(Pnet_pu(:)) + 1i * sum(Qnet_pu(:));
Sloss = lf.Ploss_pu + 1i * lf.Qloss_pu;
Ssource = Sload + Sloss;

balance.totalLoad_pu = Sload;
balance.totalLoss_pu = Sloss;
balance.source_pu = Ssource;
balance.source_kVA = abs(Ssource) * net.baseMVA * 1000;
balance.lossPercentOfLoad = 100 * real(Sloss) / max(real(Sload), eps);
end
