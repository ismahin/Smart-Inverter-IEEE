function settings = prepare_ieee33_simscape_inputs(penetrationPercent, condition, strategy)
%PREPARE_IEEE33_SIMSCAPE_INPUTS Prepare accelerated 24-hour input signals.
%
% One simulated second represents ten study hours. The 0.1-second interval
% allocated to every study hour contains five 50-Hz electrical cycles.

startup_project();
if nargin < 1 || isempty(penetrationPercent), penetrationPercent = 80; end
if nargin < 2 || isempty(condition), condition = 'partial_cloud'; end
if nargin < 3 || isempty(strategy), strategy = 'hybrid'; end

net = ieee33_data();
pv = apply_pv_penetration(net, penetrationPercent, select_pv_buses('default'));
loadProfile = create_load_profile('mixed', 1);
irradianceProfile = create_irradiance_profile(condition, 1);
params = default_control_params();

if strcmpi(strategy, 'hybrid_pso')
    bestFile = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'results', 'mat_files', 'best_params_v2.mat');
    if isfile(bestFile)
        saved = load(bestFile);
        candidates = {'bestParams', 'bestParamsV2', 'optimizedParams'};
        for index = 1:numel(candidates)
            if isfield(saved, candidates{index})
                value = saved.(candidates{index});
                if isnumeric(value) && numel(value) >= 9
                    params = vector_to_control_params(value(:)');
                elseif isstruct(value)
                    params = value;
                end
                break;
            end
        end
    end
end

switch lower(strategy)
    case 'none'
        vvEnable = 0;
        vwEnable = 0;
    case 'voltvar'
        vvEnable = 1;
        vwEnable = 0;
    case 'voltwatt'
        vvEnable = 0;
        vwEnable = 1;
    case {'hybrid', 'hybrid_pso'}
        vvEnable = 1;
        vwEnable = 1;
    otherwise
        error('Unsupported Simscape controller strategy: %s', strategy);
end

nTime = numel(loadProfile.time_h);
nPv = numel(pv.buses);
pCommand_kW = zeros(nTime, nPv);
qCommand_kVAr = zeros(nTime, nPv);
curtailCommand_kW = zeros(nTime, nPv);
for timeIndex = 1:nTime
    controlled = apply_smart_inverter_control(net, pv, ...
        loadProfile.multiplier(timeIndex), irradianceProfile.irradiance(timeIndex), ...
        strategy, params);
    pCommand_kW(timeIndex, :) = controlled.Ppv_pu(:)' * net.baseMVA * 1000;
    qCommand_kVAr(timeIndex, :) = controlled.Qpv_pu(:)' * net.baseMVA * 1000;
    curtailCommand_kW(timeIndex, :) = controlled.Pcurtailed_kW(:)';
end

secondsPerHour = 0.1;
timeSeconds = [loadProfile.time_h(:) * secondsPerHour; 24 * secondsPerHour];
loadValues = [loadProfile.multiplier(:); loadProfile.multiplier(end)];
irradianceValues = [irradianceProfile.irradiance(:); irradianceProfile.irradiance(end)];

assignin('base', 'simscape_load_scale', timeseries(loadValues, timeSeconds));
assignin('base', 'simscape_irradiance', timeseries(irradianceValues, timeSeconds));
assignin('base', 'simscape_pv_p_commands', ...
    timeseries([pCommand_kW; pCommand_kW(end, :)], timeSeconds));
assignin('base', 'simscape_pv_q_commands', ...
    timeseries([qCommand_kVAr; qCommand_kVAr(end, :)], timeSeconds));
assignin('base', 'simscape_pv_curtail_commands', ...
    timeseries([curtailCommand_kW; curtailCommand_kW(end, :)], timeSeconds));
assignin('base', 'simscape_pv_capacity_kW', pv.capacity_kW(:)');
assignin('base', 'simscape_params', params);
assignin('base', 'simscape_vv_enable', vvEnable);
assignin('base', 'simscape_vw_enable', vwEnable);
assignin('base', 'simscape_seconds_per_hour', secondsPerHour);

settings.penetrationPercent = penetrationPercent;
settings.condition = condition;
settings.strategy = strategy;
settings.net = net;
settings.pv = pv;
settings.controlParams = params;
settings.pCommand_kW = pCommand_kW;
settings.qCommand_kVAr = qCommand_kVAr;
settings.curtailCommand_kW = curtailCommand_kW;
settings.stopTime_s = 24 * secondsPerHour;
settings.secondsPerHour = secondsPerHour;
assignin('base', 'simscape_settings', settings);
end
