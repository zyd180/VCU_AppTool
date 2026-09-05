function outDir = codegen_onekey(SWCName, rootDir)
% codegen_onekey 一键生成代码：load dd -> config -> check -> slbuild -> 拷贝.c/.h
%   codegen_onekey('TrqArb')
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
addpath(fullfile(rootDir,'01_template'), fullfile(rootDir,'02_dd'));
ddM = fullfile(rootDir, '02_dd', [SWCName '_dd.m']);
if exist(ddM,'file'), run(ddM); end
slx = fullfile(rootDir, '03_model', [SWCName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s，先跑create_swc_template', slx);
[~, model] = fileparts(slx);
if bdIsLoaded(model), close_system(model,0); end
open_system(slx);
ert_autosar_config(model);
dd_check(SWCName, rootDir); % 失败会打印，不硬中断，由slbuild兜底
dd_apply_interface(SWCName, rootDir, model); % 字典Interface/DataElement写进模型，单一数据源
dd_apply_datatype(SWCName, rootDir, model); % 字典BaseType/Enum写进端口类型+生成枚举类
dd_apply_runnable(SWCName, rootDir, model); % 字典Runnable/周期写进模型
dd_apply_calibration(SWCName, rootDir, model); % 字典Calibration写进模型工作区+SharedParameter映射
dd_apply_signal(SWCName, rootDir, model); % 字典Signal_NVM写进模型（DSM/TestPoint+映射）
slbuild(model);
% 收集.c/.h（含arxml一并由slbuild产出，见arxml_gen）
buildDir = fullfile(pwd, [model '_autosar_rtw']);
if ~exist(buildDir,'dir'), buildDir = fullfile(rootDir,'03_model',[model '_autosar_rtw']); end
outDir = fullfile(rootDir, '05_codegen', 'output', SWCName);
if ~exist(outDir,'dir'), mkdir(outDir); end
files = [dir(fullfile(buildDir,'*.c')); dir(fullfile(buildDir,'*.h'))];
assert(~isempty(files), 'slbuild未产出.c/.h，检查Diagnostic Viewer');
for k = 1:numel(files), copyfile(fullfile(files(k).folder,files(k).name), fullfile(outDir,files(k).name)); end
fprintf('代码已拷贝到: %s\n', outDir);
end
