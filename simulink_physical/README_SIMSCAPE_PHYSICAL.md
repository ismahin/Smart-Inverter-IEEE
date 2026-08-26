# IEEE 33-Bus Component-Based Simscape Model

`IEEE33_SmartInverter_Physical.slx` is an executable Simscape Electrical version of the MATLAB quasi-static project. It is separate from the existing workflow diagram and results viewer.

## Build and run

From the project root:

```matlab
startup_project
addpath('simulink_physical')
build_ieee33_simscape_model
run_ieee33_simscape_model(80, 'partial_cloud', 'hybrid', true)
```

Other controller modes are `none`, `voltvar`, `voltwatt`, and `hybrid_pso`.

## Native components used

- Simscape Electrical three-phase voltage source at 12.66 kV and 50 Hz
- 32 three-phase series R-L line sections using the IEEE 33-bus ohmic data
- 32 three-phase dynamic active/reactive-power loads
- 33 three-phase line-voltage sensors and physical-signal RMS estimators
- Six physical Solar Cell arrays with resistive DC operating-point loads
- Six native three-phase dynamic P-Q components as averaged grid-following inverters
- The project's exact converged Volt-VAR/Volt-Watt MATLAB controller supplies hourly P-Q commands
- Standard Scopes and workspace logging blocks

Open the blue `IEEE 33-Bus Physical Feeder` subsystem to see the electrical components.

## Scopes

- `All 33 Bus Voltages Scope`: all bus RMS voltages in per unit
- `Voltage Envelope Scope`: feeder minimum and maximum bus voltage
- `PV P-Q-Curtailment Scope`: total active power, reactive power, and curtailed power
- `Profiles Scope`: load multiplier and irradiance

The workspace signals are `simscape_bus_voltage_pu`, `simscape_voltage_envelope`, and `simscape_pv_outputs`.

Voltage signals shown in the Scopes are sampled 0.085 s into each 0.1-s hourly interval, after the five-cycle RMS window has settled. This deliberately excludes brief electrical re-initialization impulses at accelerated hour boundaries.

## Time and model fidelity

The day is accelerated so 0.1 simulated second represents one study hour. Each hourly interval still contains five 50-Hz cycles for RMS measurement. Profile and converged controller-command points are linearly interpolated to avoid nonphysical voltage impulses from instantaneous power steps. This is a balanced three-phase average-value model matching the original code's quasi-static assumptions. The averaged inverter uses commanded P and Q rather than semiconductor PWM switching. It is appropriate for feeder voltage regulation and power-flow comparison, but not for switching harmonics, protection timing, or detailed EMT inverter design.
