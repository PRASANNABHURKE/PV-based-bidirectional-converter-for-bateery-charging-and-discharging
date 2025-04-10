%% Analysis and Visualization Script for PV Bidirectional Converter Results
% This script provides additional analysis and visualization of simulation results

function analyze_results(t, pv_voltage, pv_current, pv_power, batt_voltage, batt_current, batt_power, batt_SOC, load_power, converter_mode, duty_cycle)
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