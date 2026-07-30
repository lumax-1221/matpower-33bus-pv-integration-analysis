# 基于 MATPOWER 的 33 节点配电网光伏接入与选址定容分析

基于 MATLAB/MATPOWER `case33bw` 的稳态交流潮流分析项目，研究等效光伏有功注入在不同节点、容量和负荷水平下对配电网电压分布、有功损耗及上级电网供电功率的影响，并筛选满足电压约束的候选方案。

> 本项目是个人仿真分析项目，不代表真实电网工程设计，也不使用实际电网数据。

## 项目目标

1. 原始配电网的节点电压和有功损耗如何？
2. 光伏接入位置和容量变化会如何影响电压与网损？
3. 低负荷过电压与高负荷欠电压之间如何取舍？
4. 在多个负荷场景下，哪些节点和容量组合更合理？

## 模型边界与假设

- 网络：MATPOWER 自带 `case33bw`，静态、平衡、稳态交流潮流。
- 光伏：用功率因数为 1 的等效有功注入表示，不提供无功支撑。
- 注入：`Pd_after = Pd_before - Ppv`，`Qd_after = Qd_before`。
- 容量：`Ppv = penetration * Pload_base`。
- 光伏渗透率：默认 `0.05:0.05:0.80`，基准场景单独记录 `0`。
- 负荷场景：`0.8、1.0、1.2`，同时缩放 `Pd` 和 `Qd`。
- 电压约束：`0.95 <= Vm <= 1.05`。

不包含储能、时序光伏出力、无功电压控制、短路计算、保护、OPF、动态模型和实际工程数据。

## 软件环境

- MATLAB R2016a 或以上
- MATPOWER 8.1
- MATLAB Editor 或 VS Code

MATPOWER 应安装在项目目录之外，例如：

```text
D:\Tools\matpower8.1
```

## 运行顺序

在 MATLAB 中将当前目录切换到仓库根目录后运行：

```matlab
addpath(genpath(pwd));
startup_project;
run_baseline;
run_single_pv_case;
scan_pv_scenarios;
rank_candidates;
generate_figures;
export_results;
```

其中 `results_summary.md` 是 M5 正式结果总结，`export_results` 只生成不会覆盖正式总结的文件清单。

M0 阶段先在 MATPOWER 目录中确认：

```matlab
install_matpower
test_matpower
results = runpf('case33bw');
```

## 文件命名与目录结构

```text
config/       可调整参数
scripts/      主流程脚本
functions/    可复用计算函数
results/      图表、表格和汇总结果
references/   算例来源与版本记录
```

文件名使用英文，但采用能够表达职责的命名方式：

- `run_baseline.m`：运行基准潮流；
- `run_single_pv_case.m`：运行单节点、单容量光伏案例；
- `scan_pv_scenarios.m`：批量扫描节点、容量和负荷场景；
- `rank_candidates.m`：筛选并排序可行方案；
- `generate_figures.m`：生成中文图表；
- `export_results.m`：导出结果和中文摘要。

## 图表和文字规范

本项目面向中文读者。所有 README、阶段报告、状态文件、图表标题、坐标轴、图例和说明均使用中文。CSV 字段保留英文，便于 MATLAB 脚本稳定处理；字段含义必须在中文报告中解释。

当前已生成的基准表字段含义如下：

| 英文字段 | 中文含义 | 单位 |
|---|---|---|
| `bus` | 节点编号 | — |
| `voltage_pu` | 节点电压幅值 | pu |
| `angle_deg` | 节点电压相角 | 度 |
| `Vmin`、`Vmax` | 最低/最高节点电压 | pu |
| `P_loss` | 有功网损 | MW |
| `P_grid` | 上级电网供电功率 | MW |

## 结果真实性要求

所有图表、CSV、MAT 文件和 README 数字必须来自实际运行结果。潮流失败场景不得删除，推荐方案必须能够追溯并独立复算。

## 当前状态

详见 [`PROJECT_STATUS.md`](PROJECT_STATUS.md)。项目二的 M0–M6 已完成，实际结果、中文图表、项目报告位于 `results/` 与 `deliverables/` 目录。
