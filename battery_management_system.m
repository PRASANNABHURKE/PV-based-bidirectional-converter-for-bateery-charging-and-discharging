%% Battery Management System (BMS) for PV-Based Bidirectional Converter
% This function implements a Battery Management System that monitors and protects
% the battery during charging and discharging operations.

function [batt_current_limited, batt_status, protection_flags] = battery_management_system(batt_voltage, batt_current, batt_SOC, batt_temperature, batt_nominal_voltage, batt_capacity)
    % Initialize output variables
    batt_current_limited = batt_current;
    batt_status = 'Normal';
    
    % Initialize protection flags
    protection_flags = struct();
    protection_flags.overvoltage = false;
    protection_flags.undervoltage = false;
    protection_flags.overcurrent_charge = false;
    protection_flags.overcurrent_discharge = false;
    protection_flags.overtemperature = false;
    protection_flags.undertemperature = false;
    protection_flags.high_soc = false;
    protection_flags.low_soc = false;
    protection_flags.reverse_polarity = false;
    
    % Default protection thresholds (can be adjusted based on battery chemistry)
    % Voltage protection thresholds
    if batt_nominal_voltage == 24
        % 24V system
        overvoltage_threshold = 28.8;      % Maximum charging voltage for 24V system
        undervoltage_threshold = 21.0;     % Minimum discharge voltage for 24V system
    elseif batt_nominal_voltage == 48
        % 48V system
        overvoltage_threshold = 57.6;      % Maximum charging voltage for 48V system
        undervoltage_threshold = 42.0;     % Minimum discharge voltage for 48V system
    else
        % Default case - scale based on nominal voltage
        overvoltage_threshold = batt_nominal_voltage * 1.2;  % 120% of nominal voltage
        undervoltage_threshold = batt_nominal_voltage * 0.875; % 87.5% of nominal voltage
    end
    
    % Current protection thresholds
    max_charge_current = batt_capacity * 0.5;    % 0.5C charge rate (50% of capacity)
    max_discharge_current = batt_capacity * 1.0; % 1C discharge rate (100% of capacity)
    
    % Temperature protection thresholds (°C)
    max_temperature = 45;  % Maximum safe operating temperature
    min_temperature = 0;   % Minimum safe operating temperature
    
    % SOC protection thresholds (%)
    max_soc = 95;  % Maximum SOC to prevent overcharging
    min_soc = 10;  % Minimum SOC to prevent deep discharge
    
    % Check for protection conditions
    
    % Voltage protection
    if batt_voltage >= overvoltage_threshold
        protection_flags.overvoltage = true;
        if batt_current < 0  % Only limit charging current
            batt_current_limited = 0;  % Stop charging
            batt_status = 'Overvoltage Protection';
        end
    end
    
    if batt_voltage <= undervoltage_threshold
        protection_flags.undervoltage = true;
        if batt_current > 0  % Only limit discharging current
            batt_current_limited = 0;  % Stop discharging
            batt_status = 'Undervoltage Protection';
        end
    end
    
    % Current protection
    if batt_current < -max_charge_current  % Charging current (negative)
        protection_flags.overcurrent_charge = true;
        batt_current_limited = -max_charge_current;  % Limit charging current
        batt_status = 'Charge Current Limiting';
    end
    
    if batt_current > max_discharge_current  % Discharging current (positive)
        protection_flags.overcurrent_discharge = true;
        batt_current_limited = max_discharge_current;  % Limit discharging current
        batt_status = 'Discharge Current Limiting';
    end
    
    % Temperature protection (if temperature data is available)
    if exist('batt_temperature', 'var') && ~isempty(batt_temperature)
        if batt_temperature >= max_temperature
            protection_flags.overtemperature = true;
            batt_current_limited = 0;  % Stop all current flow
            batt_status = 'Overtemperature Protection';
        end
        
        if batt_temperature <= min_temperature
            protection_flags.undertemperature = true;
            if batt_current < 0  % Only limit charging in cold conditions
                batt_current_limited = 0;  % Stop charging
                batt_status = 'Undertemperature Protection';
            end
        end
    end
    
    % Reverse polarity protection
    % Detect reverse polarity by checking if battery voltage is negative
    % or if there's an abnormal current flow pattern
    % In a real system, this would be implemented with hardware (diodes, MOSFETs, etc.)
    if batt_voltage < 0 || (batt_voltage > 0 && batt_current < -1.5 * max_charge_current)
        protection_flags.reverse_polarity = true;
        batt_current_limited = 0;  % Stop all current flow
        batt_status = 'Reverse Polarity Protection';
        
        % In hardware implementation, this would trigger:
        % 1. Disconnect battery using relay or solid-state switch
        % 2. Activate alarm or indicator
        % 3. Log the event for diagnostics
    end
    
    % SOC protection
    if batt_SOC >= max_soc
        protection_flags.high_soc = true;
        if batt_current < 0  % Only limit charging current
            % Gradually reduce charging current as SOC approaches 100%
            soc_factor = (100 - batt_SOC) / (100 - max_soc);
            reduced_current = batt_current * soc_factor;
            batt_current_limited = max(reduced_current, -0.05 * max_charge_current);  % Allow trickle charging
            batt_status = 'High SOC Current Limiting';
        end
    end
    
    if batt_SOC <= min_soc
        protection_flags.low_soc = true;
        if batt_current > 0  % Only limit discharging current
            % Gradually reduce discharge current as SOC approaches 0%
            soc_factor = batt_SOC / min_soc;
            reduced_current = batt_current * soc_factor;
            batt_current_limited = min(reduced_current, 0.2 * max_discharge_current);  % Allow minimal discharge
            batt_status = 'Low SOC Current Limiting';
        end
    end
    
    % Cell balancing logic could be added here for multi-cell batteries
    
    % Battery health estimation could be added here
    
    % Return the limited current and status
end