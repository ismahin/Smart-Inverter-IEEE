function m = calculate_voltage_metrics(Vmag, net)
%CALCULATE_VOLTAGE_METRICS Voltage quality metrics for one or many steps.

V = Vmag(:);
below = V < net.Vmin;
above = V > net.Vmax;
dev = abs(V - net.Vnom);

m.maxVoltage = max(V);
m.minVoltage = min(V);
m.meanAbsVoltageDeviation = mean(dev);
m.maxAbsVoltageDeviation = max(dev);
m.numBelowVmin = sum(below);
m.numAboveVmax = sum(above);
m.totalViolationCount = sum(below | above);
m.voltageDeviationPercent = 100 * mean(dev) / net.Vnom;
end
