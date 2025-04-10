%% Battery Model Function for PV System
% This function simulates battery behavior including voltage, current, and SOC calculations

function [batt_voltage_new, batt_SOC_new] = battery_model(batt_voltage, batt_current, batt_SOC, internal_resistance, capacity, Ts, batt_temperature)
    % If temperature is not provided, use default temperature (25°C)
    if nargin < 7
        batt_temperature = 25;
    end
    
    % Temperature-dependent internal resistance
    % Resistance increases at low temperatures and decreases at high temperatures
    % Simplified model: R = R_ref * exp(alpha * (T_ref - T))
    T_ref = 25; % Reference temperature in Celsius
    alpha = 0.01; % Temperature coefficient
    temp_adjusted_resistance = internal_resistance * exp(alpha * (T_ref - batt_temperature));
    
    % Temperature-dependent capacity
    % Capacity decreases at low temperatures
    % Simplified model: C = C_ref * (1 - beta * (T_ref - T)) for T < T_ref
    beta = 0.005; % Temperature coefficient for capacity
    temp_capacity_factor = 1;
    if batt_temperature < T_ref
        temp_capacity_factor = 1 - beta * (T_ref - batt_temperature);
    end
    temp_adjusted_capacity = capacity * temp_capacity_factor;
    
    % Calculate new battery voltage considering temperature-adjusted internal resistance
    % V_batt = V_oc - I_batt * R_internal
    batt_voltage_new = batt_voltage - batt_current * temp_adjusted_resistance;
    
    % Update State of Charge using Coulomb counting method with temperature-adjusted capacity
    % SOC_new = SOC_old - (I_batt * Ts / (Capacity * 3600)) * 100
    % Note: Negative current means charging, positive means discharging
    batt_SOC_new = batt_SOC - (batt_current * Ts / (temp_adjusted_capacity * 3600)) * 100;
    
    % Limit SOC between 0% and 100%
    batt_SOC_new = max(0, min(100, batt_SOC_new));
    
    % Add self-discharge effect (increases with temperature)
    % Simplified model: self_discharge_rate = base_rate * exp(gamma * (T - T_ref))
    if batt_temperature > T_ref
        base_self_discharge_rate = 0.02; % 2% per day at reference temperature
        gamma = 0.05; % Temperature coefficient for self-discharge
        daily_self_discharge = base_self_discharge_rate * exp(gamma * (batt_temperature - T_ref));
        hourly_self_discharge = daily_self_discharge / 24;
        self_discharge_per_timestep = hourly_self_discharge * (Ts / 3600);
        batt_SOC_new = batt_SOC_new * (1 - self_discharge_per_timestep);
    end
end