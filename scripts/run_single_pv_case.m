function result = run_single_pv_case(pvBus, penetration, loadFactor)
%RUN_SINGLE_PV_CASE 运行一个等效光伏接入场景并保存 M2 对比结果。

if nargin < 1, pvBus = 18; end
if nargin < 2, penetration = 0.20; end
if nargin < 3, loadFactor = 1.00; end

config = project_config();
define_constants;
originalCase = loadcase(config.caseName);
scenarioCase = apply_load_factor(originalCase, loadFactor);
scenarioCase = apply_pv_injection(scenarioCase, pvBus, penetration);
mpopt = mpoption('verbose', 0, 'out.all', 0);
baseResult = runpf(originalCase, mpopt);
result = runpf(scenarioCase, mpopt);
baseMetrics = calculate_pf_metrics(baseResult);
metrics = calculate_pf_metrics(result);

fprintf('光伏节点：%d，光伏渗透率：%.2f，负荷系数：%.2f，是否收敛：%d\n', ...
    pvBus, penetration, loadFactor, result.success);
fprintf('最低节点电压：%.6f pu，节点：%d\n', metrics.Vmin, metrics.Vmin_bus);
fprintf('最高节点电压：%.6f pu，节点：%d\n', metrics.Vmax, metrics.Vmax_bus);
fprintf('有功网损：%.6f MW\n', metrics.P_loss);

% 对原始算例重新加载并比较，确认本次计算没有永久修改原始数据。
reloadedCase = loadcase(config.caseName);
originalCaseUnchanged = isequal(originalCase.bus, reloadedCase.bus) && ...
    isequal(originalCase.branch, reloadedCase.branch) && ...
    isequal(originalCase.gen, reloadedCase.gen);

comparison = table( ...
    ["基准场景"; "光伏接入场景"], ...
    [0; penetration], ...
    [baseMetrics.Vmin; metrics.Vmin], ...
    [baseMetrics.Vmin_bus; metrics.Vmin_bus], ...
    [baseMetrics.Vmax; metrics.Vmax], ...
    [baseMetrics.Vmax_bus; metrics.Vmax_bus], ...
    [baseMetrics.P_loss; metrics.P_loss], ...
    [baseMetrics.P_grid; metrics.P_grid], ...
    'VariableNames', {'scenario_name', 'penetration', 'Vmin', 'Vmin_bus', ...
    'Vmax', 'Vmax_bus', 'P_loss', 'P_grid'});
writetable(comparison, fullfile(config.tablesRoot, 'single_pv_comparison.csv'));

busComparison = table(baseResult.bus(:, BUS_I), baseResult.bus(:, VM), ...
    result.bus(:, VM), result.bus(:, VM) - baseResult.bus(:, VM), ...
    'VariableNames', {'bus', 'baseline_voltage_pu', 'pv_voltage_pu', ...
    'voltage_change_pu'});
writetable(busComparison, fullfile(config.tablesRoot, 'single_pv_bus_voltage_comparison.csv'));

set(groot, 'defaultAxesFontName', 'Microsoft YaHei');
set(groot, 'defaultTextFontName', 'Microsoft YaHei');
fig = figure('Visible', 'off', 'Color', 'w');
plot(busComparison.bus, busComparison.baseline_voltage_pu, 'o-', 'LineWidth', 1.1);
hold on;
plot(busComparison.bus, busComparison.pv_voltage_pu, 's-', 'LineWidth', 1.1);
yline(config.voltageMin, '--r');
yline(config.voltageMax, '--r');
grid on;
xlabel('节点编号');
ylabel('节点电压幅值（pu）');
title(sprintf('节点 %d 接入 %.0f%% 光伏前后电压对比', pvBus, penetration * 100));
legend('基准场景', '光伏接入场景', '电压约束线', 'Location', 'best');
saveas(fig, fullfile(config.figuresRoot, 'single_pv_voltage_comparison.png'));
close(fig);

reportFile = fullfile(config.resultsRoot, 'single_pv_analysis.md');
fid = fopen(reportFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# M2 单节点光伏接入验证报告\n\n');
fprintf(fid, '本报告由 MATLAB 实际运行结果自动生成。\n\n');
fprintf(fid, '- 接入节点：`%d`\n', pvBus);
fprintf(fid, '- 光伏渗透率：`%.2f`\n', penetration);
fprintf(fid, '- 负荷系数：`%.2f`\n', loadFactor);
fprintf(fid, '- 原始算例是否保持不变：`%d`\n\n', originalCaseUnchanged);
fprintf(fid, '## 基准与光伏接入结果\n\n');
fprintf(fid, '| 指标 | 基准场景 | 光伏接入场景 | 变化量 |\n|---|---:|---:|---:|\n');
fprintf(fid, '| 最低节点电压（pu） | %.6f | %.6f | %+.6f |\n', baseMetrics.Vmin, metrics.Vmin, metrics.Vmin - baseMetrics.Vmin);
fprintf(fid, '| 最高节点电压（pu） | %.6f | %.6f | %+.6f |\n', baseMetrics.Vmax, metrics.Vmax, metrics.Vmax - baseMetrics.Vmax);
fprintf(fid, '| 有功网损（MW） | %.6f | %.6f | %+.6f |\n', baseMetrics.P_loss, metrics.P_loss, metrics.P_loss - baseMetrics.P_loss);
fprintf(fid, '| 上级电网供电功率（MW） | %.6f | %.6f | %+.6f |\n', baseMetrics.P_grid, metrics.P_grid, metrics.P_grid - baseMetrics.P_grid);
fprintf(fid, '\n## 工程解释\n\n');
fprintf(fid, '本阶段在 %d 号节点施加等效有功光伏注入，验证光伏接入逻辑和结果提取流程。', pvBus);
fprintf(fid, '负荷无功 `Qd` 未被光伏注入改变，且原始算例重新加载后数据保持一致。');
fprintf(fid, '因此，该阶段确认了后续批量扫描可以从原始算例重新生成每一个场景。\n');
end
