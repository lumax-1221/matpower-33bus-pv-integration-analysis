function result = run_baseline()
%RUN_BASELINE 运行原始 case33bw 潮流并提取基准指标。

config = project_config();
define_constants;
mpc = loadcase(config.caseName);
mpopt = mpoption('verbose', 0, 'out.all', 0);
result = runpf(mpc, mpopt);

metrics = calculate_pf_metrics(result);
fprintf('基准潮流是否收敛：%d\n', result.success);
fprintf('最低节点电压：%.6f pu，节点：%d\n', metrics.Vmin, metrics.Vmin_bus);
fprintf('最高节点电压：%.6f pu，节点：%d\n', metrics.Vmax, metrics.Vmax_bus);
fprintf('有功网损：%.6f MW\n', metrics.P_loss);

if ~exist(config.tablesRoot, 'dir'), mkdir(config.tablesRoot); end
writetable(struct2table(metrics), fullfile(config.tablesRoot, 'baseline_metrics.csv'));

busTable = table(result.bus(:, BUS_I), result.bus(:, VM), result.bus(:, VA), ...
    'VariableNames', {'bus', 'voltage_pu', 'angle_deg'});
writetable(busTable, fullfile(config.tablesRoot, 'baseline_bus_voltages.csv'));

if ~exist(config.figuresRoot, 'dir'), mkdir(config.figuresRoot); end
fig = figure('Visible', 'off', 'Color', 'w');
set(groot, 'defaultAxesFontName', 'Microsoft YaHei');
set(groot, 'defaultTextFontName', 'Microsoft YaHei');
plot(busTable.bus, busTable.voltage_pu, 'o-', 'LineWidth', 1.2);
hold on;
yline(config.voltageMin, '--r');
yline(config.voltageMax, '--r');
grid on;
xlabel('节点编号');
ylabel('节点电压幅值（pu）');
title('MATPOWER case33bw 基准节点电压分布');
legend('节点电压', '电压约束线', 'Location', 'best');
saveas(fig, fullfile(config.figuresRoot, 'baseline_voltage_profile.png'));
close(fig);

reportFile = fullfile(config.resultsRoot, 'baseline_analysis.md');
fid = fopen(reportFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# M1 基准潮流分析报告\n\n');
fprintf(fid, '本报告由当前 MATLAB/MATPOWER 实际运行结果自动生成。\n\n');
fprintf(fid, '- 基准潮流是否收敛：`%d`\n', result.success);
fprintf(fid, '- 最低节点电压：`%.6f pu`，节点：`%d`\n', metrics.Vmin, metrics.Vmin_bus);
fprintf(fid, '- 最高节点电压：`%.6f pu`，节点：`%d`\n', metrics.Vmax, metrics.Vmax_bus);
fprintf(fid, '- 最大电压偏差：`%.6f pu`\n', metrics.Vdev_max);
fprintf(fid, '- 有功网损：`%.6f MW`\n', metrics.P_loss);
fprintf(fid, '- 上级电网供电功率：`%.6f MW`\n\n', metrics.P_grid);
fprintf(fid, '## 工程解释\n\n');
fprintf(fid, '最低电压出现在 %d 号节点，说明该节点附近是基准工况下的弱电压区域。', metrics.Vmin_bus);
fprintf(fid, '后续光伏场景将以本基准结果为参照，同时检查电压改善效果和潜在过电压风险。\n');
end
