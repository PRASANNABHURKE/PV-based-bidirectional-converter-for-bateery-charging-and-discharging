%% Bidirectional Converter Model Function for PV System
% This function simulates the bidirectional DC-DC converter behavior
% for both charging (buck) and discharging (boost) modes

function [pv_voltage_new, converter_mode] = bidirectional_converter_model(pv_power, load_power, batt_voltage, batt_SOC, pv_voltage, duty_cycle, SOC_min, SOC_max)
    % Determine converter mode based on power balance and battery SOC
    if pv_power > load_power && batt_SOC < SOC_max
        % Charging mode (PV to Battery) - Buck converter
        converter_mode = 1;
        
        % Calculate new PV voltage based on buck converter equation
        % In buck mode: Vout = D * Vin, so Vin = Vout / D
        pv_voltage_new = batt_voltage / (1 - duty_cycle);
        
    elseif pv_power < load_power && batt_SOC > SOC_min
        % Discharging mode (Battery to Load) - Boost converter
        converter_mode = -1;
        
        % In boost mode, we typically control the duty cycle based on
        % the desired output voltage, but here we're calculating the
        % expected PV voltage based on the current operating point
        pv_voltage_new = batt_voltage * (1 - duty_cycle);
        
    else
        % Idle mode - neither charging nor discharging
        converter_mode = 0;
        
        % Maintain current PV voltage with small perturbation for MPPT
        pv_voltage_new = pv_voltage;
    end
end