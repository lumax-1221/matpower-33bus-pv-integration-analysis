function metrics = calculate_pf_metrics(results)
%CALCULATE_PF_METRICS Extract voltage, loss, and supply metrics.

define_constants;
metrics = struct();
metrics.success = results.success;
if ~results.success
    metrics.Vmin = NaN; metrics.Vmin_bus = NaN;
    metrics.Vmax = NaN; metrics.Vmax_bus = NaN;
    metrics.Vdev_max = NaN; metrics.P_loss = NaN; metrics.P_grid = NaN;
    return;
end

vm = results.bus(:, VM);
[metrics.Vmin, iMin] = min(vm);
[metrics.Vmax, iMax] = max(vm);
metrics.Vmin_bus = results.bus(iMin, BUS_I);
metrics.Vmax_bus = results.bus(iMax, BUS_I);
metrics.Vdev_max = max(abs(vm - 1.0));
metrics.P_loss = sum(results.branch(:, PF) + results.branch(:, PT));
metrics.P_grid = sum(results.gen(:, PG));
end

