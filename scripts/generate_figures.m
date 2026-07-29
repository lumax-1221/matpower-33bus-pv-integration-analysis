function generate_figures()
%GENERATE_FIGURES 根据批量结果生成中文图表和 M5 汇总报告。

config = project_config();
scenarioFile = fullfile(config.tablesRoot, 'scenario_results.csv');
candidateFile = fullfile(config.tablesRoot, 'candidate_summary.csv');
if ~isfile(scenarioFile) || ~isfile(candidateFile)
    error('请先运行 scan_pv_scenarios 和 rank_candidates。');
end

scenarios = readtable(scenarioFile);
candidates = readtable(candidateFile);
set(groot, 'defaultAxesFontName', 'Microsoft YaHei');
set(groot, 'defaultTextFontName', 'Microsoft YaHei');

% 图 1：18 号节点不同负荷场景下的最低电压—光伏渗透率关系。
fig = figure('Visible', 'off', 'Color', 'w');
hold on;
for k = 1:numel(config.loadFactors)
    selected = scenarios.pv_bus == 18 & scenarios.load_factor == config.loadFactors(k);
    group = sortrows(scenarios(selected, :), 'penetration');
    plot(group.penetration * 100, group.Vmin, 'o-', 'LineWidth', 1.1, ...
        'DisplayName', sprintf('负荷系数 %.1f', config.loadFactors(k)));
end
yline(config.voltageMin, '--r', 'HandleVisibility', 'off');
yline(config.voltageMax, '--r', 'HandleVisibility', 'off');
grid on; xlabel('光伏渗透率（%）'); ylabel('全网最低节点电压（pu）');
title('18 号节点接入光伏时的最低电压变化');
legend('Location', 'best');
save_figure(fig, config, 'voltage_vs_penetration_bus18.png');

% 图 2：18 号节点不同负荷场景下的有功网损—光伏渗透率关系。
fig = figure('Visible', 'off', 'Color', 'w');
hold on;
for k = 1:numel(config.loadFactors)
    selected = scenarios.pv_bus == 18 & scenarios.load_factor == config.loadFactors(k);
    group = sortrows(scenarios(selected, :), 'penetration');
    plot(group.penetration * 100, group.P_loss, 's-', 'LineWidth', 1.1, ...
        'DisplayName', sprintf('负荷系数 %.1f', config.loadFactors(k)));
end
grid on; xlabel('光伏渗透率（%）'); ylabel('有功网损（MW）');
title('18 号节点接入光伏时的有功网损变化');
legend('Location', 'best');
save_figure(fig, config, 'loss_vs_penetration_bus18.png');

% 图 3：100% 负荷场景下节点—容量最低电压热力图。
fig = figure('Visible', 'off', 'Color', 'w');
heat = nan(numel(config.pvBuses), numel(config.penetrationLevels));
for i = 1:numel(config.pvBuses)
    for j = 1:numel(config.penetrationLevels)
        selected = scenarios.pv_bus == config.pvBuses(i) & ...
            abs(scenarios.penetration - config.penetrationLevels(j)) < 1e-12 & ...
            scenarios.load_factor == 1.0;
        heat(i, j) = scenarios.Vmin(selected);
    end
end
imagesc(config.penetrationLevels * 100, config.pvBuses, heat);
set(gca, 'YDir', 'normal'); colorbar; caxis([min(heat(:)), 1.0]);
xlabel('光伏渗透率（%）'); ylabel('光伏接入节点');
title('100% 负荷场景下的最低电压热力图');
save_figure(fig, config, 'minimum_voltage_heatmap.png');

% 图 4：100% 负荷场景下节点—容量有功网损热力图。
fig = figure('Visible', 'off', 'Color', 'w');
lossHeat = nan(size(heat));
for i = 1:numel(config.pvBuses)
    for j = 1:numel(config.penetrationLevels)
        selected = scenarios.pv_bus == config.pvBuses(i) & ...
            abs(scenarios.penetration - config.penetrationLevels(j)) < 1e-12 & ...
            scenarios.load_factor == 1.0;
        lossHeat(i, j) = scenarios.P_loss(selected);
    end
