function plot_case_comparison(summaryTable, metricName, yLabelText, outputFile)
%PLOT_CASE_COMPARISON Bar chart of one summary metric by strategy.

figure('Color', 'w', 'Position', [100 100 950 520]);
grouped = groupsummary(summaryTable, 'ControlStrategy', 'mean', metricName);
x = categorical(grouped.ControlStrategy);
y = grouped.("mean_" + metricName);
bar(x, y);
grid on;
ylabel(yLabelText);
xlabel('Control Strategy');
title(strrep(metricName, '_', ' '));
if nargin >= 4 && ~isempty(outputFile)
    exportgraphics(gcf, outputFile, 'Resolution', 200);
    close(gcf);
end
end
