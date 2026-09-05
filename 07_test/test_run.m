function test_run(SWCName, rootDir)
% test_run 基线仿真 + 语句/决策覆盖快跑（要求Simulink Coverage）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
slx = fullfile(rootDir, '03_model', [SWCName '.slx']);
[~, model] = fileparts(slx);
open_system(slx);
simOut = sim(model, 'StopTime', '1');
disp(simOut);
try
    cvt = cvsim(model, 'StopTime', '1');
    cvhtml('cov.html', cvt); disp('覆盖率报告: cov.html');
catch ME
    warning('覆盖率跳过: %s', ME.message);
end
fprintf('test_run完成: %s\n', SWCName);
end
