%% PV-Based Bidirectional Converter for Battery Charging and Discharging
% This program simulates a photovoltaic system with a bidirectional DC-DC converter
% for battery charging and discharging operations.

clear all;
close all;
clc;

%% Simulation Parameters
simulation_time = 2;     % Total simulation time in seconds
Ts = 1e-5;              % Sampling time in seconds
t = 0:Ts:simulation_time;  % Time vector
N = length(t);          % Number of simulation points

%% PV Array Parameters
PV_Voc = 48;            % Open circuit voltage (V)
PV_Isc = 10;            % Short circuit current (A)
PV_Vmp = 40;            % Maximum power point voltage (V)
PV_Imp = 9;             % Maximum power point current (A)
PV_Ns = 20;             % Number of series cells
PV_Np = 2;              % Number of parallel strings
T = 25;                 % Temperature in Celsius
G = 1000;               % Solar irradiance in W/m²

%% Battery Parameters
Batt_nominal_voltage = 24;  % Nominal battery voltage (V)
Batt_capacity = 100;        % Battery capacity (Ah)
Batt_initial_SOC = 50;      % Initial state of charge (%)
Batt_internal_resistance = 0.01; % Internal resistance (Ohm)

%% Converter Parameters
L = 1e-3;               % Inductor value (H)
C_in = 470e-6;          % Input capacitor (F)
C_out = 470e-6;         % Output capacitor (F)
f_sw = 20e3;            % Switching frequency (Hz)

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

% Battery variables
batt_voltage = zeros(1, N);
batt_current = zeros(1, N);
batt_power = zeros(1, N);
batt_SOC = zeros(1, N);

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
    
    % Limit duty cycle
    duty_cycle(k) = max(0.1, min(0.9, duty_cycle(k)));
    
    % Update battery voltage and SOC
    batt_power(k) = batt_voltage(k) * batt_current(k);
    
    % Use the modular battery model function
    [batt_voltage(k+1), batt_SOC(k+1)] = battery_model(batt_voltage(k), batt_current(k), batt_SOC(k), Batt_internal_resistance, Batt_capacity, Ts);
    
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
load_voltage(N) = batt_voltage(N);
load_current(N) = load_voltage(N) / R_load;
load_power(N) = load_voltage(N) * load_current(N);

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
title('Battery State of Charge');
xlabel('Time (s)');
ylabel('SOC (%)');
grid on;

subplot(3,2,6);
plot(t, converter_mode);
title('Converter Mode');
xlabel('Time (s)');
ylabel('Mode (1=Charging, -1=Discharging)');
grid on;

figure;
subplot(2,1,1);
plot(t, pv_power, t, load_power, t, batt_power);
title('Power Flow');
xlabel('Time (s)');
ylabel('Power (W)');
legend('PV Power', 'Load Power', 'Battery Power');
grid on;

subplot(2,1,2);
plot(t, duty_cycle);
title('Duty Cycle');
xlabel('Time (s)');
ylabel('Duty Cycle');
grid on;

%% Additional Analysis
% Call the analysis function if it exists
if exist('analyze_results', 'file') == 2
    analyze_results(t, pv_voltage, pv_current, pv_power, batt_voltage, batt_current, batt_power, batt_SOC, load_power, converter_mode, duty_cycle);
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