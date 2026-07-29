function config = project_config()
%PROJECT_CONFIG Central configuration for the 33-bus PV analysis.

config.projectRoot = fileparts(fileparts(mfilename('fullpath')));
config.matpowerRoot = ''; % Set to the local MATPOWER installation if needed.
config.caseName = 'case33bw';

config.loadFactors = [0.8, 1.0, 1.2];
config.penetrationLevels = 0.05:0.05:0.80;
config.baselinePenetration = 0.0;
config.pvBuses = 2:33;
config.voltageMin = 0.95;
config.voltageMax = 1.05;
config.powerFactor = 1.0;

config.resultsRoot = fullfile(config.projectRoot, 'results');
config.figuresRoot = fullfile(config.resultsRoot, 'figures');
config.tablesRoot = fullfile(config.resultsRoot, 'tables');
end

