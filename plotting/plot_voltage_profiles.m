function plot_voltage_profiles(net, resultStruct, penetrationPercent, outputFile)
%PLOT_VOLTAGE_PROFILES Plot worst-time bus voltage profiles by strategy.

figure('Color', 'w', 'Position', [100 100 900 520]);
hold on;
grid on;
strategies = fieldnames(resultStruct);
for k = 1:numel(strategies)
    s = strategies{k};
    V = resultStruct.(s).Vmag;
    [~, idx] = max(max(abs(V - 1), [], 2));
    plot(1:net.nBus, V(idx, :), 'LineWidth', 1.6, 'DisplayName', strrep(s, '_', '\_'));
end
yline(net.Vmin, '--r', 'Vmin', 'HandleVisibility', 'off');
yline(net.Vmax, '--r', 'Vmax', 'HandleVisibility', 'off');
xlabel('Bus Number');
ylabel('Voltage Magnitude (p.u.)');
title(sprintf('IEEE 33-Bus Voltage Profile, PV Penetration %g%%', penetrationPercent));
legend('Location', 'best');
ylim([0.88 1.10]);
if nargin >= 4 && ~isempty(outputFile)
    exportgraphics(gcf, outputFile, 'Resolution', 200);
    close(gcf);
end
end
