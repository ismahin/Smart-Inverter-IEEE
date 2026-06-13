# Simulink Results Viewer

The main research simulation remains in MATLAB quasi-static load-flow code. The Simulink model in this folder is a runnable visualization and replay model for the generated research results.

## Create the model

```matlab
startup_project
create_smart_inverter_results_viewer
```

This creates:

```text
simulink/Smart_Inverter_IEEE33_Results_Viewer.slx
results/figures/Smart_Inverter_IEEE33_Results_Viewer.png
```

## Run proposal-case visualization

```matlab
run_smart_inverter_results_viewer('proposal_80pct_partial_cloud','hybrid_pso')
```

## Run overvoltage stress visualization

```matlab
run_smart_inverter_results_viewer('stress_100pct_clear_low_daytime','hybrid_pso')
```

## What the model shows

- 33-bus voltage traces
- Minimum, mean, and maximum voltage envelope
- Mean voltage deviation
- Active power loss
- Voltage violation count
- PV curtailment
- Reactive power exchange
- Load and irradiance profiles

The model uses `From Workspace` blocks and scopes, so it is lightweight and easy to run. It is not an EMT/Simscape inverter switching model.
