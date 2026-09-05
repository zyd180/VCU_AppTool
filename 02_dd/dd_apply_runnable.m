function dd_apply_runnable(SWCName, rootDir, modelName)
% dd_apply_runnable 字典Runnable表N行写进模型（幂等，率式多速率）
%   规则：按周期升序，第i行 <-> 入口函数 Periodic:D{i}（D1=最快）；单速率时D1即Periodic
%   每行：runnable重命名/新建 + mapFunction + TimingEvent重命名/新建 + Period对齐
%   用法: dd_apply_runnable('TrqArb')；多速率 placing：慢速路径须经Rate Transition，端口自动切Explicit（见dd_apply_interface）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3 || isempty(modelName), modelName = SWCName; end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典 %s', xlsx);
T = readcell(xlsx, 'Sheet', 'Runnable');
assert(size(T,1) >= 2, 'Runnable表无数据行');
slx = fullfile(rootDir, '03_model', [modelName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
if ~bdIsLoaded(modelName), open_system(slx); end
% 多runnable必须multitasking（否则映射仅单Periodic，见HANDOFF）；单速率不动既有配置
if size(T,1) > 2
    set_param(modelName, 'EnableMultiTasking', 'on');
end
% AUTOSAR多速率硬性要求：RateTransition须Integrity(on)+Deterministic(off)，否则构建失败
try
    rts = find_system(modelName, 'BlockType', 'RateTransition');
    for k = 1:numel(rts)
        try set_param(rts{k}, 'Integrity', 'on', 'Deterministic', 'off'); catch, end
    end
    if ~isempty(rts), fprintf('dd_apply_runnable: %d个RateTransition已按AUTOSAR要求固化\n', numel(rts)); end
catch
end
arProps = autosar.api.getAUTOSARProperties(modelName);
slMap = autosar.api.getSimulinkMapping(modelName);
% 周期升序（D1=最快=基础步长）
pers = zeros(size(T,1)-1, 1);
for i = 2:size(T,1)
    pers(i-1) = str2double(string(T{i,2}));
    assert(~isnan(pers(i-1)) && pers(i-1) > 0, 'Runnable %s Period_ms非法', string(T{i,1}));
end
[~, order] = sort(pers);
fns = string(find(slMap, 'Functions'));
fns(fns == "Initialize") = [];
% IB路径：从现有runnable路径取父级
rns = find(arProps, [], 'Runnable');
parentIB = '';
for k = 1:numel(rns)
    parts = split(string(rns{k}), "/");
    if numel(parts) >= 2, parentIB = char(join(parts(1:end-1), "/")); break; end
end
if isempty(parentIB), parentIB = [modelName '/' modelName '_IB']; end
stepPaths = {};
for k = 1:numel(rns)
    if ~contains(string(rns{k}), 'Init'), stepPaths{end+1} = rns{k}; end
end
for j = 1:numel(order)
    i = order(j) + 1;
    rn = char(string(T{i,1})); period_s = pers(order(j)) / 1000;
    fn = "Periodic:D" + j;
    if numel(fns) == 1 && j == 1
        fn = fns(1); % 单速率：入口函数即Periodic（兼容老模型）
    end
    assert(ismember(fn, fns), '模型入口函数缺 %s（实际 %s）：慢速路径须经Rate Transition形成多速率', fn, strjoin(fns, ','));
    % runnable：首个复用现有Step（重命名），其余新建
    if j <= numel(stepPaths)
        curRn = char(string(get(arProps, stepPaths{j}, 'Name')));
        if ~strcmp(curRn, rn), set(arProps, stepPaths{j}, 'Name', rn); end
    else
        existing = find(arProps, [], 'Runnable');
        hit = '';
        for k = 1:numel(existing)
            if strcmp(char(string(get(arProps, existing{k}, 'Name'))), rn), hit = existing{k}; break; end
        end
        if isempty(hit)
            arProps.add(parentIB, 'Runnables', rn);
        end
    end
    slMap.mapFunction(char(fn), rn);
    % TimingEvent：按StartOnEvent找，找不到则新建
    evs = find(arProps, [], 'TimingEvent');
    evPath = '';
    for k = 1:numel(evs)
        try
            if contains(string(get(arProps, evs{k}, 'StartOnEvent')), string(rn)), evPath = evs{k}; break; end
        catch, end
    end
    if isempty(evPath)
        evName = ['Event_' rn];
        try
            arProps.add(parentIB, 'Events', evName, 'Category', 'TimingEvent');
        catch ME
            error('TimingEvent新建失败: %s', ME.message(1:min(200,numel(ME.message))));
        end
        evPath = [parentIB '/' evName];
    else
        evName = ['Event_' rn];
        curEv = char(string(get(arProps, evPath, 'Name')));
        if ~strcmp(curEv, evName), set(arProps, evPath, 'Name', evName); end
        evPath = [parentIB '/' evName];
    end
    set(arProps, evPath, 'Period', period_s);
    try set(arProps, evPath, 'StartOnEvent', [parentIB '/' rn]); catch, end
    fprintf('dd_apply_runnable: %s -> %s (%s, %.3fs)\n', modelName, rn, fn, period_s);
end
save_system(modelName);
fprintf('dd_apply_runnable完成: %s，共%d个runnable\n', modelName, numel(order));
end
