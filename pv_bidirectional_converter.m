%% PV-Based Bidirectional Converter for Battery Charging and Discharging
% This program simulates a photovoltaic system with a bidirectional DC-DC converter
% for battery charging and discharging operations.

clear all;
close all;
clc;

%% System Configuration
% Set battery system voltage (24V or 48V)
battery_system = 24;    % Options: 24 or 48 (Volts)

%% Simulation Parameters
simulation_time = 2;     % Total simulation time in seconds
Ts = 1e-5;              % Sampling time in seconds
t = 0:Ts:simulation_time;  % Time vector
N = length(t);          % Number of simulation points

%% PV Array Parameters
% Updated to match technical specifications
PV_Voc = 42;            % Open circuit voltage (V) - Range: 40-45V
PV_Isc = 10;            % Short circuit current (A) - Range: 9-11A
PV_Vmp = 35;            % Maximum power point voltage (V) - Range: 30-36V
PV_Imp = 9;             % Maximum power point current (A) - Range: 8-10A
PV_Ns = 20;             % Number of series cells
PV_Np = 2;              % Number of parallel strings
PV_power_rating = PV_Vmp * PV_Imp; % Power rating (W) - Range: 250-500W
T = 25;                 % Temperature in Celsius
G = 1000;               % Solar irradiance in W/m²

%% Battery Parameters
% Updated to match technical specifications
Batt_nominal_voltage = battery_system;  % Nominal battery voltage (V) - Options: 24V or 48V
Batt_capacity = 75;         % Battery capacity (Ah) - Range: 50-100Ah
Batt_initial_SOC = 50;      % Initial state of charge (%)
Batt_internal_resistance = 0.01; % Internal resistance (Ohm)
Batt_temperature = 25;      % Battery temperature in Celsius

% Set charging and discharge cutoff voltages based on battery system
if Batt_nominal_voltage == 24
    Batt_charging_voltage = 28.8;    % Charging voltage for 24V system (1.2 * nominal)
    Batt_discharge_cutoff = 21.0;    % Discharge cut-off voltage for 24V system (0.875 * nominal)
elseif Batt_nominal_voltage == 48
    Batt_charging_voltage = 57.6;    % Charging voltage for 48V system (1.2 * nominal)
    Batt_discharge_cutoff = 42.0;    % Discharge cut-off voltage for 48V system (0.875 * nominal)
end

% Battery thermal model parameters
Batt_thermal_resistance = 10;    % Thermal resistance (°C/W)
Batt_thermal_capacitance = 1000; % Thermal capacitance (J/°C)
Ambient_temperature = 20;        % Ambient temperature (°C)

%% Converter Parameters
% Updated to match technical specifications
L = 1e-3;               % Inductor value (H)
C_in = 470e-6;          % Input capacitor (F)
C_out = 470e-6;         % Output capacitor (F)
f_sw = 50e3;            % Switching frequency (Hz) - Range: 20kHz-100kHz
max_current = 15;       % Maximum current (A)
conv_efficiency = 0.92; % Converter efficiency (≥ 90%)

% Converter topology: Non-isolated bidirectional buck-boost
% Input voltage range: 25V-50V
% Output voltage range: 24V-48V

%% Load Parameters
R_load = 10;            % Load resistance (Ohm)

%% Control Parameters
MPPT_step = 0.01;       % MPPT step size
SOC_min = 20;           % Minimum SOC (%)
SOC_max = 90;           % Maximum SOC (%)

%% Initialize Arrays
% PV variables
pv_voltage = zeros(1, N);
pv_current = zeros(1, N);
pv_power = zeros(1, N);
pv_max_power = zeros(1, N);  % For MPPT efficiency calculation

% Battery variables
batt_voltage = zeros(1, N);
batt_current = zeros(1, N);
batt_power = zeros(1, N);
batt_SOC = zeros(1, N);
batt_temperature = ones(1, N) * Batt_temperature; % Initialize battery temperature array
batt_temperature(1) = Batt_temperature; % Set initial temperature

