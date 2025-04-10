%% Run Simulation Scenarios for PV-Based Bidirectional Converter
% This script runs multiple scenarios to demonstrate the bidirectional converter
% operation under different conditions

clear all;
close all;
clc;

disp('Running PV-Based Bidirectional Converter Simulation Scenarios');
disp('===========================================================');

%% Scenario 1: Normal operation with varying irradiance
disp('Scenario 1: Normal operation with varying irradiance');

% Set global parameters for this scenario
global G_PROFILE;
G_PROFILE = [1000, 800, 600, 400, 600, 800, 1000]; % W/m²
global G_TIMES;
G_TIMES = [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]; % seconds

% Run the main simulation
pv_bidirectional_converter;

% Save the figures for this scenario
fig1 = figure(1);
saveas(fig1, 'scenario1_voltages_currents.fig');
fig2 = figure(2);
saveas(fig2, 'scenario1_power_duty.fig');

%% Scenario 2: Heavy load condition
disp('\nScenario 2: Heavy load condition');

% Modify the load resistance to simulate heavy load
R_load = 5; % Lower resistance means higher load

% Set irradiance profile for this scenario
G_PROFILE = [1000, 900, 800, 700, 600, 500, 400]; % W/m²
G_TIMES = [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]; % seconds

% Run the main simulation
pv_bidirectional_converter;

% Save the figures for this scenario
fig1 = figure(1);
saveas(fig1, 'scenario2_voltages_currents.fig');
fig2 = figure(2);
saveas(fig2, 'scenario2_power_duty.fig');

%% Scenario 3: Low battery initial SOC
disp('\nScenario 3: Low battery initial SOC');

% Reset load to normal
R_load = 10;

% Set low initial battery SOC
Batt_initial_SOC = 30;

% Set constant high irradiance for charging
G_PROFILE = [1000, 1000, 1000, 1000, 1000, 1000, 1000]; % W/m²
G_TIMES = [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]; % seconds

% Run the main simulation
pv_bidirectional_converter;

% Save the figures for this scenario
fig1 = figure(1);
saveas(fig1, 'scenario3_voltages_currents.fig');
fig2 = figure(2);
saveas(fig2, 'scenario3_power_duty.fig');

%% Scenario 4: High battery initial SOC with low irradiance
disp('\nScenario 4: High battery initial SOC with low irradiance');

% Set high initial battery SOC
Batt_initial_SOC = 80;

% Set low irradiance profile
G_PROFILE = [400, 300, 200, 100, 200, 300, 400]; % W/m²
G_TIMES = [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]; % seconds

% Run the main simulation
pv_bidirectional_converter;

% Save the figures for this scenario
fig1 = figure(1);
saveas(fig1, 'scenario4_voltages_currents.fig');
fig2 = figure(2);
saveas(fig2, 'scenario4_power_duty.fig');

disp('\nAll scenarios completed. Results saved as .fig files.');
disp('Use "openfig(''filename.fig'')" to view the results.');