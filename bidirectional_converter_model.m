%% Bidirectional Converter Model Function for PV System
% This function simulates the bidirectional DC-DC converter behavior
% for both charging (buck) and discharging (boost) modes
% Supports full input voltage range (25V-50V) and output voltage range (24V-48V)

function [pv_voltage_new, converter_mode] = bidirectional_converter_model(pv_power, load_power, batt_voltage, batt_SOC, pv_voltage, duty_cycle, SOC_min, SOC_max)
    % Input voltage range: 25V-50V
    % Output voltage range: 24V-48V
    
    % Define voltage limits for safety
    MIN_INPUT_VOLTAGE = 25;  % Minimum input voltage (V)
    MAX_INPUT_VOLTAGE = 50;  % Maximum input voltage (V)
    MIN_OUTPUT_VOLTAGE = 24; % Minimum output voltage (V)
    MAX_OUTPUT_VOLTAGE = 48; % Maximum output voltage (V)
    
    % Determine converter mode based on power balance and battery SOC
    if pv_power > load_power && batt_SOC < SOC_max
        % Charging mode (PV to Battery) - Buck converter
        converter_mode = 1;
        
        % Calculate new PV voltage based on buck converter equation
        % In buck mode: Vout = D * Vin, so Vin = Vout / D
        pv_voltage_new = batt_voltage / (1 - duty_cycle);
        
        % Ensure PV voltage is within input range
        pv_voltage_new = max(MIN_INPUT_VOLTAGE, min(MAX_INPUT_VOLTAGE, pv_voltage_new));
        
        % Adjust duty cycle if necessary to maintain battery voltage within limits
        if batt_voltage > MAX_OUTPUT_VOLTAGE
            % Limit output voltage by adjusting duty cycle
            duty_cycle_adjusted = 1 - (pv_voltage_new / MAX_OUTPUT_VOLTAGE);
            pv_voltage_new = MAX_OUTPUT_VOLTAGE / (1 - duty_cycle_adjusted);
        end
        
    elseif pv_power < load_power && batt_SOC > SOC_min
        % Discharging mode (Battery to Load) - Boost converter
        converter_mode = -1;
        
        % In boost mode: Vout = Vin / (1-D), so Vin = Vout * (1-D)
        pv_voltage_new = batt_voltage * (1 - duty_cycle);
        
        % Ensure PV voltage is within input range
        pv_voltage_new = max(MIN_INPUT_VOLTAGE, min(MAX_INPUT_VOLTAGE, pv_voltage_new));
        
        % Check if battery voltage is within output range
        if batt_voltage < MIN_OUTPUT_VOLTAGE || batt_voltage > MAX_OUTPUT_VOLTAGE
            % Adjust duty cycle to keep output voltage within range
            if batt_voltage < MIN_OUTPUT_VOLTAGE
                % Increase duty cycle to boost voltage
                duty_cycle_adjusted = 1 - (pv_voltage_new / MIN_OUTPUT_VOLTAGE);
                pv_voltage_new = MIN_OUTPUT_VOLTAGE * (1 - duty_cycle_adjusted);
            elseif batt_voltage > MAX_OUTPUT_VOLTAGE
                % Decrease duty cycle to reduce voltage
                duty_cycle_adjusted = 1 - (pv_voltage_new / MAX_OUTPUT_VOLTAGE);
                pv_voltage_new = MAX_OUTPUT_VOLTAGE * (1 - duty_cycle_adjusted);
            end
        end
        
    else
        % Idle mode - neither charging nor discharging
        converter_mode = 0;
        
        % Maintain current PV voltage with small perturbation for MPPT
        pv_voltage_new = pv_voltage;
        
        % Ensure PV voltage is within input range
        pv_voltage_new = max(MIN_INPUT_VOLTAGE, min(MAX_INPUT_VOLTAGE, pv_voltage_new));
    end
end