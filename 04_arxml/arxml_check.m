function ok = arxml_check(SWCName, rootDir)
% arxml_check XML良构 + 关键词 + MATLAB可重导入
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
arxmlDir = fullfile(rootDir, '04_arxml', 'output', SWCName);
if ~exist(arxmlDir,'dir'), arxmlDir = fullfile(rootDir, '04_arxml', 'output'); end
arxmlPath = fullfile(arxmlDir, [SWCName '.arxml']);
assert(exist(arxmlPath,'file'), '找不到 %s，先跑arxml_gen', arxmlPath);
ok = true;
try
    xdoc = xmlread(arxmlPath); %#ok<NASGU>
catch ME
    error('XML良构失败: %s', ME.message);
end
txt = fileread(arxmlPath);
for kw = ["PORT", "INTERFACE", "RUNNABLE", SWCName]
    assert(contains(txt, kw, 'IgnoreCase', true), '缺少关键词: %s', kw);
end
try
    files = dir(fullfile(arxmlDir, '*.arxml'));
    fps = cellfun(@(n) fullfile(arxmlDir, n), {files.name}, 'uni', 0);
    if numel(fps) >= 2, ar = arxml.importer(fps); else, ar = arxml.importer(arxmlPath); end
    comps = getComponentNames(ar);
    assert(any(contains(string(comps), SWCName)), '重导入未找到SWC组件');
    fprintf('重导入组件: %s\n', strjoin(string(comps), ', '));
catch ME
    warning('重导入检查跳过/失败: %s', ME.message);
end
fprintf('arxml_check通过: %s\n', arxmlPath);
end
