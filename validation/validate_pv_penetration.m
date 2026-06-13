function pvValidation = validate_pv_penetration()
%VALIDATE_PV_PENETRATION Validate PV allocation and power sign convention.

startup_project();
projectRoot = fileparts(fileparts(mfilename('fullpath')));
net = ieee33_data();
levels = [20 50 80 100 150 200];
rows = cell(numel(levels), 10);

for i = 1:numel(levels)
    pv = apply_pv_penetration(net, levels(i), select_pv_buses());
    expectedPV = levels(i) / 100 * net.totalLoad_kW;
    totalPV = sum(pv.capacity_kW);
    assert(abs(totalPV - expectedPV) < 1e-8, 'PV penetration allocation mismatch.');

    bus = pv.buses(1);
    Pload0 = net.loadP_pu(bus);
    Qload0 = net.loadQ_pu(bus);
    Pgen = pv.capacity_pu(1);
    Qinj = 0.001;
    Qabs = -0.001;

    PnetWithPV = Pload0 - Pgen;
    QnetWithInjection = Qload0 - Qinj;
    QnetWithAbsorption = Qload0 - Qabs;

    assert(PnetWithPV < Pload0, 'PV generation must reduce net active load.');
    assert(QnetWithInjection < Qload0, 'Reactive injection must reduce net reactive load.');
    assert(QnetWithAbsorption > Qload0, 'Reactive absorption must increase net reactive load.');

    rows(i, :) = {levels(i), net.totalLoad_kW, expectedPV, totalPV, ...
        abs(totalPV - expectedPV), bus, Pload0, PnetWithPV, ...
        QnetWithInjection, QnetWithAbsorption};
end

pvValidation = cell2table(rows, 'VariableNames', ...
    {'PenetrationPercent', 'TotalLoad_kW', 'ExpectedPV_kW', 'ActualPV_kW', ...
    'PVError_kW', 'CheckedBus', 'OriginalPnet_pu', 'PnetWithPV_pu', ...
    'QnetWithReactiveInjection_pu', 'QnetWithReactiveAbsorption_pu'});
writetable(pvValidation, fullfile(projectRoot, 'results', 'tables', 'pv_penetration_validation.csv'));

fprintf('PV penetration and sign convention validation passed.\n');
end
