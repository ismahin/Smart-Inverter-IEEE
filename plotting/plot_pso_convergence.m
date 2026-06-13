function plot_pso_convergence(history, outputFile)
%PLOT_PSO_CONVERGENCE Plot best objective value by PSO iteration.

figure('Color', 'w', 'Position', [120 120 850 500]);
plot(history.Iteration, history.BestObjective, '-o', 'LineWidth', 1.6);
grid on;
xlabel('PSO Iteration');
ylabel('Best Objective Value');
title('PSO Convergence');
if nargin >= 2 && ~isempty(outputFile)
    exportgraphics(gcf, outputFile, 'Resolution', 200);
    close(gcf);
end
end
