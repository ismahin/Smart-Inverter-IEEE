function pv = apply_pv_penetration(net, penetrationPercent, pvBuses, weights)
%APPLY_PV_PENETRATION Allocate installed PV capacity across selected buses.
%
% PV penetration = total installed PV active power / total nominal load.

if nargin < 3 || isempty(pvBuses), pvBuses = select_pv_buses(); end
if nargin < 4 || isempty(weights), weights = ones(size(pvBuses)); end

pvBuses = pvBuses(:)';
weights = weights(:)' / sum(weights);
totalPV_kW = (penetrationPercent / 100) * net.totalLoad_kW;
capacity_kW = totalPV_kW * weights;

pv.penetrationPercent = penetrationPercent;
pv.buses = pvBuses;
pv.capacity_kW = capacity_kW(:);
pv.capacity_pu = pv.capacity_kW / (net.baseMVA * 1000);
pv.totalCapacity_kW = sum(pv.capacity_kW);
pv.Sinv_kVA = 1.1 * pv.capacity_kW;
pv.Sinv_pu = pv.Sinv_kVA / (net.baseMVA * 1000);
end