% BMS variables
batt_status = cell(1, N);
batt_status{1} = 'Normal';
protection_flags = struct('overvoltage', false, 'undervoltage', false, 'overcurrent_charge', false, 'overcurrent_discharge', false, 'overtemperature', false, 'undertemperature', false, 'high_soc', false, 'low_soc', false, 'reverse_polarity', false);
protection_flags_array(1) = protection_flags;

% MPPT variables
mppt_efficiency = zeros(1, N);  % Track MPPT efficiency

% Converter variables
duty_cycle = zeros(1, N);
converter_mode = zeros(1, N); % 1 for charging, -1 for discharging, 0 for idle

% Load variables
load_voltage = zeros(1, N);
load_current = zeros(1, N);
load_power = zeros(1, N);

%% Initial Conditions
pv_voltage(1) = PV_Vmp;
batt_voltage(1) = Batt_nominal_voltage;
batt_SOC(1) = Batt_initial_SOC;
duty_cycle(1) = 0.5;

%% Simulation Loop
for k = 1:N-1
    % Update time-varying irradiance based on profile (if defined)
    if exist('G_PROFILE', 'var') && exist('G_TIMES', 'var')
        % Find the appropriate irradiance level based on current time
        for i = length(G_TIMES):-1:1
            if t(k) >= G_TIMES(i)
                G = G_PROFILE(i);
                break;
            end
        end
    else
        % Default behavior if no profile is defined
        if t(k) > 1
            G = 800; % Reduced irradiance after 1 second
        end
    end
    
    % Calculate PV current using single-diode model
    pv_current(k) = PV_model(pv_voltage(k), G, T, PV_Isc, PV_Voc, PV_Ns, PV_Np);
    pv_power(k) = pv_voltage(k) * pv_current(k);
    
    % Calculate theoretical maximum power at current irradiance and temperature
    % This is used for MPPT efficiency calculation
    pv_max_power(k) = PV_Vmp * PV_Imp * (G/1000);  % Scale by irradiance ratio
    
    % Calculate load power
    load_voltage(k) = batt_voltage(k);
    load_current(k) = load_voltage(k) / R_load;
    load_power(k) = load_voltage(k) * load_current(k);
    
    % Determine converter mode based on power balance and battery SOC
    if pv_power(k) > load_power(k) && batt_SOC(k) < SOC_max
        % Charging mode (PV to Battery)
        converter_mode(k) = 1;
        
        % MPPT algorithm (Perturb & Observe) using the modular function
        if k > 1
            duty_cycle(k) = mppt_algorithm(pv_voltage(k), pv_current(k), pv_voltage(k-1), pv_current(k-1), duty_cycle(k-1), MPPT_step);
        end
        
        % Calculate battery charging current (Buck converter mode)
        batt_current(k) = (pv_power(k) - load_power(k)) / batt_voltage(k);
        
    elseif pv_power(k) < load_power(k) && batt_SOC(k) > SOC_min
        % Discharging mode (Battery to Load)
        converter_mode(k) = -1;
        
        % Calculate battery discharging current (Boost converter mode)
        batt_current(k) = -(load_power(k) - pv_power(k)) / batt_voltage(k);
        duty_cycle(k) = 1 - (pv_voltage(k) / batt_voltage(k));
        
    else
        % Idle mode
        converter_mode(k) = 0;
        batt_current(k) = 0;
        duty_cycle(k) = duty_cycle(k-1);
    end
    
    % Apply Battery Management System (BMS) to protect the battery
    [batt_current(k), batt_status{k}, protection_flags] = battery_management_system(batt_voltage(k), batt_current(k), batt_SOC(k), batt_temperature(k), Batt_nominal_voltage, Batt_capacity);
    protection_flags_array(k) = protection_flags;
    
    % Calculate MPPT efficiency
    if pv_max_power(k) > 0 && converter_mode(k) == 1  % Only in charging mode
        mppt_efficiency(k) = (pv_power(k) / pv_max_power(k)) * 100;
    else
        mppt_efficiency(k) = 0;
    end
    
    % Limit duty cycle
    duty_cycle(k) = max(0.1, min(0.9, duty_cycle(k)));
    
    % Update battery voltage and SOC
    batt_power(k) = batt_voltage(k) * batt_current(k);
    
    % Use the modular battery model function with temperature parameter
    [batt_voltage(k+1), batt_SOC(k+1)] = battery_model(batt_voltage(k), batt_current(k), batt_SOC(k), Batt_internal_resistance, Batt_capacity, Ts, batt_temperature(k));
    
    % Update battery temperature using thermal model
    batt_temperature(k+1) = battery_thermal_model(batt_temperature(k), batt_current(k), batt_voltage(k), Ambient_temperature, Batt_thermal_resistance, Batt_thermal_capacitance, Ts);
    
    % Use the bidirectional converter model to update PV voltage
    [pv_voltage_new, converter_mode_check] = bidirectional_converter_model(pv_power(k), load_power(k), batt_voltage(k), batt_SOC(k), pv_voltage(k), duty_cycle(k), SOC_min, SOC_max);
    
    % Verify converter mode is consistent
    if converter_mode_check ~= converter_mode(k)
        % This is a safety check - modes should match
        warning('Converter mode mismatch detected');
    end
    
    % Update PV voltage with small perturbation for MPPT if needed
    if converter_mode(k) ~= 1 % If not in charging mode
        pv_voltage(k+1) = pv_voltage_new + MPPT_step * (2 * rand - 1); % Add small perturbation for MPPT
    else
        pv_voltage(k+1) = pv_voltage_new;
    end
    
    % Limit PV voltage
    pv_voltage(k+1) = max(0.1, min(PV_Voc, pv_voltage(k+1)));
 end

