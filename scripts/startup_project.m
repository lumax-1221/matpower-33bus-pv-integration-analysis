function config = startup_project()
%STARTUP_PROJECT 配置项目路径并创建结果目录。

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
config = project_config();

if ~isempty(config.matpowerRoot) && isfolder(config.matpowerRoot)
    addpath(genpath(config.matpowerRoot));
end

if ~exist(config.resultsRoot, 'dir'), mkdir(config.resultsRoot); end
if ~exist(config.figuresRoot, 'dir'), mkdir(config.figuresRoot); end
if ~exist(config.tablesRoot, 'dir'), mkdir(config.tablesRoot); end

fprintf('项目根目录：%s\n', config.projectRoot);
fprintf('网络算例：%s\n', config.caseName);
fprintf('请确认 MATLAB 已经加载 MATPOWER 路径。\n');
end
