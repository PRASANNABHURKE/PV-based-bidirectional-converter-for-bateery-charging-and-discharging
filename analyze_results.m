%% Analysis and Visualization Script for PV Bidirectional Converter Results
% This script provides additional analysis and visualization of simulation results

function analyze_results(t, pv_voltage, pv_current, pv_power, batt_voltage, batt_current, batt_power, batt_SOC, load_power, converter_mode, duty_cycle, batt_status, protection_flags_array, batt_temperature)
    % Create a new figure for PV characteristics
    figure('Name', 'PV Characteristics', 'NumberTitle', 'off');
    
    % Plot PV I-V curve at different time points
    subplot(2,2,1);
    hold on;
    colors = jet(5);
    time_points = round(linspace(1, length(t), 5));
    for i = 1:length(time_points)
        idx = time_points(i);
        scatter(pv_voltage(idx), pv_current(idx), 50, colors(i,:), 'filled');
    end
    title('PV I-V Operating Points');
    xlabel('Voltage (V)');
    ylabel('Current (A)');
    grid on;
    legend(strcat('t = ', string(t(time_points))), 'Location', 'best');
    
    % Plot PV P-V curve
    subplot(2,2,2);
    hold on;
    for i = 1:length(time_points)
        idx = time_points(i);
        scatter(pv_voltage(idx), pv_power(idx), 50, colors(i,:), 'filled');
    end
    title('PV P-V Operating Points');
    xlabel('Voltage (V)');
    ylabel('Power (W)');
    grid on;
    
    % Plot efficiency over time
    subplot(2,2,3);
    % Calculate approximate converter efficiency
    % In charging mode: efficiency = battery power / PV power
    % In discharging mode: efficiency = load power / battery power
    efficiency = zeros(size(t));
    for i = 1:length(t)
        if converter_mode(i) == 1 && pv_power(i) > 0
            % Charging mode
            efficiency(i) = abs(batt_power(i)) / pv_power(i) * 100;
        elseif converter_mode(i) == -1 && batt_power(i) ~= 0
            % Discharging mode
            efficiency(i) = load_power(i) / abs(batt_power(i)) * 100;
        else
            efficiency(i) = NaN; % Not applicable in idle mode
        end
    end
    plot(t, efficiency, 'LineWidth', 1.5);
    title('Estimated Converter Efficiency');
    xlabel('Time (s)');
    ylabel('Efficiency (%)');
    ylim([0, 100]);
    grid on;
    
    % Plot energy balance
    subplot(2,2,4);
    % Calculate cumulative energy
    dt = t(2) - t(1); % Time step
    pv_energy = cumsum(pv_power * dt);
    batt_energy = cumsum(batt_power * dt);
    load_energy = cumsum(load_power * dt);
    plot(t, pv_energy, 'g-', t, abs(batt_energy), 'b-', t, load_energy, 'r-', 'LineWidth', 1.5);
    title('Cumulative Energy');
    xlabel('Time (s)');
    ylabel('Energy (J)');
    legend('PV Energy', 'Battery Energy', 'Load Energy', 'Location', 'northwest');
    grid on;
    
    % Create a new figure for system performance
    figure('Name', 'System Performance', 'NumberTitle', 'off');
    
    % Plot battery SOC vs. converter mode
    subplot(2,2,1);
    yyaxis left;
    plot(t, batt_SOC, 'b-', 'LineWidth', 1.5);
    ylabel('Battery SOC (%)');
    ylim([0, 100]);
    
    yyaxis right;
    plot(t, converter_mode, 'r-', 'LineWidth', 1.5);
    ylabel('Converter Mode');
    ylim([-1.5, 1.5]);
    
    title('Battery SOC and Converter Mode');
    xlabel('Time (s)');
    grid on;
    
    % Plot power distribution
    subplot(2,2,2);
    area(t, [pv_power; -batt_power; load_power]');
    title('Power Distribution');
    xlabel('Time (s)');
    ylabel('Power (W)');
    legend('PV Power', 'Battery Power', 'Load Power', 'Location', 'best');
    grid on;
    
    % Create a new figure for battery thermal analysis if temperature data is available
    if exist('batt_temperature', 'var')
        figure('Name', 'Battery Thermal Analysis', 'NumberTitle', 'off');
        
        % Plot battery temperature over time
        subplot(2,1,1);
        plot(t, batt_temperature, 'r-', 'LineWidth', 1.5);
        title('Battery Temperature Over Time');
        xlabel('Time (s)');
        ylabel('Temperature (°C)');
        grid on;
        
        % Plot temperature vs. battery current to show heating effect
        subplot(2,1,2);
        scatter(batt_current, batt_temperature, 25, t, 'filled');
        title('Temperature vs. Current (Color = Time)');
        xlabel('Battery Current (A)');
        ylabel('Temperature (°C)');
        colorbar('Title', 'Time (s)');
        grid on;
    end
    
    % Create a new figure for BMS analysis if BMS data is available
    if exist('batt_status', 'var') && exist('protection_flags_array', 'var')
        figure('Name', 'Battery Management System Analysis', 'NumberTitle', 'off');
        
        % Plot BMS status over time
        subplot(2,1,1);
        % Create a numeric representation of battery status for plotting
        batt_status_numeric = zeros(1, length(t));
        for i = 1:length(t)
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
        plot(t, batt_status_numeric, 'LineWidth', 1.5);
        title('BMS Status Over Time');
        xlabel('Time (s)');
        yticks(0:6);
        yticklabels({'Normal', 'Overvoltage', 'Undervoltage', 'Charge Limit', 'Discharge Limit', 'Temp Limit', 'SOC Limit'});
        grid on;
        
        % Plot protection flags activation
        subplot(2,1,2);
        hold on;
        
        % Extract protection flags data
        overvoltage_flags = zeros(1, length(t));
        undervoltage_flags = zeros(1, length(t));
        overcurrent_charge_flags = zeros(1, length(t));
        overcurrent_discharge_flags = zeros(1, length(t));
        high_soc_flags = zeros(1, length(t));
        low_soc_flags = zeros(1, length(t));
        
        for i = 1:length(t)
            if isfield(protection_flags_array(i), 'overvoltage')
                overvoltage_flags(i) = protection_flags_array(i).overvoltage;
                undervoltage_flags(i) = protection_flags_array(i).undervoltage;
                overcurrent_charge_flags(i) = protection_flags_array(i).overcurrent_charge;
                overcurrent_discharge_flags(i) = protection_flags_array(i).overcurrent_discharge;
                high_soc_flags(i) = protection_flags_array(i).high_soc;
                low_soc_flags(i) = protection_flags_array(i).low_soc;
            end
        end
        
        % Plot each protection flag with offset for visibility
        plot(t, overvoltage_flags * 6, 'LineWidth', 1.5);
        plot(t, undervoltage_flags * 5, 'LineWidth', 1.5);
        plot(t, overcurrent_charge_flags * 4, 'LineWidth', 1.5);
        plot(t, overcurrent_discharge_flags * 3, 'LineWidth', 1.5);
        plot(t, high_soc_flags * 2, 'LineWidth', 1.5);
        plot(t, low_soc_flags * 1, 'LineWidth', 1.5);
        
        title('Protection Flags Activation');
        xlabel('Time (s)');
        yticks(1:6);
        yticklabels({'Low SOC', 'High SOC', 'Overcurrent Discharge', 'Overcurrent Charge', 'Undervoltage', 'Overvoltage'});
        grid on;
        legend('Overvoltage', 'Undervoltage', 'Overcurrent Charge', 'Overcurrent Discharge', 'High SOC', 'Low SOC', 'Location', 'best');
    end
    
    % Plot duty cycle vs. converter mode
    subplot(2,2,3);
    yyaxis left;
    plot(t, duty_cycle, 'b-', 'LineWidth', 1.5);
    ylabel('Duty Cycle');
    ylim([0, 1]);
    
    yyaxis right;
    plot(t, converter_mode, 'r-', 'LineWidth', 1.5);
    ylabel('Converter Mode');
    ylim([-1.5, 1.5]);
    
    title('Duty Cycle and Converter Mode');
    xlabel('Time (s)');
    grid on;
    
    % Plot battery current vs. SOC
    subplot(2,2,4);
    scatter(batt_SOC, batt_current, 10, t, 'filled');
    title('Battery Current vs. SOC');
    xlabel('Battery SOC (%)');
    ylabel('Battery Current (A)');
    colorbar('Title', 'Time (s)');
    grid on;
    
    % Create a new figure for detailed battery analysis
    figure('Name', 'Battery Analysis', 'NumberTitle', 'off');
    
    % Plot battery voltage vs. SOC
    subplot(2,1,1);
    scatter(batt_SOC, batt_voltage, 10, t, 'filled');
    title('Battery Voltage vs. SOC');
    xlabel('Battery SOC (%)');
    ylabel('Battery Voltage (V)');
    colorbar('Title', 'Time (s)');
    grid on;
    
    % Plot battery power vs. SOC
    subplot(2,1,2);
    scatter(batt_SOC, batt_power, 10, t, 'filled');
    title('Battery Power vs. SOC');
    xlabel('Battery SOC (%)');
    ylabel('Battery Power (W)');
    colorbar('Title', 'Time (s)');
    grid on;
end