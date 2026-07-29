function validation = validate_scenario(results, config)
%VALIDATE_SCENARIO Check convergence and voltage constraints.

if nargin < 2, config = project_config(); end
metrics = calculate_pf_metrics(results);
validation = metrics;
validation.voltage_feasible = metrics.success == 1 && ...
    metrics.Vmin >= config.voltageMin && metrics.Vmax <= config.voltageMax;
end