% Calculate final values for the last time step
pv_current(N) = PV_model(pv_voltage(N), G, T, PV_Isc, PV_Voc, PV_Ns, PV_Np);
pv_power(N) = pv_voltage(N) * pv_current(N);
pv_max_power(N) = PV_Vmp * PV_Imp * (G/1000);  % Scale by irradiance ratio
load_voltage(N) = batt_voltage(N);
load_current(N) = load_voltage(N) / R_load;
load_power(N) = load_voltage(N) * load_current(N);

% Calculate MPPT efficiency for the last time step
if pv_max_power(N) > 0
    mppt_efficiency(N) = (pv_power(N) / pv_max_power(N)) * 100;
else
    mppt_efficiency(N) = 0;
end

% Calculate average MPPT efficiency
valid_indices = mppt_efficiency > 0;
if any(valid_indices)
    avg_mppt_efficiency = mean(mppt_efficiency(valid_indices));
    fprintf('Average MPPT Efficiency: %.2f%%\n', avg_mppt_efficiency);
else
    fprintf('No valid MPPT efficiency data available.\n');
end

%% Plot Results
figure;
subplot(3,2,1);
plot(t, pv_voltage);
title('PV Voltage');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;

subplot(3,2,2);
plot(t, pv_current);
title('PV Current');
xlabel('Time (s)');
ylabel('Current (A)');
grid on;

subplot(3,2,3);
plot(t, batt_voltage);
title('Battery Voltage');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;

subplot(3,2,4);
plot(t, batt_current);
title('Battery Current');
xlabel('Time (s)');
ylabel('Current (A)');
grid on;

subplot(3,2,5);
plot(t, batt_SOC);
title('Battery SOC');
xlabel('Time (s)');
ylabel('SOC (%)');
grid on;

subplot(3,2,6);
plot(t, converter_mode);
title('Converter Mode');
xlabel('Time (s)');
ylabel('Mode');
yticks([-1, 0, 1]);
yticklabels({'Discharging', 'Idle', 'Charging'});
grid on;

