function export_results()
%EXPORT_RESULTS 导出当前结果文件清单，不覆盖正式结果总结。

config = project_config();
summaryFile = fullfile(config.resultsRoot, 'export_manifest.md');
fid = fopen(summaryFile, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# 项目结果文件清单\n\n');
fprintf(fid, '生成时间：%s\n\n', datestr(now, 31));
fprintf(fid, '本文件由当前项目输出自动生成。正式分析总结位于 `results_summary.md`。\n\n');
fprintf(fid, '只有来自实际 MATLAB/MATPOWER 运行的数值才允许写入正式报告。\n');
end
