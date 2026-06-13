function plot_time_series_results(time_h, Vseries, buses, labels, outputFile)
%PLOT_TIME_SERIES_RESULTS Plot voltage over time for selected buses.

figure('Color', 'w', 'Position', [120 120 900 520]);
hold on;
grid on;
for k = 1:numel(buses)
    plot(time_h, Vseries(:, buses(k)), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s Bus %d', labels, buses(k)));
end
xlabel('Time (hours)');
ylabel('Voltage Magnitude (p.u.)');
title('Voltage Time-Series at Monitored Buses');
legend('Location', 'best');
if nargin >= 5 && ~isempty(outputFile)
    exportgraphics(gcf, outputFile, 'Resolution', 200);
    close(gcf);
end
end