% Display system configuration
fprintf('\nSystem Configuration:\n');
fprintf('Battery System: %dV\n', Batt_nominal_voltage);
fprintf('PV Power Rating: %.1fW\n', PV_power_rating);
fprintf('Battery Capacity: %.1fAh\n', Batt_capacity);
fprintf('Converter Switching Frequency: %.1fkHz\n', f_sw/1000);
fprintf('Converter Efficiency: %.1f%%\n', conv_efficiency*100);

% Call the analyze_results function with all parameters including MPPT efficiency
analyze_results(t, pv_voltage, pv_current, pv_power, batt_voltage, batt_current, batt_power, batt_SOC, load_power, converter_mode, duty_cycle, batt_status, protection_flags_array, batt_temperature, pv_max_power, mppt_efficiency);

% Create a new figure for battery temperature
figure;
plot(t, batt_temperature, 'r-', 'LineWidth', 1.5);
title('Battery Temperature');
xlabel('Time (s)');
ylabel('Temperature (°C)');
grid on;
hold on;
plot(t, ones(size(t))*Ambient_temperature, 'b--', 'LineWidth', 1);
legend('Battery Temperature', 'Ambient Temperature');


figure;
subplot(3,1,1);
plot(t, pv_power, t, load_power, t, batt_power);
title('Power Flow');
xlabel('Time (s)');
ylabel('Power (W)');
legend('PV Power', 'Load Power', 'Battery Power');
grid on;

subplot(3,1,2);
plot(t, duty_cycle);
title('Duty Cycle');
xlabel('Time (s)');
ylabel('Duty Cycle');
grid on;

% Plot BMS status
subplot(3,1,3);
% Create a numeric representation of battery status for plotting
batt_status_numeric = zeros(1, N);
for i = 1:N
    if strcmp(batt_status{i}, 'Normal')
        batt_status_numeric(i) = 0;
    elseif contains(batt_status{i}, 'Overvoltage')
        batt_status_numeric(i) = 1;
    elseif contains(batt_status{i}, 'Undervoltage')
        batt_status_numeric(i) = 2;
    elseif contains(batt_status{i}, 'Charge Current')
        batt_status_numeric(i) = 3;
    elseif contains(batt_status{i}, 'Discharge Current')
        batt_status_numeric(i) = 4;
    elseif contains(batt_status{i}, 'Temperature')
        batt_status_numeric(i) = 5;
    elseif contains(batt_status{i}, 'SOC')
        batt_status_numeric(i) = 6;
    end
end
plot(t, batt_status_numeric);
title('BMS Status');
xlabel('Time (s)');
yticks(0:6);
yticklabels({'Normal', 'Overvoltage', 'Undervoltage', 'Charge Limit', 'Discharge Limit', 'Temp Limit', 'SOC Limit'});
grid on;

%% Additional Analysis
% Call the analysis function if it exists
if exist('analyze_results', 'file') == 2
    analyze_results(t, pv_voltage, pv_current, pv_power, batt_voltage, batt_current, batt_power, batt_SOC, load_power, converter_mode, duty_cycle, batt_status, protection_flags_array, batt_temperature);
end

%% PV Model Function
function I = PV_model(V, G, T, Isc, Voc, Ns, Np)
    % Simple PV model based on the single-diode equation
    k = 1.38e-23;    % Boltzmann constant
    q = 1.6e-19;     % Electron charge
    A = 1.2;         % Ideality factor
    T_ref = 25 + 273.15; % Reference temperature in Kelvin
    T_K = T + 273.15;    % Operating temperature in Kelvin
    
    % Temperature and irradiance corrections
    Isc_T = Isc * (G/1000) * (1 + 0.0017*(T - 25));
    Voc_T = Voc * (1 - 0.0023*(T - 25));
    
    % Thermal voltage
    Vt = Ns * k * T_K / q;
    
    % Saturation current
    I0 = Isc_T / (exp(Voc_T/(A*Vt)) - 1);
    
    % PV current equation
    I = Np * (Isc_T - I0 * (exp(V/(A*Vt)) - 1));
    
    % Ensure current is not negative (no reverse current flow)
    I = max(0, I);
end