# User Guide: PV-Based Bidirectional Converter for Battery Charging and Discharging

## Introduction

This user guide provides detailed information on how to use, configure, and analyze the MATLAB simulation of a photovoltaic (PV) system with a bidirectional DC-DC converter for battery charging and discharging operations. The system demonstrates how solar energy can be used to charge a battery when excess power is available, and how the battery can supply power to the load when solar generation is insufficient.

## System Architecture

The simulation consists of the following components:

1. **PV Array**: Simulated using a single-diode model with temperature and irradiance effects
2. **Battery**: Modeled with state of charge (SOC) tracking and internal resistance
3. **Bidirectional DC-DC Converter**: Operates in buck mode (charging) or boost mode (discharging)
4. **Control System**: Includes Maximum Power Point Tracking (MPPT) for the PV array and mode selection based on power balance
5. **Load**: Represented as a resistive load

## File Structure

- `pv_bidirectional_converter.m`: Main simulation script
- `mppt_algorithm.m`: Implementation of the Perturb and Observe MPPT algorithm
- `battery_model.m`: Battery modeling function with SOC tracking
- `bidirectional_converter_model.m`: Converter model for both charging and discharging modes
- `analyze_results.m`: Additional analysis and visualization of simulation results
- `run_simulation_scenarios.m`: Script to run multiple simulation scenarios
- `README.md`: Overview of the project
- `USER_GUIDE.md`: This detailed user guide

## Configuration Parameters

### PV Array Parameters

```matlab
PV_Voc = 48;            % Open circuit voltage (V)
PV_Isc = 10;            % Short circuit current (A)
PV_Vmp = 40;            % Maximum power point voltage (V)
PV_Imp = 9;             % Maximum power point current (A)
PV_Ns = 20;             % Number of series cells
PV_Np = 2;              % Number of parallel strings
T = 25;                 % Temperature in Celsius
G = 1000;               % Solar irradiance in W/m²
```

### Battery Parameters

```matlab
Batt_nominal_voltage = 24;  % Nominal battery voltage (V)
Batt_capacity = 100;        % Battery capacity (Ah)
Batt_initial_SOC = 50;      % Initial state of charge (%)
Batt_internal_resistance = 0.01; % Internal resistance (Ohm)
```

### Converter Parameters

```matlab
L = 1e-3;               % Inductor value (H)
C_in = 470e-6;          % Input capacitor (F)
C_out = 470e-6;         % Output capacitor (F)
f_sw = 20e3;            % Switching frequency (Hz)
```

### Load Parameters

```matlab
R_load = 10;            % Load resistance (Ohm)
```

### Control Parameters

```matlab
MPPT_step = 0.01;       % MPPT step size
SOC_min = 20;           % Minimum SOC (%)
SOC_max = 90;           % Maximum SOC (%)
```

### Simulation Parameters

```matlab
simulation_time = 2;     % Total simulation time in seconds
Ts = 1e-5;              % Sampling time in seconds
```

## Running Simulations

### Basic Simulation

To run a basic simulation with default parameters:

1. Open MATLAB
2. Navigate to the project directory
3. Run the script `pv_bidirectional_converter.m`
4. Observe the simulation results in the generated plots

### Running Multiple Scenarios

The `run_simulation_scenarios.m` script provides a way to run multiple simulation scenarios with different parameters:

1. Open MATLAB
2. Navigate to the project directory
3. Run the script `run_simulation_scenarios.m`
4. The script will run four different scenarios:
   - Scenario 1: Normal operation with varying irradiance
   - Scenario 2: Heavy load condition
   - Scenario 3: Low battery initial SOC
   - Scenario 4: High battery initial SOC with low irradiance
5. Results for each scenario are saved as `.fig` files

### Creating Custom Scenarios

To create your own custom scenarios:

1. Open `run_simulation_scenarios.m`
2. Copy one of the existing scenario blocks
3. Modify the parameters as needed
4. Add your custom scenario to the script
5. Run the script

## Configuring Irradiance Profiles

The simulation supports time-varying irradiance profiles to simulate changing environmental conditions:

