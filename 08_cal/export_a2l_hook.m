function a2lPath = export_a2l_hook(SWCName, rootDir, mapFile)
% export_a2l_hook 完整A2L导出：coder.asap2.export + 内容/地址校验
%   前提：本会话刚跑过codegen_onekey（构建信息有效）；run_all天然满足
%   校验：ARXML出现过的Cal必须进A2L(CHARACTERISTIC)；有SrcBlock的Meas必须进A2L(MEASUREMENT)
%   mapFile可选：目标ELF/PDB/可执行文件，传了则解析真实ECU_ADDRESS；不传则地址占位并告警
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3, mapFile = ''; end
ddM = fullfile(rootDir, '02_dd', [SWCName '_dd.m']);
if exist(ddM,'file'), evalin('base', ['run(''' strrep(ddM, '''', '''''') ''')']); end
vars = evalin('base', 'who(''Cal_*'')');
if ischar(vars), vars = {vars}; elseif isempty(vars), vars = {}; end
fprintf('标定量(%d): %s\n', numel(vars), strjoin(vars, ', '));
% ARXML覆盖率：已映射且被引用的Cal才会进datatype/component arxml
arxmlDir = fullfile(rootDir, '04_arxml', 'output', SWCName);
arTxt = '';
if exist(arxmlDir, 'dir')
    fs = dir(fullfile(arxmlDir, '*.arxml'));
    for k = 1:numel(fs), arTxt = [arTxt fileread(fullfile(fs(k).folder, fs(k).name))]; end
    for k = 1:numel(vars)
        if ~contains(arTxt, vars{k}), warning('标定量 %s 不在ARXML中（未被模块引用或未跑arxml_gen）', vars{k}); end
    end
end
% A2L导出
slx = fullfile(rootDir, '03_model', [SWCName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
[~, model] = fileparts(slx);
if ~bdIsLoaded(model), open_system(slx); end
outDir = fullfile(rootDir, '08_cal', 'output', SWCName);
if ~exist(outDir,'dir'), mkdir(outDir); end
assert(isempty(mapFile) || exist(mapFile,'file'), 'MapFile不存在: %s', mapFile);
try
    if ~isempty(mapFile)
        coder.asap2.export(model, 'Folder', outDir, 'FileName', SWCName, 'MapFile', mapFile);
    else
        coder.asap2.export(model, 'Folder', outDir, 'FileName', SWCName);
    end
catch ME
    error('A2L导出失败（先跑codegen_onekey保证本会话构建）: %s', ME.message(1:min(400,numel(ME.message))));
end
a2lPath = fullfile(outDir, [SWCName '.a2l']);
assert(exist(a2lPath,'file'), 'A2L未生成: %s', a2lPath);
txt = fileread(a2lPath);
% 内容校验：ARXML在场的Cal必须在A2L；有SrcBlock的Meas必须在A2L
for k = 1:numel(vars)
    if contains(arTxt, vars{k}) && ~contains(txt, vars{k})
        warning('标定量 %s 在ARXML但不在A2L中', vars{k});
    end
end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
if exist(xlsx, 'file')
    Tsg = readcell(xlsx, 'Sheet', 'Signal_NVM');
    for r = 2:size(Tsg,1)
        if strcmp(char(string(Tsg{r,2})), 'Meas') && ~isempty(safeText(Tsg, r, 6)) ...
                && ~contains(txt, char(string(Tsg{r,1})))
            warning('测量 %s 不在A2L中', char(string(Tsg{r,1})));
        end
    end
end
fprintf('A2L已生成: %s\n', a2lPath);
% 地址审计：全0=占位（无ELF），实车标定前须带MapFile重导
addrs = regexp(txt, 'ECU_ADDRESS\s+(0x[0-9A-Fa-f]+)', 'tokens');
addrs = [addrs{:}];
if ~isempty(addrs) && all(strcmp(addrs, '0x0000'))
    warning('A2L地址全0占位（无目标ELF）：实车标定前带MapFile重导 export_a2l_hook(''%s'',rootDir,elfPath)', SWCName);
elseif ~isempty(addrs)
    fprintf('A2L地址已解析（%d个，非零）\n', sum(~strcmp(addrs, '0x0000')));
end

    function t = safeText(T, r, c)
        % ponytail: ismissing对char返回向量，不可直接&&，见HANDOFF#10
        if size(T,2) < c, t = ''; return; end
        try sv = string(T{r,c}); catch, t = ''; return; end
        if ~isscalar(sv) || ismissing(sv), t = ''; return; end
        t = char(strtrim(sv));
    end
end
