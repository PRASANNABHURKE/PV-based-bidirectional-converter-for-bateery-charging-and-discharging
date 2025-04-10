# PV-Based Bidirectional Converter for Battery Charging and Discharging

This MATLAB project simulates a photovoltaic (PV) system with a bidirectional DC-DC converter for battery charging and discharging operations. The system demonstrates how solar energy can be used to charge a battery when excess power is available, and how the battery can supply power to the load when solar generation is insufficient.

## System Components

1. **PV Array**: Simulated using a single-diode model with temperature and irradiance effects
2. **Battery**: Modeled with state of charge (SOC) tracking and internal resistance
3. **Bidirectional DC-DC Converter**: Operates in buck mode (charging) or boost mode (discharging)
4. **Control System**: Includes Maximum Power Point Tracking (MPPT) for the PV array and mode selection based on power balance
5. **Load**: Represented as a resistive load

## Features

- **MPPT Algorithm**: Perturb and Observe method for maximum power extraction from the PV array
- **Bidirectional Power Flow**: Automatically switches between charging and discharging modes
- **Battery Protection**: Prevents over-charging and over-discharging based on SOC limits
- **Dynamic Irradiance**: Simulates changing environmental conditions
- **Comprehensive Visualization**: Plots for voltage, current, power, SOC, and converter operation mode

## How to Run

1. Open MATLAB
2. Navigate to the project directory
3. Run the script `pv_bidirectional_converter.m`
4. Observe the simulation results in the generated plots

## Simulation Parameters

The simulation includes configurable parameters for:
- PV array characteristics
- Battery specifications
- Converter components
- Load requirements
- Control parameters

These can be modified in the script to test different scenarios and system configurations.

## Results Interpretation

The simulation generates multiple plots showing:
- PV voltage and current
- Battery voltage, current, and state of charge
- Converter operation mode and duty cycle
- Power flow between PV array, battery, and load

Positive battery current indicates charging, while negative current indicates discharging.