```matlab
% Example of setting a custom irradiance profile
global G_PROFILE;
G_PROFILE = [1000, 800, 600, 400, 600, 800, 1000]; % W/m²
global G_TIMES;
G_TIMES = [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]; % seconds
```

The `G_PROFILE` array contains irradiance values in W/m², and the `G_TIMES` array contains the corresponding time points in seconds. The simulation will interpolate between these points to create a continuous irradiance profile.

## Interpreting Results

### Basic Plots

The main simulation script generates two figures with the following plots:

**Figure 1:**
- PV Voltage
- PV Current
- Battery Voltage
- Battery Current
- Battery State of Charge
- Converter Mode

**Figure 2:**
- Power Flow (PV Power, Load Power, Battery Power)
- Duty Cycle

### Advanced Analysis

The `analyze_results.m` function provides additional analysis and visualization:

**PV Characteristics:**
- PV I-V Operating Points
- PV P-V Operating Points
- Estimated Converter Efficiency
- Cumulative Energy

**System Performance:**
- Battery SOC and Converter Mode
- Power Distribution
- Energy Distribution
- MPPT Tracking Performance

## Understanding Converter Modes

The converter operates in three modes:

1. **Charging Mode (1)**: When PV power exceeds load power and battery SOC is below maximum limit
   - Buck converter operation (PV to Battery)
   - MPPT algorithm active
   - Positive battery current

2. **Discharging Mode (-1)**: When PV power is less than load power and battery SOC is above minimum limit
   - Boost converter operation (Battery to Load)
   - Negative battery current

3. **Idle Mode (0)**: When neither charging nor discharging conditions are met
   - No power flow to/from battery
   - Battery current is zero

## Modifying the System

### Changing PV Array Specifications

To model a different PV array, modify the PV parameters in the main script:

```matlab
PV_Voc = 45;            % New open circuit voltage (V)
PV_Isc = 11;            % New short circuit current (A)
PV_Vmp = 36;            % New maximum power point voltage (V)
PV_Imp = 10;            % New maximum power point current (A)
PV_Ns = 18;             % New number of series cells
PV_Np = 3;              % New number of parallel strings
```

### Changing Battery Specifications

To model a different battery, modify the battery parameters:

```matlab
Batt_nominal_voltage = 48;  % New nominal battery voltage (V)
Batt_capacity = 75;         % New battery capacity (Ah)
Batt_initial_SOC = 60;      % New initial state of charge (%)
Batt_internal_resistance = 0.015; % New internal resistance (Ohm)
```

### Modifying MPPT Algorithm

The MPPT algorithm is implemented in `mppt_algorithm.m`. To modify the algorithm:

1. Open `mppt_algorithm.m`
2. Modify the algorithm implementation as needed
3. Save the file
4. Run the simulation

## Troubleshooting

### Common Issues

1. **Simulation Runs Slowly**
   - Reduce the simulation time or increase the sampling time
   - Simplify the model by reducing the number of components

2. **Unrealistic Battery Behavior**
   - Check battery parameters, especially capacity and internal resistance
   - Verify that SOC limits are appropriate

3. **MPPT Not Working Correctly**
   - Adjust the MPPT step size
   - Check PV array parameters

4. **Converter Mode Switching Too Frequently**
   - Implement hysteresis in the mode selection logic
   - Add filtering to power measurements

## Extending the Model

### Adding Temperature Effects

The current model includes basic temperature effects for the PV array. To enhance this:

1. Add a thermal model for the battery
2. Implement temperature-dependent efficiency for the converter
3. Add ambient temperature variations to simulate day/night cycles

### Implementing Grid Connection

To extend the model to include grid connection:

1. Add a grid-tie inverter model
2. Implement grid synchronization algorithms
3. Add logic for grid power import/export

### Adding More Realistic Load Profiles

To simulate more realistic load conditions:

1. Replace the constant resistive load with a time-varying load profile
2. Implement different load types (resistive, inductive, capacitive)
3. Add random load variations to simulate real-world conditions

## Conclusion

This user guide provides a comprehensive overview of the PV-based bidirectional converter simulation system. By following the instructions and guidelines provided, you can effectively use, configure, and analyze the system for various scenarios and applications.

For further assistance or to report issues, please contact the project maintainer.