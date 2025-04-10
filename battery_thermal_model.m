%% Battery Thermal Model for PV-Based Bidirectional Converter
% This function simulates the thermal behavior of the battery during
% charging and discharging operations

function [batt_temperature_new] = battery_thermal_model(batt_temperature, batt_current, batt_voltage, ambient_temperature, thermal_resistance, thermal_capacitance, Ts)
    % Calculate power dissipation in the battery (I^2*R losses)
    % Using a simplified model where power dissipation is proportional to the square of the current
    internal_resistance = 0.01; % Default internal resistance (Ohm)
    power_dissipation = batt_current^2 * internal_resistance;
    
    % Calculate heat transfer to/from environment
    % Q = (T_batt - T_ambient) / R_thermal
    heat_transfer = (batt_temperature - ambient_temperature) / thermal_resistance;
    
    % Calculate temperature change using thermal capacitance
    % dT/dt = (P_diss - Q) / C_thermal
    temperature_change = (power_dissipation - heat_transfer) / thermal_capacitance;
    
    % Update battery temperature using forward Euler method
    batt_temperature_new = batt_temperature + temperature_change * Ts;
    
    % Apply temperature limits (typical safe operating range for Li-ion batteries)
    batt_temperature_new = max(-20, min(60, batt_temperature_new));
    
    % Optional: Add temperature effects on battery performance
    % - Reduced capacity at low temperatures
    % - Increased self-discharge at high temperatures
    % - Accelerated aging at high temperatures
    
    % Return the updated battery temperature
end