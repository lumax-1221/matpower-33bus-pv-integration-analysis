function scenarios = scan_pv_scenarios()
%SCAN_PV_SCENARIOS 批量扫描节点、光伏渗透率和负荷系数。

config = project_config();
define_constants;
rows = struct([]);
rowIndex = 0;
baseCase = loadcase(config.caseName);
basePload = sum(baseCase.bus(:, PD));

for loadFactor = config.loadFactors
    for penetration = config.penetrationLevels
        for pvBus = config.pvBuses
            mpc = baseCase;
            mpc = apply_load_factor(mpc, loadFactor);
            mpc = apply_pv_injection(mpc, pvBus, penetration, basePload);
            result = runpf(mpc, mpoption('verbose', 0, 'out.all', 0));
            metrics = calculate_pf_metrics(result);
            rowIndex = rowIndex + 1;
            newRow = scenario_row(pvBus, penetration, loadFactor, metrics);
            if rowIndex == 1
                rows = newRow;
            else
                rows(rowIndex) = newRow; %#ok<AGROW>
            end
        end
    end
end

scenarios = struct2table(rows);
writetable(scenarios, fullfile(config.tablesRoot, 'scenario_results.csv'));

reportFile = fullfile(config.resultsRoot, 'scan_analysis.md');
fid = fopen(reportFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# M3 节点与容量批量扫描报告\n\n');
fprintf(fid, '本报告由 MATLAB 实际批量运行结果自动生成。\n\n');
fprintf(fid, '- 场景总数：`%d`\n', height(scenarios));
fprintf(fid, '- 扫描节点：`%d`–`%d`，共 `%d` 个\n', min(scenarios.pv_bus), max(scenarios.pv_bus), numel(unique(scenarios.pv_bus)));
fprintf(fid, '- 光伏渗透率：`%.2f`–`%.2f`，共 `%d` 个\n', min(scenarios.penetration), max(scenarios.penetration), numel(unique(scenarios.penetration)));
fprintf(fid, '- 负荷系数：`%.2f、%.2f、%.2f`\n', config.loadFactors(1), config.loadFactors(2), config.loadFactors(3));
fprintf(fid, '- 潮流失败场景：`%d`\n', sum(scenarios.success == 0));
fprintf(fid, '- 所有场景是否收敛：`%d`\n\n', all(scenarios.success == 1));
fprintf(fid, '## 实际结果范围\n\n');
fprintf(fid, '| 指标 | 最小值 | 最大值 |\n|---|---:|---:|\n');
fprintf(fid, '| 最低节点电压（pu） | %.6f | %.6f |\n', min(scenarios.Vmin), max(scenarios.Vmin));
fprintf(fid, '| 最高节点电压（pu） | %.6f | %.6f |\n', min(scenarios.Vmax), max(scenarios.Vmax));
fprintf(fid, '| 有功网损（MW） | %.6f | %.6f |\n', min(scenarios.P_loss), max(scenarios.P_loss));
fprintf(fid, '| 最大电压偏差（pu） | %.6f | %.6f |\n\n', min(scenarios.Vdev_max), max(scenarios.Vdev_max));
fprintf(fid, '## 扫描逻辑说明\n\n');
fprintf(fid, '每个场景都从未修改的原始 `case33bw` 重新生成，先按负荷系数缩放 `Pd` 和 `Qd`，再施加按基准总有功负荷定义的等效光伏注入。');
fprintf(fid, '因此，在不同负荷场景下，同一节点和同一渗透率对应的光伏容量保持一致。\n');
fprintf(fid, '下一阶段将按照三种负荷场景同时满足 0.95–1.05 pu 电压约束的规则筛选候选方案。\n');

fprintf('已保存 %d 个光伏场景。\n', height(scenarios));
end

function row = scenario_row(pvBus, penetration, loadFactor, metrics)
row = metrics;
row.pv_bus = pvBus;
row.penetration = penetration;
row.load_factor = loadFactor;
end
