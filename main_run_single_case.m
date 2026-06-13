function scenario = main_run_single_case(penetrationPercent, condition, strategy, params, simOptions)
%MAIN_RUN_SINGLE_CASE Run one 24-hour quasi-static scenario.

startup_project();
if nargin < 1 || isempty(penetrationPercent), penetrationPercent = 80; end
if nargin < 2 || isempty(condition), condition = 'partial_cloud'; end
if nargin < 3 || isempty(strategy), strategy = 'hybrid'; end
if nargin < 4 || isempty(params), params = default_control_params(); end
if nargin < 5 || isempty(simOptions), simOptions = struct(); end
if ~isfield(simOptions, 'loadProfileType'), simOptions.loadProfileType = 'mixed'; end
if ~isfield(simOptions, 'pvBusOption'), simOptions.pvBusOption = 'default'; end
if ~isfield(simOptions, 'pvWeights'), simOptions.pvWeights = []; end
if ~isfield(simOptions, 'loadScaleFactor'), simOptions.loadScaleFactor = 1.0; end
if ~isfield(simOptions, 'controlOptions'), simOptions.controlOptions = struct(); end
if ~isfield(simOptions, 'scenarioLabel'), simOptions.scenarioLabel = 'proposal_case'; end

net = ieee33_data();
pv = apply_pv_penetration(net, penetrationPercent, ...
    select_pv_buses(simOptions.pvBusOption), simOptions.pvWeights);
if strcmpi(simOptions.loadProfileType, 'stress')
    loadProfile = create_stress_load_profile(1);
else
    loadProfile = create_load_profile(simOptions.loadProfileType, 1);
end
loadProfile.multiplier = loadProfile.multiplier * simOptions.loadScaleFactor;
if strcmpi(condition, 'stress_clear_sky')
    irrProfile = create_stress_irradiance_profile(1);
else
    irrProfile = create_irradiance_profile(condition, 1);
end

nT = numel(loadProfile.time_h);
Vmag = zeros(nT, net.nBus);
loss_kW = zeros(nT, 1);
violations = zeros(nT, 1);
curtail_kW = zeros(nT, 1);
q_kVAr = zeros(nT, 1);
outerIter = zeros(nT, 1);
pvLogRows = {};

for t = 1:nT
    r = apply_smart_inverter_control(net, pv, loadProfile.multiplier(t), ...
        irrProfile.irradiance(t), strategy, params, simOptions.controlOptions);
    vm = calculate_voltage_metrics(r.lf.Vmag, net);
    Vmag(t, :) = r.lf.Vmag(:)';
    loss_kW(t) = r.lf.Ploss_kW;
    violations(t) = vm.totalViolationCount;
    curtail_kW(t) = sum(r.Pcurtailed_kW);
    q_kVAr(t) = sum(r.Qpv_kVAr);
    outerIter(t) = r.outerIter;
    for k = 1:numel(pv.buses)
        pvLogRows(end + 1, :) = {t, loadProfile.time_h(t), pv.buses(k), ...
            r.localVoltage_pu(k), r.Pavailable_pu(k) * net.baseMVA * 1000, ...
            r.Ppv_pu(k) * net.baseMVA * 1000, r.Pcurtailed_kW(k), ...
            r.Qpv_kVAr(k), r.Qlimit_pu(k) * net.baseMVA * 1000, ...
            r.voltvar_active(k), r.voltwatt_active(k), r.both_active(k)}; %#ok<AGROW>
    end
end

response = calculate_response_time(loadProfile.time_h, Vmag, net);
scenario.net = net;
scenario.pv = pv;
scenario.time_h = loadProfile.time_h;
scenario.loadMultiplier = loadProfile.multiplier;
scenario.irradiance = irrProfile.irradiance;
scenario.Vmag = Vmag;
scenario.loss_kW = loss_kW;
scenario.violations = violations;
scenario.curtail_kW = curtail_kW;
scenario.q_kVAr = q_kVAr;
scenario.outerIter = outerIter;
scenario.response = response;
scenario.strategy = strategy;
scenario.condition = condition;
scenario.penetrationPercent = penetrationPercent;
scenario.scenarioLabel = simOptions.scenarioLabel;
scenario.loadProfileType = simOptions.loadProfileType;
scenario.pvBusOption = simOptions.pvBusOption;
scenario.pvLog = cell2table(pvLogRows, 'VariableNames', ...
    {'TimeIndex', 'Time_h', 'Bus', 'LocalVoltage_pu', 'Pavailable_kW', ...
    'Poutput_kW', 'Pcurtailed_kW', 'Qoutput_kVAr', 'Qlimit_kVAr', ...
    'VoltVARActive', 'VoltWattActive', 'BothActive'});
end
