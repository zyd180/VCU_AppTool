function check_all(SWCName, rootDir)
% check_all 字典检查 + Model Advisor AUTOSAR子集（CI入口之一）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
addpath(fullfile(rootDir,'02_dd'));
dd_check(SWCName, rootDir);
slx = fullfile(rootDir,'03_model',[SWCName '.slx']);
[~, model] = fileparts(slx);
open_system(slx);
try
    res = ModelAdvisor.run(model, 'Configuration', 'autosar');
    disp(res);
catch ME
    warning('ModelAdvisor AUTOSAR配置不可用，改跑默认检查: %s', ME.message);
    ModelAdvisor.run(model);
end
fprintf('check_all完成: %s\n', SWCName);
end
