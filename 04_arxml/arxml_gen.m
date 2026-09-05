function arxmlPath = arxml_gen(SWCName, rootDir)
% arxml_gen 从AUTOSAR模型导出arxml（R2023a: slbuild产物中收集）
%   arxml_gen('TrqArb')
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
slx = fullfile(rootDir, '03_model', [SWCName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
[~, model] = fileparts(slx);
if ~bdIsLoaded(model), open_system(slx); end
slbuild(model); % AUTOSAR模型slbuild即产出arxml（4件套）
buildArxml = dir(fullfile(pwd, [model '_autosar_rtw'], '*.arxml'));
if isempty(buildArxml), buildArxml = dir(fullfile('slprj','**','*.arxml')); end
if isempty(buildArxml), buildArxml = dir(fullfile(pwd,'**','*.arxml')); end
assert(~isempty(buildArxml), '未找到arxml产物，确认模型已autosar.api.create映射');
outDir = fullfile(rootDir, '04_arxml', 'output', SWCName);
if ~exist(outDir,'dir'), mkdir(outDir); end
for k = 1:numel(buildArxml)
    copyfile(fullfile(buildArxml(k).folder, buildArxml(k).name), fullfile(outDir, buildArxml(k).name));
end
% 主文件统一命名为 SWCName.arxml（component件），其余3件保留原名供导入
comp = dir(fullfile(outDir, '*_component.arxml'));
arxmlPath = fullfile(outDir, [SWCName '.arxml']);
if ~isempty(comp), copyfile(fullfile(comp(1).folder, comp(1).name), arxmlPath); end
fprintf('ARXML已生成(%d件): %s\n', numel(buildArxml)+1, outDir);
end
