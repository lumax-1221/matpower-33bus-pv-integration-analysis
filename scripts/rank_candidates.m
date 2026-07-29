function candidates = rank_candidates()
%RANK_CANDIDATES 按三种负荷场景共同满足约束的规则筛选候选方案。

config = project_config();
inputFile = fullfile(config.tablesRoot, 'scenario_results.csv');
if ~isfile(inputFile)
    error('请先运行 scan_pv_scenarios。');
end

scenarios = readtable(inputFile);
candidateKeys = unique(scenarios(:, {'pv_bus', 'penetration'}), 'rows');
candidateRows = struct([]);

% 使用逻辑索引逐个检查“节点 + 光伏渗透率”组合。
for k = 1:height(candidateKeys)
    bus = candidateKeys.pv_bus(k);
    penetration = candidateKeys.penetration(k);
    selected = scenarios.pv_bus == bus & abs(scenarios.penetration - penetration) < 1e-12;
    group = scenarios(selected, :);
    feasible = height(group) == numel(config.loadFactors) && ...
        all(group.success == 1) && all(group.Vmin >= config.voltageMin) && ...
        all(group.Vmax <= config.voltageMax);

    row = struct();
    row.pv_bus = bus;
    row.penetration = penetration;
    row.scenario_count = height(group);
    scenarioFeasible = group.success == 1 & group.Vmin >= config.voltageMin & group.Vmax <= config.voltageMax;
    row.feasible_scenario_count = sum(scenarioFeasible);
    row.all_scenarios_feasible = feasible;
    row.mean_P_loss = mean(group.P_loss, 'omitnan');
    row.max_P_loss = max(group.P_loss, [], 'omitnan');
    row.min_Vmin = min(group.Vmin, [], 'omitnan');
    row.max_Vmax = max(group.Vmax, [], 'omitnan');
    row.max_Vdev = max(group.Vdev_max, [], 'omitnan');
    row.mean_P_grid = mean(group.P_grid, 'omitnan');
    row.max_voltage_violation = max([0; config.voltageMin - group.Vmin; group.Vmax - config.voltageMax]);
    candidateRows = add_struct_row(candidateRows, row, k);
end

candidates = struct2table(candidateRows);
candidates = sortrows(candidates, {'all_scenarios_feasible', 'feasible_scenario_count', ...
    'max_voltage_violation', 'mean_P_loss', 'penetration'}, ...
    {'descend', 'descend', 'ascend', 'ascend', 'ascend'});

allFile = fullfile(config.tablesRoot, 'candidate_summary.csv');
feasibleFile = fullfile(config.tablesRoot, 'feasible_candidates.csv');
writetable(candidates, allFile);
writetable(candidates(candidates.all_scenarios_feasible, :), feasibleFile);

feasible = candidates(candidates.all_scenarios_feasible, :);
reportFile = fullfile(config.resultsRoot, 'candidate_screening_analysis.md');
fid = fopen(reportFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# M4 多负荷场景候选方案筛选报告\n\n');
fprintf(fid, '本报告由批量扫描结果自动生成。\n\n');
fprintf(fid, '- 节点与容量组合总数：`%d`\n', height(candidates));
fprintf(fid, '- 三种负荷场景下全部满足电压约束的组合数：`%d`\n', height(feasible));
fprintf(fid, '- 电压约束：`%.2f <= Vm <= %.2f pu`\n\n', config.voltageMin, config.voltageMax);
fprintf(fid, '## 筛选规则\n\n');
fprintf(fid, '同一个光伏接入节点和渗透率组合，必须在 80%%、100%%、120%% 三种负荷场景下均收敛，且所有节点电压均处于约束范围内，才被标记为跨场景可行。');
fprintf(fid, '可行方案再按三场景平均有功网损、最大电压偏差和渗透率从优到次排序。\n\n');
if isempty(feasible)
    fprintf(fid, '## 筛选结果\n\n当前扫描范围内没有满足全部场景约束的方案。项目不放宽电压约束，而是报告最接近可行的候选组合。\n\n');
    topN = min(10, height(candidates));
    fprintf(fid, '| 排名 | 节点 | 渗透率 | 满足约束场景数 | 最大电压越限（pu） | 平均网损（MW） |\n|---:|---:|---:|---:|---:|---:|\n');
    for k = 1:topN
        fprintf(fid, '| %d | %d | %.2f | %d/%d | %.6f | %.6f |\n', k, candidates.pv_bus(k), candidates.penetration(k), candidates.feasible_scenario_count(k), candidates.scenario_count(k), candidates.max_voltage_violation(k), candidates.mean_P_loss(k));
    end
else
    topN = min(10, height(feasible));
    fprintf(fid, '## 前 %d 个候选方案\n\n', topN);
    fprintf(fid, '| 排名 | 节点 | 渗透率 | 平均网损（MW） | 最大电压偏差（pu） | 最低电压（pu） | 最高电压（pu） |\n|---:|---:|---:|---:|---:|---:|---:|\n');
    for k = 1:topN
        fprintf(fid, '| %d | %d | %.2f | %.6f | %.6f | %.6f | %.6f |\n', k, feasible.pv_bus(k), feasible.penetration(k), feasible.mean_P_loss(k), feasible.max_Vdev(k), feasible.min_Vmin(k), feasible.max_Vmax(k));
    end
end
end

function rows = add_struct_row(rows, newRow, index)
if index == 1
    rows = newRow;
else
    rows(index) = newRow; %#ok<AGROW>
end
end
