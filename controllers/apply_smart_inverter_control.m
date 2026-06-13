function result = apply_smart_inverter_control(net, pv, loadScale, irradiance, strategy, params, options)
%APPLY_SMART_INVERTER_CONTROL Fixed-point smart inverter/load-flow solve.

if nargin < 5 || isempty(strategy), strategy = 'none'; end
if nargin < 6 || isempty(params), params = default_control_params(); end
if nargin < 7 || isempty(options), options = struct(); end
if ~isfield(options, 'maxOuterIter'), options.maxOuterIter = 80; end
if ~isfield(options, 'outerTol'), options.outerTol = 1e-6; end
if ~isfield(options, 'relaxation'), options.relaxation = 0.20; end
if ~isfield(options, 'lf'), options.lf = struct('maxIter', 100, 'tol', 1e-8); end

baseP = net.loadP_pu(:) * loadScale;
baseQ = net.loadQ_pu(:) * loadScale;
Pavailable = pv.capacity_pu(:) * irradiance;
Sinv = pv.Sinv_pu(:);

Ppv = Pavailable;
Qpv = zeros(size(Pavailable));
prevP = Ppv;
prevQ = Qpv;
converged = false;

for outer = 1:options.maxOuterIter
    Pnet = baseP;
    Qnet = baseQ;
    Pnet(pv.buses) = Pnet(pv.buses) - Ppv;
    Qnet(pv.buses) = Qnet(pv.buses) - Qpv;

    lf = bfs_loadflow_ieee33(net, Pnet, Qnet, options.lf);
    Vlocal = lf.Vmag(pv.buses);

    switch lower(strategy)
        case 'none'
            Pnew = Pavailable;
            Qnew = zeros(size(Pavailable));
        case 'voltvar'
            Pnew = Pavailable;
            Qnew = volt_var_control(Vlocal, Pnew, Sinv, params);
        case 'voltwatt'
            Pnew = volt_watt_control(Vlocal, Pavailable, params);
            Qnew = zeros(size(Pavailable));
        case {'hybrid', 'hybrid_pso'}
            ctrl = hybrid_volt_var_watt_control(Vlocal, Pavailable, Sinv, params);
            Pnew = ctrl.Pout_pu;
            Qnew = ctrl.Qout_pu;
        otherwise
            error('Unknown smart inverter strategy: %s', strategy);
    end

    if strcmpi(strategy, 'none')
        Prelaxed = Pnew;
        Qrelaxed = Qnew;
    else
        alpha = min(max(options.relaxation, 0.05), 1.0);
        Prelaxed = alpha * Pnew + (1 - alpha) * Ppv;
        Qrelaxed = alpha * Qnew + (1 - alpha) * Qpv;
    end

    delta = max([abs(Prelaxed - prevP); abs(Qrelaxed - prevQ)]);
    Ppv = Prelaxed;
    Qpv = Qrelaxed;
    prevP = Prelaxed;
    prevQ = Qrelaxed;
    if delta < options.outerTol
        converged = true;
        break;
    end
end

Pnet = baseP;
Qnet = baseQ;
Pnet(pv.buses) = Pnet(pv.buses) - Ppv;
Qnet(pv.buses) = Qnet(pv.buses) - Qpv;
lf = bfs_loadflow_ieee33(net, Pnet, Qnet, options.lf);

result.lf = lf;
result.Pnet_pu = Pnet;
result.Qnet_pu = Qnet;
result.Ppv_pu = Ppv;
result.Qpv_pu = Qpv;
result.Pavailable_pu = Pavailable;
result.Pcurtailed_pu = max(Pavailable - Ppv, 0);
result.Pcurtailed_kW = result.Pcurtailed_pu * net.baseMVA * 1000;
result.Qpv_kVAr = Qpv * net.baseMVA * 1000;
result.outerIter = outer;
result.outerConverged = converged;
result.strategy = strategy;

result.localVoltage_pu = lf.Vmag(pv.buses);
result.Qlimit_pu = sqrt(max(Sinv(:).^2 - Ppv(:).^2, 0));
result.voltwatt_active = false(size(Ppv));
result.voltvar_active = false(size(Ppv));
result.both_active = false(size(Ppv));
switch lower(strategy)
    case 'voltvar'
        result.voltvar_active = abs(Qpv(:)) > 1e-8;
    case 'voltwatt'
        [~, vwInfo] = volt_watt_control(result.localVoltage_pu, Pavailable, params);
        result.voltwatt_active = vwInfo.active(:);
    case {'hybrid', 'hybrid_pso'}
        ctrlFinal = hybrid_volt_var_watt_control(result.localVoltage_pu, Pavailable, Sinv, params);
        result.voltwatt_active = ctrlFinal.voltwatt_active;
        result.voltvar_active = ctrlFinal.voltvar_active;
        result.both_active = ctrlFinal.both_active;
end
end
