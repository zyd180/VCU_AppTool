function h = harness_gen(SWCName, rootDir)
% harness_gen 生成顶层仿真Harness + Dataset激励（最小闭环）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
hDir = fullfile(rootDir, '06_harness');
if ~exist(hDir,'dir'), mkdir(hDir); end
h = [SWCName '_Harness'];
slx = fullfile(rootDir, '03_model', [SWCName '.slx']);
assert(exist(slx,'file'), '先建SWC模型');
if bdIsLoaded(h), close_system(h, 0); end
if exist(fullfile(hDir,[h '.slx']),'file'), delete(fullfile(hDir,[h '.slx'])); end
new_system(h); open_system(h);
add_block('simulink/Sources/Signal Builder', [h '/Stim'], 'Position', [30 60 120 140]);
add_block('simulink/Ports & Subsystems/Model', [h '/DUT'], 'ModelName', SWCName, 'Position', [200 60 320 140]);
add_block('simulink/Sinks/Scope', [h '/Scope'], 'Position', [400 80 430 110]);
add_line(h, 'Stim/1', 'DUT/1');
try add_line(h, 'Stim/2', 'DUT/2'); catch, end
add_line(h, 'DUT/1', 'Scope/1');
save_system(h, fullfile(hDir, [h '.slx']), 'SaveDirtyReferencedModels', 'on');
fprintf('Harness已生成: %s (BSW桩：DUT外先用Stim/Scope闭环；IoHwAb/Dem/NvM stub按需在Harness外加Gain/Constant占位)\n', h);
end
