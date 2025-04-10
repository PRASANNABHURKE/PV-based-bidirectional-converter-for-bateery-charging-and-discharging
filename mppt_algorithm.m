%% MPPT Algorithm Function for PV System
% This function implements the Perturb and Observe MPPT algorithm
% for maximum power point tracking in photovoltaic systems

function [duty_cycle_new] = mppt_algorithm(pv_voltage, pv_current, pv_voltage_prev, pv_current_prev, duty_cycle_prev, step_size)
    % Calculate power at current and previous time steps
    pv_power = pv_voltage * pv_current;
    pv_power_prev = pv_voltage_prev * pv_current_prev;
    
    % Calculate changes in power and voltage
    delta_P = pv_power - pv_power_prev;
    delta_V = pv_voltage - pv_voltage_prev;
    
    % Perturb and Observe algorithm
    if delta_P == 0
        % No change in power, maintain duty cycle
        duty_cycle_new = duty_cycle_prev;
    else
        if delta_P > 0
            % Power increased
            if delta_V > 0
                % Voltage increased -> decrease duty cycle
                duty_cycle_new = duty_cycle_prev - step_size;
            else
                % Voltage decreased -> increase duty cycle
                duty_cycle_new = duty_cycle_prev + step_size;
            end
        else
            % Power decreased
            if delta_V > 0
                % Voltage increased -> increase duty cycle
                duty_cycle_new = duty_cycle_prev + step_size;
            else
                % Voltage decreased -> decrease duty cycle
                duty_cycle_new = duty_cycle_prev - step_size;
            end
        end
    end
    
    % Limit duty cycle between 0.1 and 0.9 for stability
    duty_cycle_new = max(0.1, min(0.9, duty_cycle_new));
end