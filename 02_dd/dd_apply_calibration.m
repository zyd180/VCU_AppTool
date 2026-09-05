function dd_apply_calibration(SWCName, rootDir, modelName)
% dd_apply_calibration 字典Calibration写进模型：模型工作区参数 + 引用 + SharedParameter映射
%   规则：Constant/Gain块按名匹配Cal_*则将其Value/Gain指向工作区参数；未被引用的Cal仅进工作区并警告
%   用法: dd_apply_calibration('TrqArb')，幂等
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3 || isempty(modelName), modelName = SWCName; end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典 %s', xlsx);
T = readcell(xlsx, 'Sheet', 'Calibration');
slx = fullfile(rootDir, '03_model', [modelName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
if ~bdIsLoaded(modelName), open_system(slx); end
ddM = fullfile(rootDir, '02_dd', [SWCName '_dd.m']);
if exist(ddM, 'file'), evalin('base', ['run(''' strrep(ddM, '''', '''''') ''')']); end
hWS = get_param(modelName, 'ModelWorkspace');
nOK = 0;
for r = 2:size(T,1)
    nm = char(string(T{r,1}));
    try baseP = evalin('base', nm); catch, baseP = []; end
    if isempty(baseP)
        warning('标定量 %s 不在Base Workspace（先跑dd_excel2m产物），跳过', nm); continue;
    end
    q = copy(baseP);
    try q.RTWInfo.StorageClass = 'Auto'; catch, end % ponytail: 模型工作区不保留代码生成信息，映射走code mappings
    hWS.assignin(nm, q);
    if ~pointBlockAt(nm)
        warning('标定量 %s 未被任何Constant/Gain模块引用，仅进工作区（代码/ARXML将裁剪）', nm);
    end
end
set_param(modelName, 'SimulationCommand', 'update');
slMap = autosar.api.getSimulinkMapping(modelName);
for r = 2:size(T,1)
    nm = char(string(T{r,1}));
    if ~hWS.hasVariable(nm), continue; end
    try
        slMap.mapParameter(nm, 'SharedParameter');
        nOK = nOK + 1;
    catch ME
        warning('标定量 %s 映射跳过（可能未被模块引用）: %s', nm, ME.message(1:min(160,numel(ME.message))));
    end
end
save_system(modelName);
fprintf('dd_apply_calibration完成: %s，%d个标定量已映射SharedParameter\n', modelName, nOK);

    function hit = pointBlockAt(nm)
        hit = false;
        blk = [modelName '/' nm];
        if exist_block(blk, 'Constant')
            try set_param(blk, 'Value', nm); hit = true; catch, end
        end
        if exist_block(blk, 'Gain')
            try set_param(blk, 'Gain', nm); hit = true; catch, end
        end
    end

    function yes = exist_block(blk, type)
        try
            yes = strcmp(get_param(blk, 'BlockType'), type);
        catch
            yes = false;
        end
    end
end
