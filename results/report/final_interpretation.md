# Final Research Interpretation

## 1. Model Description
This project uses a quasi-static time-series MATLAB load-flow model of the IEEE 33-bus radial distribution feeder. Smart inverter controls are represented by Volt-VAR and Volt-Watt control curves with inverter apparent-power limits.

## 2. IEEE 33-Bus Validation
The base-case validation passed with 33 buses, 32 branches, minimum voltage 0.9038 p.u., and active loss 211.00 kW.

## 3. Normal Proposal Scenario Results
For the normal 20%, 50%, and 80% PV proposal cases, Volt-Watt may be inactive when feeder voltage does not exceed the Volt-Watt threshold. This is reported honestly in the activation tables.
In the 80% PV partial-cloud case, no-control violations were 179. Hybrid-PSO mean voltage deviation was 0.0137 p.u.

## 4. Stress Scenario Results
Stress scenarios use low daytime load, clear-sky irradiance, end-feeder PV placement, and 80-200% PV penetration to create overvoltage in no-control cases.
At 150% PV stress, no-control maximum voltage was 1.1070 p.u.; hybrid maximum voltage was 1.0415 p.u.; hybrid-PSO maximum voltage was 1.0147 p.u.

## 5. Volt-Watt Activation
Volt-Watt activation in stress cases is proven in controller_activation_summary.csv. The maximum stress Volt-Watt active percentage is 100.00%.

## 6. Hybrid Control
Hybrid control combines active-power curtailment and reactive-power support. In normal cases it can match Volt-VAR when Volt-Watt is inactive; in stress cases it differs because Volt-Watt is activated.

## 7. PSO Optimization
PSO v2 used multiple seeds. Best objective 7.7890; default hybrid objective 16.8724. The optimized controller should be interpreted as improving the selected objective, not every individual metric.
Seed objective mean 9.8676 and standard deviation 1.8297.

## 8. Hosting Capacity
- none: 80% PV
- voltvar: 100% PV
- voltwatt: 120% PV
- hybrid: 250% PV
- hybrid_pso: 250% PV
Best hosting capacity in this study: hybrid at 250% PV.

## 9. Limitations
This is not EMT transient simulation. The response metric is a quasi-static voltage recovery indicator over time-series load-flow snapshots. Communication delay, detailed inverter switching, protection dynamics, and unbalanced phase modelling are outside the current scope.

## 10. Final Conclusion
The results support the proposal objectives with a careful interpretation: Volt-VAR is effective for voltage support, Volt-Watt is effective when overvoltage occurs, Hybrid is most valuable under high-PV stress, and PSO improves the selected multi-objective trade-off while possible loss/curtailment trade-offs must be reported.
