%% Battery Model Function for PV System
% This function simulates battery behavior including voltage, current, and SOC calculations

function [batt_voltage_new, batt_SOC_new] = battery_model(batt_voltage, batt_current, batt_SOC, internal_resistance, capacity, Ts)
    % Calculate new battery voltage considering internal resistance
    % V_batt = V_oc - I_batt * R_internal
    batt_voltage_new = batt_voltage - batt_current * internal_resistance;
    
    % Update State of Charge using Coulomb counting method
    % SOC_new = SOC_old - (I_batt * Ts / (Capacity * 3600)) * 100
    % Note: Negative current means charging, positive means discharging
    batt_SOC_new = batt_SOC - (batt_current * Ts / (capacity * 3600)) * 100;
    
    % Limit SOC between 0% and 100%
    batt_SOC_new = max(0, min(100, batt_SOC_new));
    
    % Optional: Implement more sophisticated battery model if needed
    % For example, consider temperature effects, aging, etc.
end