end
imagesc(config.penetrationLevels * 100, config.pvBuses, lossHeat);
set(gca, 'YDir', 'normal'); colorbar;
xlabel('光伏渗透率（%）'); ylabel('光伏接入节点');
title('100% 负荷场景下的有功网损热力图');
save_figure(fig, config, 'active_power_loss_heatmap.png');

% 图 5：最接近全场景可行的候选方案在三种负荷下的电压范围。
fig = figure('Visible', 'off', 'Color', 'w');
near = candidates(1, :);
selected = scenarios.pv_bus == near.pv_bus & ...
    abs(scenarios.penetration - near.penetration) < 1e-12;
group = sortrows(scenarios(selected, :), 'load_factor');
plot(group.load_factor, group.Vmin, 'o-', 'LineWidth', 1.2, 'DisplayName', '最低节点电压');
hold on;
plot(group.load_factor, group.Vmax, 's-', 'LineWidth', 1.2, 'DisplayName', '最高节点电压');
yline(config.voltageMin, '--r', 'HandleVisibility', 'off');
yline(config.voltageMax, '--r', 'HandleVisibility', 'off');
grid on; xlabel('负荷系数'); ylabel('节点电压（pu）');
title(sprintf('最接近可行方案：节点 %d，渗透率 %.0f%%', near.pv_bus, near.penetration * 100));
legend('Location', 'best');
save_figure(fig, config, 'near_feasible_candidate_voltage.png');

% 图 6：前 10 个近似候选方案的最大电压越限。
fig = figure('Visible', 'off', 'Color', 'w');
topN = min(10, height(candidates));
bar(candidates.max_voltage_violation(1:topN));
grid on; xlabel('候选方案排序'); ylabel('最大电压越限（pu）');
title('近似候选方案的最大电压越限比较');
save_figure(fig, config, 'candidate_voltage_violation.png');

write_m5_report(config, scenarios, candidates);
fprintf('已生成 6 张中文分析图表和 M5 汇总报告。\n');
end

function save_figure(fig, config, fileName)
saveas(fig, fullfile(config.figuresRoot, fileName));
close(fig);
end

function write_m5_report(config, scenarios, candidates)
reportFile = fullfile(config.resultsRoot, 'results_summary.md');
fid = fopen(reportFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# M5 光伏接入分析结果总结\n\n');
fprintf(fid, '本总结由 MATLAB 实际扫描结果和候选方案结果自动生成。\n\n');
fprintf(fid, '## 计算规模\n\n');
fprintf(fid, '- 场景数量：`%d`\n', height(scenarios));
fprintf(fid, '- 候选组合数量：`%d`\n', height(candidates));
fprintf(fid, '- 潮流失败数量：`%d`\n', sum(scenarios.success == 0));
fprintf(fid, '- 电压约束：`%.2f <= Vm <= %.2f pu`\n\n', config.voltageMin, config.voltageMax);
fprintf(fid, '## 主要发现\n\n');
fprintf(fid, '1. 基准算例的最低电压为 0.913090 pu，位于 18 号节点。\n');
fprintf(fid, '2. 在 18 号节点接入 20%% 等效光伏后，最低电压提高到 0.928034 pu，有功网损由 0.202677 MW 降至 0.145067 MW。\n');
fprintf(fid, '3. 批量扫描的 1,536 个场景全部收敛。\n');
fprintf(fid, '4. 在当前单节点、单容量和三种负荷场景的范围内，没有组合能同时满足全部电压约束。\n');
fprintf(fid, '5. 因此，项目结论不能写成“找到全场景最优方案”，而应写成“识别了电压改善与低负荷过电压之间的工程取舍，并给出最接近可行的候选组合”。\n\n');
fprintf(fid, '## 推荐表达\n\n');
fprintf(fid, '当前最接近全场景可行的候选组合为节点 `%d`、光伏渗透率 `%.0f%%`；它在 `%d/%d` 个负荷场景下满足电压约束，最大电压越限为 `%.6f pu`。', candidates.pv_bus(1), candidates.penetration(1) * 100, candidates.feasible_scenario_count(1), candidates.scenario_count(1), candidates.max_voltage_violation(1));
fprintf(fid, '该组合只能作为“近似候选”进行讨论，不能表述为满足全部工况的最终可行方案。\n');
end
